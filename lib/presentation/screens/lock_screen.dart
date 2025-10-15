import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business/providers/auth_provider.dart';
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
    _checkBiometricAvailability();
    _tryBiometricAuth();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final biometricAvailable = await authProvider.isBiometricAvailable();
    final biometricEnabled = await authProvider.isBiometricEnabled();

    setState(() {
      _isBiometricAvailable = biometricAvailable && biometricEnabled;
    });
  }

  Future<void> _tryBiometricAuth() async {
    // Slight delay to let screen render first
    await Future.delayed(Duration(milliseconds: 300));

    if (_isBiometricAvailable) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.authenticateWithBiometrics();
    }
  }

  void _handlePinSubmit(String pin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = await authProvider.authenticateWithPin(pin);

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
