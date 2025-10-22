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

  final List<BackupService> _availableServices = [
    GoogleDriveBackupService(),
    FileBackupService(),
  ];

  BackupProvider(this._accountRepository);

  BackupStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastBackupTime => _lastBackupTime;

  List<BackupService> get availableServices =>
      _availableServices.where((service) => service.isAvailable).toList();

  Future<void> createBackup(BackupService service) async {
    _status = BackupStatus.backingUp;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get all accounts data
      final accounts = await _accountRepository.getAccounts();
      final accountsData = accounts.map((account) => account.toMap()).toList();

      final result = await service.createBackup(accountsData);

      if (result.success) {
        _lastBackupTime = result.timestamp ?? DateTime.now();
        _status = BackupStatus.idle;
      } else {
        _status = BackupStatus.error;
        _errorMessage = result.errorMessage ?? 'Backup failed';
      }
    } catch (e) {
      _status = BackupStatus.error;
      _errorMessage = 'Backup failed: $e';
    }

    notifyListeners();
  }

  Future<void> restoreBackup(BackupService service) async {
    _status = BackupStatus.restoring;
    _errorMessage = null;
    notifyListeners();

    try {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
