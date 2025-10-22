import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth/pin_input.dart';
import '../../business/providers/settings_provider.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _newPin;
  final GlobalKey<PinInputState> _pinInputKey = GlobalKey<PinInputState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  Icons.lock_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),

                SizedBox(height: 24),

                // Title
                Text(
                  _newPin == null ? 'Create PIN' : 'Confirm PIN',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Subtitle
                Text(
                  _newPin == null
                      ? 'Enter a 4-digit PIN to secure your app'
                      : 'Enter the same PIN again to confirm',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 48),

                // PIN Input
                PinInput(key: _pinInputKey, onCompleted: _handlePinCompleted),

                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PIN setup successful'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          margin: EdgeInsets.all(16),
        ),
      );

      // Return success to settings screen
      Navigator.pop(context, true);
    }
  }
}
