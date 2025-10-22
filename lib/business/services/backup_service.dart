import 'package:flutter/material.dart';

/// Represents the result of a backup operation
class BackupResult {
  final bool success;
  final String? errorMessage;
  final String? backupPath;
  final DateTime? timestamp;

  BackupResult({
    required this.success,
    this.errorMessage,
    this.backupPath,
    this.timestamp,
  });

  factory BackupResult.success({String? backupPath, DateTime? timestamp}) {
    return BackupResult(
      success: true,
      backupPath: backupPath,
      timestamp: timestamp,
    );
  }

  factory BackupResult.failure(String errorMessage) {
    return BackupResult(success: false, errorMessage: errorMessage);
  }
}

/// Represents the result of a restore operation
class RestoreResult {
  final bool success;
  final String? errorMessage;
  final int? accountsRestored;
  final DateTime? timestamp;

  RestoreResult({
    required this.success,
    this.errorMessage,
    this.accountsRestored,
    this.timestamp,
  });

  factory RestoreResult.success(int accountsRestored, {DateTime? timestamp}) {
    return RestoreResult(
      success: true,
      accountsRestored: accountsRestored,
      timestamp: timestamp,
    );
  }

  factory RestoreResult.failure(String errorMessage) {
    return RestoreResult(success: false, errorMessage: errorMessage);
  }
}

/// Abstract backup service interface
abstract class BackupService {
  /// Get the name of the backup service
  String get serviceName;

  /// Get the icon for the backup service
  IconData get serviceIcon;

  /// Check if the service is available on this platform
  bool get isAvailable;

  /// Check if the user is signed in/authenticated
  Future<bool> isSignedIn();

  /// Sign in to the service
  Future<bool> signIn();

  /// Sign out from the service
  Future<void> signOut();

  /// Create a backup of all accounts
  Future<BackupResult> createBackup(List<Map<String, dynamic>> accountsData);

  /// Restore accounts from backup
  Future<RestoreResult> restoreBackup();

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups();

  /// Delete a specific backup
  Future<bool> deleteBackup(String backupId);

  /// Optional progress stream (0.0..1.0) for long-running operations like upload/download
  Stream<double>? get progressStream => null;
}

/// Information about a backup
class BackupInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size; // in bytes
  final String serviceName;

  BackupInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    required this.serviceName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'size': size,
    'serviceName': serviceName,
  };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    size: json['size'],
    serviceName: json['serviceName'],
  );
}
