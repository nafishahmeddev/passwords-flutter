import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth/pin_input.dart';
import '../../business/providers/auth_provider.dart';
import '../../business/services/auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isAuthEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isPinSetup = false;
  bool _isSettingPin = false;
  String? _newPin;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isAuthEnabled = await _authService.isAuthEnabled();
    final isBiometricAvailable = await _authService.isBiometricAvailable();
    final isBiometricEnabled = await _authService.isBiometricEnabled();
    final isPinSet = await _authService.isPinSet();

    setState(() {
      _isAuthEnabled = isAuthEnabled;
      _isBiometricAvailable = isBiometricAvailable;
      _isBiometricEnabled = isBiometricEnabled;
      _isPinSetup = isPinSet;
    });
  }

  final GlobalKey<PinInputState> _pinInputKey = GlobalKey<PinInputState>();

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.savePin(pin);
    await authProvider.setAuthEnabled(true);

    setState(() {
      _isSettingPin = false;
      _newPin = null;
      _isPinSetup = true;
      _isAuthEnabled = true;
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
      appBar: AppBar(title: Text('Security Settings'), elevation: 0),
      body: _isSettingPin ? _buildPinSetupScreen() : _buildSettingsScreen(),
    );
  }

  Widget _buildSettingsScreen() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // App lock section
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
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
                value: _isAuthEnabled,
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

                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.setAuthEnabled(value);
                  setState(() {
                    _isAuthEnabled = value;
                    if (!value) {
                      _isBiometricEnabled = false;
                    }
                  });
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
              if (_isAuthEnabled && _isBiometricAvailable)
                const Divider(height: 0),

              if (_isAuthEnabled && _isBiometricAvailable)
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
                  value: _isBiometricEnabled,
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

                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.setBiometricEnabled(value);
                    setState(() {
                      _isBiometricEnabled = value;
                    });
                  },
                ),
            ],
          ),
        ),

        // Reset security section
        if (_isPinSetup)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Card(
              margin: EdgeInsets.zero,
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
          ),

        // Info text about security
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
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
              padding: const EdgeInsets.all(16.0),
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

  void _showResetConfirmation() {
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
              await _resetSecurity();
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSecurity() async {
    await _authService.resetAuth();
    await _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security settings reset'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
