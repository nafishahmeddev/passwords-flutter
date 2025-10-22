import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/backup_provider.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backupProvider = Provider.of<BackupProvider>(context);

    final services = backupProvider.availableServices;

    return Scaffold(
      appBar: AppBar(title: Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: services.map((service) {
            return InkWell(
              onTap:
                  backupProvider.status == BackupStatus.backingUp ||
                      backupProvider.status == BackupStatus.restoring
                  ? null
                  : () async {
                      final signed = await backupProvider.isServiceSignedIn(
                        service,
                      );
                      bool ok = signed;
                      if (!signed) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dctx) =>
                              Center(child: CircularProgressIndicator()),
                        );
                        ok = await backupProvider.signInToService(service);
                        try {
                          Navigator.of(context, rootNavigator: true).pop();
                        } catch (_) {}
                      }

                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sign-in failed. Backup cancelled.'),
                          ),
                        );
                        return;
                      }

                      await backupProvider.createBackup(service);
                    },
              child: Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(service.serviceIcon),
                              SizedBox(width: 12),
                              Text(
                                service.serviceName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // progress indicator
                      if (backupProvider.status == BackupStatus.backingUp ||
                          backupProvider.status == BackupStatus.restoring)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              backupProvider.status == BackupStatus.backingUp
                                  ? 'Backup in progress'
                                  : 'Restore in progress',
                            ),
                            SizedBox(height: 8),
                            SizedBox(height: 8),
                          ],
                        ),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.backup_outlined),
                            label: Text('Create Backup'),
                            onPressed:
                                backupProvider.status ==
                                        BackupStatus.backingUp ||
                                    backupProvider.status ==
                                        BackupStatus.restoring
                                ? null
                                : () async {
                                    // Ensure signed in first
                                    final signed = await backupProvider
                                        .isServiceSignedIn(service);
                                    bool ok = signed;
                                    if (!signed) {
                                      // show modal progress while signing in
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (dctx) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                      try {
                                        ok = await backupProvider
                                            .signInToService(service);
                                      } catch (e) {
                                        ok = false;
                                      }
                                      // dismiss dialog
                                      try {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop();
                                      } catch (_) {}
                                    }

                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Sign-in failed. Backup cancelled.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await backupProvider.createBackup(service);
                                  },
                          ),
                          SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: Icon(Icons.restore_outlined),
                            label: Text('Restore'),
                            onPressed:
                                backupProvider.status ==
                                        BackupStatus.backingUp ||
                                    backupProvider.status ==
                                        BackupStatus.restoring
                                ? null
                                : () async {
                                    final signed = await backupProvider
                                        .isServiceSignedIn(service);
                                    bool ok = signed;
                                    if (!signed) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (dctx) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                      try {
                                        ok = await backupProvider
                                            .signInToService(service);
                                      } catch (e) {
                                        ok = false;
                                      }
                                      try {
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop();
                                      } catch (_) {}
                                    }

                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Sign-in failed. Restore cancelled.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await backupProvider.restoreBackup(service);
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
