import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth/pin_input.dart';
import '../../business/providers/settings_provider.dart';
import '../../business/services/favicon_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // UI state for PIN setup
  bool _isSettingPin = false;
  String? _newPin;
  bool _isPinSetup = false;

  // Used for PIN input control
  final GlobalKey<PinInputState> _pinInputKey = GlobalKey<PinInputState>();

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

    setState(() {
      _isPinSetup = isPinSet;
    });
  }

  void _handlePinCompleted(String pin) {
    if (_newPin == null) {
      // First entry
      setState(() {
        _newPin = pin;
      });
      // Reset the PIN input UI for confirmation
      _pinInputKey.currentState?.resetPin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirm your PIN'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      // Confirm entry
      if (_newPin == pin) {
        _savePin(pin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PINs do not match. Try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: EdgeInsets.all(16),
          ),
        );
        setState(() {
          _newPin = null;
        });
        // Reset PIN input UI when there's an error
        _pinInputKey.currentState?.resetPin();
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.savePin(pin);
    await settingsProvider.setAuthEnabled(true);

    setState(() {
      _isSettingPin = false;
      _newPin = null;
      _isPinSetup = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PIN setup successful'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), elevation: 0),
      body: _isSettingPin ? _buildPinSetupScreen() : _buildSettingsScreen(),
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

              const Divider(height: 0),

              // Dynamic color setting
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
                onTap: () {
                  setState(() {
                    _isSettingPin = true;
                    _newPin = null;
                  });
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
                      return Text('Cache size: ${sizeInMB} MB');
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

  Widget _buildPinSetupScreen() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _newPin == null ? 'Create PIN' : 'Confirm PIN',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _newPin == null
                        ? 'Enter a 4-digit PIN to secure your app'
                        : 'Enter the same PIN again to confirm',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  PinInput(key: _pinInputKey, onCompleted: _handlePinCompleted),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSettingPin = false;
                    _newPin = null;
                  });
                },
                child: Text('Cancel'),
              ),
              // Right side empty for balance
              SizedBox(width: 64),
            ],
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
          RadioListTile<ThemeMode>(
            title: Text('System'),
            value: ThemeMode.system,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await settingsProvider.setThemeMode(value);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text('Light'),
            value: ThemeMode.light,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await settingsProvider.setThemeMode(value);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text('Dark'),
            value: ThemeMode.dark,
            groupValue: settingsProvider.themeMode,
            onChanged: (value) async {
              if (value != null) {
                await settingsProvider.setThemeMode(value);
                Navigator.pop(context);
              }
            },
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

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Auto Lock Duration'),
        children: [
          for (final duration in [1, 5, 10, 30, 60])
            RadioListTile<int>(
              title: Text('${duration} minute${duration > 1 ? 's' : ''}'),
              value: duration,
              groupValue: settingsProvider.autoLockDuration,
              onChanged: (value) async {
                if (value != null) {
                  await settingsProvider.setAutoLockDuration(value);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }
}
