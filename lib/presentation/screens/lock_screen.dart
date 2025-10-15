import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business/providers/settings_provider.dart';
import '../widgets/auth/pin_input.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final GlobalKey<PinInputState> _pinInputKey = GlobalKey<PinInputState>();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the UI is built before showing biometrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBiometrics();
    });
  }

  Future<void> _initBiometrics() async {
    try {
      // First check if biometrics are available and enabled
      await _checkBiometricAvailability();

      // Print debug information
      debugPrint("Biometric availability check completed");
      debugPrint("Is biometric available: $_isBiometricAvailable");

      // If biometrics are available, try to authenticate after UI is fully rendered
      if (_isBiometricAvailable && mounted) {
        // Add a slight delay to let the UI render fully
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted && !_isAuthenticating) {
          debugPrint("Auto-attempting biometric authentication");
          await _tryBiometricAuth();
        }
      } else {
        debugPrint(
          "Biometrics not available or not enabled, skipping authentication",
        );
      }
    } catch (e) {
      debugPrint("Error in biometric initialization: ${e.toString()}");
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      // Force a fresh check of biometric availability
      final biometricAvailable = await settingsProvider
          .checkBiometricAvailability();
      final biometricEnabled = settingsProvider.isBiometricEnabled;
      final isAuthEnabled = settingsProvider.isAuthEnabled;

      debugPrint("Biometric hardware available: $biometricAvailable");
      debugPrint("Biometric enabled in settings: $biometricEnabled");
      debugPrint("Auth enabled: $isAuthEnabled");

      // Biometrics should only be available if all conditions are met
      setState(() {
        _isBiometricAvailable =
            biometricAvailable && biometricEnabled && isAuthEnabled;
      });

      debugPrint("Final biometric availability: $_isBiometricAvailable");
    } catch (e) {
      debugPrint("Error checking biometric availability: $e");
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }

  // A flag to prevent multiple authentication attempts
  bool _isAuthenticating = false;

  Future<void> _tryBiometricAuth() async {
    if (_isAuthenticating) {
      debugPrint(
        "Biometric authentication already in progress, ignoring request",
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      // Call authenticate directly without the dialog/FutureBuilder
      final success = await settingsProvider.authenticateWithBiometrics();

      if (!success && mounted) {
        // Only show an error if authentication failed (not canceled)
        final errorMsg = settingsProvider.errorMessage;
        if (errorMsg != null && errorMsg.contains('failed') && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed. Please enter your PIN.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error during biometric authentication: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error. Please enter your PIN.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _handlePinSubmit(String pin) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isValid = await settingsProvider.authenticateWithPin(pin);

    if (!isValid && _pinInputKey.currentState != null) {
      _pinInputKey.currentState!.setError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon and name
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Passwords',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Enter your PIN',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 32),

              // PIN input
              PinInput(key: _pinInputKey, onCompleted: _handlePinSubmit),

              // Biometric option
              if (_isBiometricAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: TextButton.icon(
                    onPressed: _tryBiometricAuth,
                    icon: Icon(Icons.fingerprint),
                    label: Text('Use biometric'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
