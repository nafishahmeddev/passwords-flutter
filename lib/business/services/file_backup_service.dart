import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'backup_service.dart';

class FileBackupService implements BackupService {
  static const String _backupFilePrefix = 'passwords_backup_';

  @override
  String get serviceName => 'File Export';

  @override
  IconData get serviceIcon => Icons.file_download;

  @override
  bool get isAvailable => true; // Available on all platforms

  @override
  Stream<double>? get progressStream => null;

  @override
  Future<bool> isSignedIn() async {
    // File backup doesn't require sign-in
    return true;
  }

  @override
  Future<bool> signIn() async {
    // No sign-in required
    return true;
  }

  @override
  Future<void> signOut() async {
    // Nothing to sign out
  }

  @override
  Future<BackupResult> createBackup(
    List<Map<String, dynamic>> accountsData,
  ) async {
    try {
      final timestamp = DateTime.now();
      final backupData = {
        'version': '1.0',
        'timestamp': timestamp.toIso8601String(),
        'accounts': accountsData,
      };

      final jsonData = jsonEncode(backupData);
      final fileName =
          '${_backupFilePrefix}${timestamp.millisecondsSinceEpoch}.json';

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/$fileName');
      await backupFile.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Passwords Backup',
        text: 'Backup created on ${timestamp.toString()}',
      );

      return BackupResult.success(
        backupPath: backupFile.path,
        timestamp: timestamp,
      );
    } catch (e) {
      print('File backup creation failed: $e');
      return BackupResult.failure('Failed to create file backup: $e');
    }
  }

  @override
  Future<RestoreResult> restoreBackup() async {
    // File restore requires user to select a file
    // This would need to be implemented with file picker
    return RestoreResult.failure(
      'File restore not implemented yet. Please use import feature.',
    );
  }

  @override
  Future<List<BackupInfo>> getAvailableBackups() async {
    // File backups are managed by the user externally
    return [];
  }

  @override
  Future<bool> deleteBackup(String backupId) async {
    // User manages file deletion externally
    return false;
  }
}
