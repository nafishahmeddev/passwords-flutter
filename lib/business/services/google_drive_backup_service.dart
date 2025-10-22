import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'backup_service.dart';
import '../../data/services/db_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleDriveBackupService implements BackupService {
  static const String _backupFolderName = 'Passwords Backup';
  static const String _backupFilePrefix = 'passwords_backup_';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  drive.DriveApi? _driveApi;
  String? _backupFolderId;
  GoogleSignInAccount? _currentUser;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  // progress controller for backup uploads
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  GoogleDriveBackupService() {
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      debugPrint('[GoogleDrive] Initializing GoogleSignIn');
      await _googleSignIn.initialize(
        serverClientId:
            '838059960115-72q3865apahd75be3u5mnusbq9v81t6t.apps.googleusercontent.com',
      );
      debugPrint('[GoogleDrive] GoogleSignIn.initialize completed');
      _googleSignIn.authenticationEvents.listen(_handleAuthenticationEvent);
      // Attempt to restore saved token and init Drive client silently
      try {
        await _tryRestoreSavedToken();
      } catch (e) {
        debugPrint('[GoogleDrive] No saved credentials restored: $e');
      }
    } catch (e) {
      debugPrint('[GoogleDrive] Failed to initialize Google Sign-In: $e');
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      _currentUser = event.user;
      debugPrint(
        '[GoogleDrive] Google Sign-In completed for user: ${_currentUser!.displayName}',
      );
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      _currentUser = null;
      _driveApi = null;
      _backupFolderId = null;
      debugPrint('[GoogleDrive] Google Sign-Out completed');
    }
  }

  @override
  String get serviceName => 'Google Drive';

  @override
  IconData get serviceIcon => Icons.cloud;

  @override
  bool get isAvailable => Platform.isAndroid;

  @override
  Stream<double>? get progressStream => _progressController.stream;

  @override
  Future<bool> isSignedIn() async {
    return _currentUser != null || _driveApi != null;
  }

  @override
  Future<bool> signIn() async {
    try {
      // Try the newer authenticate flow if supported (biometric/instant)
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate(scopeHint: _scopes);
        // Allow the auth event listener to set _currentUser
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      if (_currentUser == null) {
        debugPrint('Google Sign-In did not complete or was cancelled');
        return false;
      }

      // Attempt to get client authorization for the requested scopes
      late GoogleSignInClientAuthorization? authorization;

      // check if auth exists
      authorization = await _googleSignIn.authorizationClient
          .authorizationForScopes(_scopes);
      await _currentUser!.authorizationClient
          .authorizeScopes(_scopes)
          .then((value) {
            authorization = value;
          })
          .catchError((e) {
            debugPrint('Error during authorizeScopes: $e');
            return null;
          });

      debugPrint('Authorization obtained: $authorization');
      if (authorization != null) {
        final token = authorization!.accessToken;
        // Persist token to secure storage for auto-backup flows.
        try {
          await _secureStorage.write(
            key: 'google_drive_access_token',
            value: token,
          );
          // store the signed-in account email for informational purposes
          if (_currentUser?.email != null) {
            await _secureStorage.write(
              key: 'google_drive_account_email',
              value: _currentUser!.email,
            );
          }
          await _secureStorage.write(
            key: 'google_drive_token_saved_at',
            value: DateTime.now().toIso8601String(),
          );
        } catch (e) {
          debugPrint('[GoogleDrive] Failed to persist auth token: $e');
        }

        await _setupDriveApi(authorization);
        return true;
      }

      // If we reach here, the user account exists but Drive authorization
      // could not be obtained. This usually means the user didn't grant the
      // Drive scopes or the authorization flow did not return them.
      debugPrint(
        'authorizationForScopes returned null (no Drive authorization)',
      );
      if (_currentUser != null) {
        debugPrint(
          'Signed in user: ${_currentUser!.email} (${_currentUser!.displayName})',
        );
      }
      debugPrint('Requested scopes: $_scopes');
      // Sign out to clear any partial auth state so the user can retry cleanly
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Failed to sign out after missing Drive authorization: $e');
      }
      return false;
    } on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In failed with code ${e.code}: ${e.description}');
      return false;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  /// Dispose resources used by this service.
  void dispose() {
    try {
      _progressController.close();
    } catch (e) {
      debugPrint('[GoogleDrive] Failed to close progress controller: $e');
    }
  }

  Future<void> _setupDriveApi([
    GoogleSignInClientAuthorization? authorization,
  ]) async {
    if (_currentUser == null) return;

    try {
      // If no authorization provided, try to get it
      authorization ??= await _googleSignIn.authorizationClient
          .authorizationForScopes(_scopes);

      if (authorization != null) {
        final authenticateClient = auth.authenticatedClient(
          http.Client(),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              authorization.accessToken,
              DateTime.now()
                  .add(Duration(hours: 1))
                  .toUtc(), // Access tokens typically last 1 hour
            ),
            null, // No refresh token provided by client authorization
            _scopes,
          ),
        );
        _driveApi = drive.DriveApi(authenticateClient);
        await _ensureBackupFolder();
      }
    } catch (e) {
      debugPrint('[GoogleDrive] Failed to setup Drive API: $e');
      rethrow;
    }
  }

  Future<void> _ensureBackupFolder() async {
    if (_driveApi == null) return;

    try {
      debugPrint('[GoogleDrive] Ensuring backup folder exists');
      // Check if backup folder already exists
      final folderQuery =
          "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folderList = await _driveApi!.files.list(q: folderQuery);

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        _backupFolderId = folderList.files!.first.id;
        debugPrint(
          '[GoogleDrive] Found existing backup folder: $_backupFolderId',
        );
      } else {
        // Create backup folder
        debugPrint('[GoogleDrive] Creating backup folder');
        final folderMetadata = drive.File()
          ..name = _backupFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final folder = await _driveApi!.files.create(folderMetadata);
        _backupFolderId = folder.id;
        debugPrint('[GoogleDrive] Created backup folder: $_backupFolderId');
      }
    } catch (e) {
      debugPrint('[GoogleDrive] Failed to create or find backup folder: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    debugPrint('[GoogleDrive] signOut() called');
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      _backupFolderId = null;
      _currentUser = null;
      try {
        await _secureStorage.delete(key: 'google_drive_access_token');
        await _secureStorage.delete(key: 'google_drive_account_email');
        await _secureStorage.delete(key: 'google_drive_token_saved_at');
      } catch (e) {
        debugPrint('[GoogleDrive] Failed to clear saved credentials: $e');
      }
      debugPrint('[GoogleDrive] signOut() completed');
    } catch (e) {
      debugPrint('[GoogleDrive] signOut() failed: $e');
    }
  }

  @override
  Future<BackupResult> createBackup(
    List<Map<String, dynamic>> accountsData,
  ) async {
    if (_driveApi == null || _backupFolderId == null) {
      return BackupResult.failure('Not signed in to Google Drive');
    }

    bool _dbClosedByBackup = false;
    try {
      // Ensure DB is closed before reading the sqlite file
      await DBHelper.close();
      _dbClosedByBackup = true;
      final timestamp = DateTime.now();
      // Assume DB filename as in DBHelper
      final dbPath = join(await getDatabasesPath(), 'passwords.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        return BackupResult.failure('Local database file not found');
      }

      final fileName =
          '$_backupFilePrefix${timestamp.millisecondsSinceEpoch}.db';

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_backupFolderId!];

      final total = dbFile.lengthSync();
      int uploaded = 0;

      final controller = StreamController<List<int>>();
      final sub = dbFile.openRead().listen(
        (chunk) {
          uploaded += chunk.length;
          try {
            final progress = (uploaded / total).clamp(0.0, 1.0);
            // send progress via stream if available
            // ignore if controller closed
            debugPrint('[GoogleDrive] emitting progress $progress');
            _progressController.add(progress);
          } catch (_) {}
          controller.add(chunk);
        },
        onDone: () {
          controller.close();
        },
        onError: (e) {
          controller.addError(e);
        },
        cancelOnError: true,
      );

      final media = drive.Media(controller.stream, total);

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      // emit completion
      try {
        debugPrint('[GoogleDrive] emitting progress 1.0 (complete)');
        _progressController.add(1.0);
      } catch (_) {}

      await sub.cancel();

      // After successful upload, remove any other backups in the folder so
      // only the most recent backup is kept. This protects against orphaned
      // older backups consuming space.
      try {
        final query =
            "'$_backupFolderId' in parents and name contains '$_backupFilePrefix' and trashed = false";
        final fileList = await _driveApi!.files.list(q: query);
        if (fileList.files != null) {
          for (final f in fileList.files!) {
            if (f.id != uploadedFile.id &&
                f.name != null &&
                f.name!.startsWith(_backupFilePrefix)) {
              try {
                await _driveApi!.files.delete(f.id!);
              } catch (e) {
                debugPrint(
                  '[GoogleDrive] Failed to delete old backup ${f.id}: $e',
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[GoogleDrive] Error cleaning up old backups: $e');
      }

      return BackupResult.success(
        backupPath: uploadedFile.id,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Backup creation failed: $e');
      return BackupResult.failure('Failed to create backup: $e');
    } finally {
      if (_dbClosedByBackup) {
        try {
          // Re-open the database so the rest of the app can continue using it.
          await DBHelper.init();
          debugPrint('[GoogleDrive] Re-opened local DB after backup');
        } catch (e) {
          debugPrint('[GoogleDrive] Failed to re-open DB after backup: $e');
        }
      }
    }
  }

  @override
  Future<RestoreResult> restoreBackup() async {
    if (_driveApi == null) {
      return RestoreResult.failure('Not signed in to Google Drive');
    }

    try {
      final backups = await getAvailableBackups();
      if (backups.isEmpty) {
        return RestoreResult.failure('No backups found');
      }

      // Get the most recent backup
      final latestBackup = backups.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );

      final media =
          await _driveApi!.files.get(
                latestBackup.id,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/restore_temp.db');
      final sink = tempFile.openWrite();

      int received = 0;
      final total = (latestBackup.size > 0) ? latestBackup.size : null;

      final controller = StreamController<List<int>>();
      final streamSub = media.stream.listen(
        (chunk) {
          received += chunk.length;
          try {
            if (total != null) {
              _progressController.add((received / total).clamp(0.0, 1.0));
            }
          } catch (_) {}
          controller.add(chunk);
        },
        onDone: () {
          controller.close();
        },
        onError: (e) {
          controller.addError(e);
        },
      );

      await controller.stream.pipe(sink);
      await sink.close();
      await streamSub.cancel();

      // Basic verification: check file size > 0 and check SQLite header
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        try {
          await tempFile.delete();
        } catch (_) {}
        return RestoreResult.failure('Downloaded backup is invalid (empty)');
      }

      try {
        final bytes = await tempFile.readAsBytes();
        if (bytes.length < 16) {
          try {
            await tempFile.delete();
          } catch (_) {}
          return RestoreResult.failure(
            'Downloaded backup is invalid (too small)',
          );
        }

        final header = ascii.decode(bytes.sublist(0, 16));
        if (header != 'SQLite format 3\u0000') {
          try {
            await tempFile.delete();
          } catch (_) {}
          return RestoreResult.failure(
            'Downloaded backup is not a valid SQLite DB',
          );
        }
      } catch (e) {
        try {
          await tempFile.delete();
        } catch (_) {}
        return RestoreResult.failure(
          'Downloaded backup verification failed: $e',
        );
      }

      // Close DB before replacing
      await DBHelper.close();

      final dbPath = join(await getDatabasesPath(), 'passwords.db');
      final dbFile = File(dbPath);

      // backup current DB
      final backupOld = File('${dbPath}.bak');
      if (await dbFile.exists()) {
        try {
          await dbFile.rename(backupOld.path);
        } catch (e) {
          debugPrint('[GoogleDrive] Failed to move old DB to .bak: $e');
        }
      }

      // Move new DB into place
      try {
        await tempFile.rename(dbPath);
      } catch (e) {
        debugPrint('[GoogleDrive] Failed to move restored DB into place: $e');
        // Try to restore previous DB from bak
        try {
          if (await backupOld.exists()) {
            await backupOld.rename(dbPath);
          }
        } catch (e2) {
          debugPrint(
            '[GoogleDrive] Failed to restore .bak after failed rename: $e2',
          );
        }
        return RestoreResult.failure('Failed to place restored DB: $e');
      }

      // Re-open DB so app can continue; if this fails we leave .bak in place
      try {
        await DBHelper.init();
        debugPrint('[GoogleDrive] Re-opened local DB after restore');
      } catch (e) {
        debugPrint('[GoogleDrive] Failed to re-open DB after restore: $e');
        return RestoreResult.failure('Restored DB could not be opened: $e');
      }

      // Restart app by calling platform channel to exit (best-effort)
      try {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (e) {
        // If platform pop fails, just return success and let user restart
        debugPrint('Failed to programmatically exit app: $e');
      }

      return RestoreResult.success(0, timestamp: latestBackup.createdAt);
    } catch (e) {
      debugPrint('Restore failed: $e');
      return RestoreResult.failure('Failed to restore backup: $e');
    }
  }

  @override
  Future<List<BackupInfo>> getAvailableBackups() async {
    if (_driveApi == null || _backupFolderId == null) {
      return [];
    }

    try {
      final query =
          "'$_backupFolderId' in parents and name contains '$_backupFilePrefix' and trashed = false";
      final fileList = await _driveApi!.files.list(
        q: query,
        orderBy: 'createdTime desc',
      );

      return fileList.files
              ?.map(
                (file) => BackupInfo(
                  id: file.id!,
                  name: file.name!,
                  createdAt: file.createdTime ?? DateTime.now(),
                  size: int.parse(file.size ?? '0'),
                  serviceName: serviceName,
                ),
              )
              .toList() ??
          [];
    } catch (e) {
      debugPrint('Failed to get backups: $e');
      return [];
    }
  }

  /// Returns the signed-in account email if available.
  Future<String?> getAccountEmail() async {
    if (_currentUser?.email != null) return _currentUser!.email;
    try {
      final stored = await _secureStorage.read(
        key: 'google_drive_account_email',
      );
      return stored;
    } catch (e) {
      debugPrint('[GoogleDrive] getAccountEmail failed to read storage: $e');
      return null;
    }
  }

  /// Returns the size (in bytes) of the latest backup, or null if none.
  Future<int?> getLatestBackupSize() async {
    try {
      final list = await getAvailableBackups();
      if (list.isEmpty) return null;
      // getAvailableBackups orders by createdTime desc, so first is latest
      return list.first.size;
    } catch (e) {
      debugPrint('[GoogleDrive] getLatestBackupSize failed: $e');
      return null;
    }
  }

  Future<void> _tryRestoreSavedToken() async {
    try {
      final token = await _secureStorage.read(key: 'google_drive_access_token');
      final savedAtStr = await _secureStorage.read(
        key: 'google_drive_token_saved_at',
      );
      if (token == null) return;

      DateTime savedAt;
      try {
        savedAt = savedAtStr != null
            ? DateTime.parse(savedAtStr)
            : DateTime.now();
      } catch (_) {
        savedAt = DateTime.now();
      }

      // Construct access credentials assuming 1 hour lifetime from savedAt.
      final expiry = savedAt.toUtc().add(Duration(hours: 1));
      final credentials = auth.AccessCredentials(
        auth.AccessToken('Bearer', token, expiry),
        null,
        _scopes,
      );

      final client = auth.authenticatedClient(http.Client(), credentials);
      _driveApi = drive.DriveApi(client);

      try {
        await _ensureBackupFolder();
        debugPrint('[GoogleDrive] Restored Drive client from saved token');
      } catch (e) {
        debugPrint(
          '[GoogleDrive] Restored Drive client but failed to ensure folder: $e',
        );
      }
    } catch (e) {
      debugPrint('[GoogleDrive] _tryRestoreSavedToken failed: $e');
    }
  }

  @override
  Future<bool> deleteBackup(String backupId) async {
    if (_driveApi == null) return false;

    try {
      await _driveApi!.files.delete(backupId);
      return true;
    } catch (e) {
      debugPrint('Failed to delete backup: $e');
      return false;
    }
  }
}
