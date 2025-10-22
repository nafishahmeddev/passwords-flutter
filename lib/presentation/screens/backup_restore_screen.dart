import 'package:flutter/material.dart';
// provider already imported above
import '../../business/providers/backup_provider.dart';
import '../../business/services/google_drive_backup_service.dart';
import '../../business/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final Map<String, bool> _hasRemoteBackup = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChecks());
  }

  Future<void> _initChecks() async {
    if (!mounted) return;
    final backupProvider = Provider.of<BackupProvider>(context, listen: false);
    final services = backupProvider.availableServices;
    debugPrint('[BackupScreen] initChecks: found ${services.length} services');

    for (final service in services) {
      try {
        final signed = await backupProvider.isServiceSignedIn(service);
        if (signed) {
          // fetch availability
          await _fetchBackupsFor(service);
        } else {
          // mark as not having backups by default
          setState(() {
            _hasRemoteBackup[service.serviceName] = false;
          });
        }
      } catch (e) {
        debugPrint(
          '[BackupScreen] initChecks error for ${service.serviceName}: $e',
        );
      }
    }

    // If Google Drive is signed-in at open, auto-start a backup
    dynamic googleService;
    for (final s in services) {
      if (s.serviceName == 'Google Drive') {
        googleService = s;
        break;
      }
    }
    if (googleService != null) {
      final signed = await backupProvider.isServiceSignedIn(googleService);
      if (signed && backupProvider.status == BackupStatus.idle) {
        debugPrint(
          '[BackupScreen] Auto-sync: Google Drive signed in, starting backup',
        );
        await _runWithProgress(
          operation: () => backupProvider.createBackup(googleService),
          title: 'Auto syncing to Google Drive...',
        );
        await _fetchBackupsFor(googleService);
      }
    }

    // finished init checks
    if (!mounted) return;
  }

  Future<void> _fetchBackupsFor(dynamic service) async {
    try {
      final backupProvider = Provider.of<BackupProvider>(
        context,
        listen: false,
      );
      final list = await backupProvider.getAvailableBackups(service);
      if (!mounted) return;
      setState(() {
        _hasRemoteBackup[service.serviceName] = list.isNotEmpty;
      });
    } catch (e) {
      debugPrint(
        '[BackupScreen] fetchBackups error for ${service.serviceName}: $e',
      );
      if (mounted)
        setState(() => _hasRemoteBackup[service.serviceName] = false);
    }
  }

  Future<String?> _fetchAccountEmail(dynamic service) async {
    try {
      if (service is GoogleDriveBackupService) {
        return await service.getAccountEmail();
      }
    } catch (e) {
      debugPrint('[BackupScreen] fetchAccountEmail error: $e');
    }
    return null;
  }

  Future<int?> _fetchLatestBackupSize(dynamic service) async {
    try {
      if (service is GoogleDriveBackupService) {
        return await service.getLatestBackupSize();
      }
    } catch (e) {
      debugPrint('[BackupScreen] fetchLatestBackupSize error: $e');
    }
    return null;
  }

  Future<void> _runWithProgress({
    required Future<void> Function() operation,
    required String title,
  }) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<BackupProvider>(
                  builder: (c, p, _) {
                    final progress = p.progress;
                    final inProgress =
                        p.status == BackupStatus.backingUp ||
                        p.status == BackupStatus.restoring;
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: inProgress ? progress : null,
                        ),
                        SizedBox(height: 12),
                        Text('${(progress * 100).toStringAsFixed(0)}%'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await operation();
    } finally {
      try {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }
  }

  Future<bool> _ensureSignedIn(dynamic service) async {
    final backupProvider = Provider.of<BackupProvider>(context, listen: false);
    final signed = await backupProvider.isServiceSignedIn(service);
    if (signed) return true;

    final ok = await backupProvider.signInToService(service);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed. Operation cancelled.')),
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final backupProvider = Provider.of<BackupProvider>(context);
    final services = backupProvider.availableServices;
    debugPrint(
      '[BackupScreen] build: ${services.length} services -> ${services.map((s) => s.serviceName).join(', ')}',
    );

    // (helpers _runWithProgress and _ensureSignedIn are implemented at class level)

    return Scaffold(
      appBar: AppBar(title: Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: services.map((service) {
            return Card(
              margin: EdgeInsets.only(bottom: 24),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: _fetchAccountEmail(service),
                    builder: (ctx, snap) {
                      final accountEmail = snap.data;
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            service.serviceIcon,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(service.serviceName),
                        subtitle: accountEmail != null
                            ? Text('Signed in as $accountEmail')
                            : Text('Not signed in'),
                      );
                      // end account FutureBuilder
                    },
                  ),

                  // Backup info row (inline) - show small status within card
                  if (backupProvider.status == BackupStatus.backingUp ||
                      backupProvider.status == BackupStatus.restoring)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            backupProvider.status == BackupStatus.backingUp
                                ? 'Backup in progress'
                                : 'Restore in progress',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: backupProvider.progress,
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: FutureBuilder<int?>(
                      future: _fetchLatestBackupSize(service),
                      builder: (ctx, snap) {
                        final size = snap.data;
                        final hasBackup =
                            _hasRemoteBackup[service.serviceName] ?? false;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: Icon(Icons.backup_outlined),
                                    label: Text('Create Backup'),
                                    onPressed:
                                        backupProvider.status ==
                                                BackupStatus.backingUp ||
                                            backupProvider.status ==
                                                BackupStatus.restoring
                                        ? null
                                        : () async {
                                            final ok = await _ensureSignedIn(
                                              service,
                                            );
                                            if (!ok) return;
                                            await backupProvider.createBackup(
                                              service,
                                            );
                                            await _fetchBackupsFor(service);
                                          },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.restore_outlined),
                                    label: Text('Restore'),
                                    onPressed:
                                        (!hasBackup ||
                                            backupProvider.status ==
                                                BackupStatus.backingUp ||
                                            backupProvider.status ==
                                                BackupStatus.restoring)
                                        ? null
                                        : () async {
                                            final ok = await _ensureSignedIn(
                                              service,
                                            );
                                            if (!ok) return;
                                            await _runWithProgress(
                                              operation: () => backupProvider
                                                  .restoreBackup(service),
                                              title: 'Restoring...',
                                            );
                                            await _fetchBackupsFor(service);
                                          },
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remote backup',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      hasBackup
                                          ? (size != null
                                                ? '${(size / 1024).toStringAsFixed(1)} KB'
                                                : 'Available')
                                          : 'No remote backup',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                Consumer<SettingsProvider>(
                                  builder: (c, settings, _) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Text('Auto backup'),
                                            Switch(
                                              value: settings.autoBackupEnabled,
                                              onChanged: (v) async {
                                                await settings
                                                    .setAutoBackupEnabled(v);
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text('Every'),
                                            SizedBox(width: 8),
                                            DropdownButton<int>(
                                              value:
                                                  settings.autoBackupFrequency,
                                              items: [60, 6 * 60, 12 * 60, 24 * 60]
                                                  .map(
                                                    (
                                                      m,
                                                    ) => DropdownMenuItem<int>(
                                                      value: m,
                                                      child: Text(
                                                        m >= 60
                                                            ? (m ~/ 60 == 24
                                                                  ? '24 hours'
                                                                  : '${m ~/ 60} hours')
                                                            : '$m minutes',
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) async {
                                                if (v != null)
                                                  await settings
                                                      .setAutoBackupFrequency(
                                                        v,
                                                      );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
