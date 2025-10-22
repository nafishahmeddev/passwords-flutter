import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/account_repository.dart';
import '../services/backup_service.dart';
import '../services/google_drive_backup_service.dart';
import '../services/file_backup_service.dart';

enum BackupStatus { idle, backingUp, restoring, error }

class BackupProvider extends ChangeNotifier {
  final AccountRepository _accountRepository;

  BackupStatus _status = BackupStatus.idle;
  String? _errorMessage;
  DateTime? _lastBackupTime;
  double _progress = 0.0;
  StreamSubscription<double>? _progressSubscription;

  final List<BackupService> _availableServices = [
    GoogleDriveBackupService(),
    FileBackupService(),
  ];

  BackupProvider(this._accountRepository);

  BackupStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastBackupTime => _lastBackupTime;
  double get progress => _progress;

  List<BackupService> get availableServices =>
      _availableServices.where((service) => service.isAvailable).toList();

  Future<void> createBackup(BackupService service) async {
    debugPrint('[BackupProvider] createBackup called for ${service.serviceName}');
    _status = BackupStatus.backingUp;
    _errorMessage = null;
    _progress = 0.0;
    notifyListeners();

    try {
      // Get all accounts data
      final accounts = await _accountRepository.getAccounts();
      final accountsData = accounts.map((account) => account.toMap()).toList();

      // Subscribe to progress if supported
      try {
        await _progressSubscription?.cancel();
        final progressStream = service.progressStream;
        if (progressStream != null) {
          debugPrint('[BackupProvider] subscribing to progress stream for ${service.serviceName}');
          _progressSubscription = progressStream.listen((p) {
            _progress = p.clamp(0.0, 1.0);
            debugPrint('[BackupProvider] progress=$p for ${service.serviceName}');
            notifyListeners();
          }, onError: (e) {
            debugPrint('[BackupProvider] progress stream error: $e');
          });
        }
      } catch (_) {}

      final result = await service.createBackup(accountsData);

      if (result.success) {
        _lastBackupTime = result.timestamp ?? DateTime.now();
        _progress = 1.0;
        _status = BackupStatus.idle;
      } else {
        _status = BackupStatus.error;
        _errorMessage = result.errorMessage ?? 'Backup failed';
      }
    } catch (e) {
      _status = BackupStatus.error;
      _errorMessage = 'Backup failed: $e';
    }

    debugPrint('[BackupProvider] createBackup finished: status=$_status error=$_errorMessage');

    // cleanup progress listener
    try {
      await _progressSubscription?.cancel();
      _progressSubscription = null;
    } catch (_) {}

    notifyListeners();
  }

  Future<void> restoreBackup(BackupService service) async {
    debugPrint('[BackupProvider] restoreBackup called for ${service.serviceName}');
    _status = BackupStatus.restoring;
    _errorMessage = null;
    _progress = 0.0;
    notifyListeners();

    try {
      // Subscribe to progress if supported
      try {
        await _progressSubscription?.cancel();
        final progressStream = service.progressStream;
        if (progressStream != null) {
          _progressSubscription = progressStream.listen((p) {
            _progress = p.clamp(0.0, 1.0);
            notifyListeners();
          });
        }
      } catch (_) {}

      final result = await service.restoreBackup();

      if (result.success) {
        // Note: Actual account restoration would need to be implemented
        // This is just a placeholder for the UI feedback
        _status = BackupStatus.idle;
      } else {
        _status = BackupStatus.error;
        _errorMessage = result.errorMessage ?? 'Restore failed';
      }
    } catch (e) {
      _status = BackupStatus.error;
      _errorMessage = 'Restore failed: $e';
    }

    debugPrint('[BackupProvider] restoreBackup finished: status=$_status error=$_errorMessage');

    notifyListeners();
  }

  Future<List<BackupInfo>> getAvailableBackups(BackupService service) async {
    try {
      return await service.getAvailableBackups();
    } catch (e) {
      _errorMessage = 'Failed to get backups: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> deleteBackup(BackupService service, String backupId) async {
    try {
      return await service.deleteBackup(backupId);
    } catch (e) {
      _errorMessage = 'Failed to delete backup: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> isServiceSignedIn(BackupService service) async {
    try {
      return await service.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInToService(BackupService service) async {
    try {
      return await service.signIn();
    } catch (e) {
      _errorMessage = 'Failed to sign in: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    try {
      _progressSubscription?.cancel();
    } catch (_) {}

    for (final service in _availableServices) {
      try {
        if (service is GoogleDriveBackupService) {
          service.dispose();
        }
      } catch (_) {}
    }

    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
