import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/backup_provider.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backupProvider = Provider.of<BackupProvider>(context);
    final services = backupProvider.availableServices;
    debugPrint('[BackupScreen] build: ${services.length} services -> ${services.map((s) => s.serviceName).join(', ')}');

    // Helper to show a modal progress dialog while running the async op
    Future<void> _runWithProgress({
      required Future<void> Function() operation,
      required String title,
    }) async {
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
                  Consumer<BackupProvider>(builder: (c, p, _) {
                    final progress = p.progress;
                    final inProgress = p.status == BackupStatus.backingUp || p.status == BackupStatus.restoring;
                    return Column(
                      children: [
                        LinearProgressIndicator(value: inProgress ? progress : null),
                        SizedBox(height: 12),
                        Text('${(progress * 100).toStringAsFixed(0)}%'),
                      ],
                    );
                  }),
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
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
    }

    // Ensure the service is signed in. Shows a SnackBar on failure.
    Future<bool> ensureSignedIn(BuildContext context, dynamic service) async {
      final signed = await backupProvider.isServiceSignedIn(service);
      if (signed) return true;

      // Try to sign in. Do not show a blocking custom dialog here; the Google SignIn UI will appear.
      final ok = await backupProvider.signInToService(service);
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed. Operation cancelled.')),
          );
        }
      }
      return ok;
    }

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
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(service.serviceIcon, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    title: Text(service.serviceName),
                    subtitle: Text(
                      'Manage backups for ${service.serviceName}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Progress row (inline) - only show small status within card
                  if (backupProvider.status == BackupStatus.backingUp || backupProvider.status == BackupStatus.restoring)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            backupProvider.status == BackupStatus.backingUp ? 'Backup in progress' : 'Restore in progress',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(value: backupProvider.progress),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: Icon(Icons.backup_outlined),
                            label: Text('Create Backup'),
                            onPressed: backupProvider.status == BackupStatus.backingUp || backupProvider.status == BackupStatus.restoring
                                ? null
                                : () async {
                                    try {
                                      debugPrint('[BackupScreen] Create Backup pressed for ${service.serviceName}');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Starting backup...')),
                                        );
                                      }

                                      final ok = await ensureSignedIn(context, service);
                                      if (!ok) return;

                                      await _runWithProgress(
                                        operation: () => backupProvider.createBackup(service),
                                        title: 'Backing up...',
                                      );

                                      // After operation, show result feedback
                                      if (backupProvider.status == BackupStatus.error) {
                                        final msg = backupProvider.errorMessage ?? 'Backup failed';
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg)),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Backup completed')),
                                          );
                                        }
                                      }
                                    } catch (e, st) {
                                      debugPrint('[BackupScreen] Create Backup error: $e\n$st');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Unexpected error: $e')),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.restore_outlined),
                            label: Text('Restore'),
                            onPressed: backupProvider.status == BackupStatus.backingUp || backupProvider.status == BackupStatus.restoring
                                ? null
                                : () async {
                                    try {
                                      debugPrint('[BackupScreen] Restore pressed for ${service.serviceName}');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Starting restore...')),
                                        );
                                      }

                                      final ok = await ensureSignedIn(context, service);
                                      if (!ok) return;

                                      await _runWithProgress(
                                        operation: () => backupProvider.restoreBackup(service),
                                        title: 'Restoring...',
                                      );

                                      if (backupProvider.status == BackupStatus.error) {
                                        final msg = backupProvider.errorMessage ?? 'Restore failed';
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg)),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Restore completed')),
                                          );
                                        }
                                      }
                                    } catch (e, st) {
                                      debugPrint('[BackupScreen] Restore error: $e\n$st');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Unexpected error: $e')),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
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
