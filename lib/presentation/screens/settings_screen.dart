import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/settings_provider.dart';
import '../../business/providers/backup_provider.dart';
import '../../business/services/favicon_service.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // UI state for PIN setup
  bool _isPinSetup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isPinSet = await settingsProvider.isPinSet();

    if (mounted) {
      setState(() {
        _isPinSetup = isPinSet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: _buildSettingsScreen(),
    );
  }

  Widget _buildSettingsScreen() {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // General settings section
        _buildSectionHeader(
          context,
          'General Settings',
          Icons.settings_outlined,
        ),
        Card(
          margin: EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Theme mode setting
              ListTile(
                title: Text('Theme Mode'),
                subtitle: Text(
                  settingsProvider.themeMode.displayName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                onTap: () => _showThemeModeDialog(context),
              ),

              // Dynamic color setting
              if (Platform.isAndroid) ...[
                const Divider(height: 0),
                SwitchListTile(
                  title: Text('Dynamic Colors'),
                  subtitle: Text(
                    'Use system color palette',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  secondary: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.color_lens_outlined,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  value: settingsProvider.useDynamicColor,
                  onChanged: (value) async {
                    await settingsProvider.setUseDynamicColor(value);
                  },
                ),
              ],
            ],
          ),
        ),

        // Security settings section
        _buildSectionHeader(
          context,
          'Security Settings',
          Icons.security_outlined,
        ),
        Card(
          margin: EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // App lock setting
              SwitchListTile(
                title: Text('App Lock'),
                subtitle: Text(
                  'Require authentication to access your passwords',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                value: settingsProvider.isAuthEnabled,
                onChanged: (value) async {
                  if (value && !_isPinSetup) {
                    // Can't enable without setting up a PIN first
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please set up a PIN first'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }

                  await settingsProvider.setAuthEnabled(value);
                  if (!value) {
                    await settingsProvider.setBiometricEnabled(false);
                  }
                },
              ),

              const Divider(height: 0),

              // PIN setup option
              ListTile(
                title: Text(_isPinSetup ? 'Change PIN' : 'Set up PIN'),
                subtitle: Text(
                  _isPinSetup
                      ? 'Change your current PIN'
                      : 'Create a PIN to secure your app',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pin_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PinSetupScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    // Refresh PIN status
                    _loadSettings();
                  }
                },
              ),

              // Biometric option
              if (settingsProvider.isBiometricAvailable)
                const Divider(height: 0),

              if (settingsProvider.isBiometricAvailable)
                SwitchListTile(
                  title: Text('Biometric Authentication'),
                  subtitle: Text(
                    'Use your fingerprint or face to unlock',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  secondary: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  value: settingsProvider.isBiometricEnabled,
                  onChanged: (value) async {
                    if (!_isPinSetup) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please set up a PIN first'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                        ),
                      );
                      return;
                    }

                    await settingsProvider.setBiometricEnabled(value);
                  },
                ),

              // Auto lock settings
              const Divider(height: 0),

              SwitchListTile(
                title: Text('Auto Lock'),
                subtitle: Text(
                  'Automatically lock the app after inactivity',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                value: settingsProvider.autoLockEnabled,
                onChanged: (value) async {
                  if (!settingsProvider.isAuthEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enable App Lock first'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  await settingsProvider.setAutoLockEnabled(value);
                },
              ),

              // Show auto lock duration only if auto lock is enabled
              if (settingsProvider.autoLockEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListTile(
                    title: Text('Auto Lock After'),
                    subtitle: Text(
                      '${settingsProvider.autoLockDuration} minute${settingsProvider.autoLockDuration > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _showAutoLockDurationDialog(context),
                  ),
                ),
            ],
          ),
        ),

        // Storage section
        _buildSectionHeader(context, 'Storage', Icons.storage_outlined),
        Card(
          margin: EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Cache info tile
              ListTile(
                title: Text('Favicon Cache'),
                subtitle: FutureBuilder<int>(
                  future: FaviconService.getCacheSize(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final sizeInMB = (snapshot.data! / (1024 * 1024))
                          .toStringAsFixed(2);
                      return Text('Cache size: $sizeInMB MB');
                    }
                    return Text('Calculating cache size...');
                  },
                ),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.refresh_outlined),
                  onPressed: () {
                    setState(() {}); // Refresh the cache size display
                  },
                ),
              ),

              const Divider(height: 0),

              // Clear expired cache
              ListTile(
                title: Text('Clear Expired Cache'),
                subtitle: Text('Remove favicon cache older than 7 days'),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_delete_outlined,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                onTap: () => _clearExpiredCache(context),
              ),

              const Divider(height: 0),

              // Clear all cache
              ListTile(
                title: Text(
                  'Clear All Cache',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                subtitle: Text('Remove all cached favicons'),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.clear_all_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onTap: () => _clearAllCache(context),
              ),
            ],
          ),
        ),

        // Reset section
        if (_isPinSetup)
          Card(
            margin: EdgeInsets.only(bottom: 24),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                'Reset Security Settings',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: Text(
                'Remove PIN and biometric authentication',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onTap: _showResetConfirmation,
            ),
          ),

        // Backup section
        _buildSectionHeader(context, 'Backup & Sync', Icons.backup_outlined),
        Card(
          margin: EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Consumer<BackupProvider>(
                builder: (context, backupProvider, child) {
                  final availableServices = backupProvider.availableServices;

                  return Column(
                    children: availableServices.map((service) {
                      return Column(
                        children: [
                          if (availableServices.indexOf(service) > 0)
                            const Divider(height: 0),
                          FutureBuilder<bool>(
                            future: backupProvider.isServiceSignedIn(service),
                            builder: (context, snapshot) {
                              final isSignedIn = snapshot.data ?? false;

                              return ListTile(
                                title: Text(service.serviceName),
                                subtitle: Text(
                                  isSignedIn ? 'Signed in' : 'Tap to sign in',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
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
                                trailing:
                                    backupProvider.status ==
                                        BackupStatus.backingUp
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.backup_outlined),
                                        onPressed: isSignedIn
                                            ? () => _createBackup(
                                                context,
                                                backupProvider,
                                                service,
                                              )
                                            : () => _signInToService(
                                                context,
                                                backupProvider,
                                                service,
                                              ),
                                      ),
                                onTap: () => _showBackupOptions(
                                  context,
                                  backupProvider,
                                  service,
                                  isSignedIn,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),

        // About section
        _buildSectionHeader(context, 'About', Icons.info_outlined),
        Card(
          margin: EdgeInsets.only(bottom: 24),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text('Version'),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info text about security
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
          child: Text(
            'App lock ensures that your passwords remain secure even if someone gains access to your device. We recommend using both PIN and biometric authentication for the best security.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _clearExpiredCache(BuildContext context) async {
    try {
      await FaviconService.clearExpiredCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expired favicon cache cleared'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        setState(() {}); // Refresh the cache size display
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear expired cache: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _clearAllCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Cache?'),
        content: Text(
          'This will remove all cached favicons. They will need to be downloaded again when viewing accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FaviconService.clearCache();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All favicon cache cleared'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                  setState(() {}); // Refresh the cache size display
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear cache: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Security?'),
        content: Text(
          'This will remove your PIN and disable biometric authentication. You will need to set them up again to secure your app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await settingsProvider.resetAuth();

              setState(() {
                _isPinSetup = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Security settings reset'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Theme Mode'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: settingsProvider.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await settingsProvider.setThemeMode(value);
                Navigator.pop(context);
              }
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<ThemeMode>(value: ThemeMode.system),
                    SizedBox(width: 8),
                    Text('System'),
                  ],
                ),
                Row(
                  children: [
                    Radio<ThemeMode>(value: ThemeMode.light),
                    SizedBox(width: 8),
                    Text('Light'),
                  ],
                ),
                Row(
                  children: [
                    Radio<ThemeMode>(value: ThemeMode.dark),
                    SizedBox(width: 8),
                    Text('Dark'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoLockDurationDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    void onChanged(int? value) async {
      if (value != null) {
        Navigator.pop(context);
        await settingsProvider.setAutoLockDuration(value);
      }
    }

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Auto Lock Duration'),
        children: [
          RadioGroup<int>(
            groupValue: settingsProvider.autoLockDuration,
            onChanged: onChanged,
            child: Column(
              children: [
                for (final duration in [1, 5, 10, 30, 60])
                  Row(
                    children: [
                      Radio<int>(value: duration),
                      SizedBox(width: 8),
                      Text('$duration minute${duration > 1 ? 's' : ''}'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(
    BuildContext context,
    BackupProvider backupProvider,
    dynamic service,
  ) async {
    try {
      await backupProvider.createBackup(service);
      if (backupProvider.errorMessage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup created successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${backupProvider.errorMessage}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _signInToService(
    BuildContext context,
    BackupProvider backupProvider,
    dynamic service,
  ) async {
    // Show a modal progress indicator while signing in to prevent
    // accidental cancellation of the sign-in activity.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(child: CircularProgressIndicator()),
    );

    bool success = false;
    try {
      success = await backupProvider.signInToService(service);
    } catch (e) {
      debugPrint('Sign-in threw: $e');
      success = false;
    } finally {
      // Dismiss progress dialog if still mounted
      if (mounted) Navigator.pop(context);
    }

    if (success) {
      debugPrint('Signed in to ${service.serviceName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in to ${service.serviceName}')),
        );
      }
    } else {
      debugPrint('Failed to sign in to ${service.serviceName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () =>
                  _signInToService(context, backupProvider, service),
            ),
          ),
        );
      }
    }
  }

  void _showBackupOptions(
    BuildContext context,
    BackupProvider backupProvider,
    dynamic service,
    bool isSignedIn,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${service.serviceName} Backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (isSignedIn) ...[
              ListTile(
                leading: Icon(Icons.backup_outlined),
                title: Text('Create Backup'),
                onTap: () {
                  // Close the bottom sheet first using the sheet's context,
                  // then run the action using the outer settings screen context
                  Navigator.pop(sheetContext);
                  _createBackup(context, backupProvider, service);
                },
              ),
              ListTile(
                leading: Icon(Icons.restore_outlined),
                title: Text('Restore Backup'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _restoreBackup(context, backupProvider, service);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.login_outlined),
                title: Text('Sign In'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _signInToService(context, backupProvider, service);
                },
              ),
            ],
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup(
    BuildContext context,
    BackupProvider backupProvider,
    dynamic service,
  ) async {
    try {
      await backupProvider.restoreBackup(service);
      if (backupProvider.errorMessage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup restored successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${backupProvider.errorMessage}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}
