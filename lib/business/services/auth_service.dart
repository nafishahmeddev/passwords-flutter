import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static const String _pinKey = 'app_pin';
  static const String _useBiometricKey = 'use_biometric';
  static const String _useAuthKey = 'use_auth';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Get available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool biometricsEnabled =
          await isAuthEnabled() && await isBiometricEnabled();
      if (!biometricsEnabled)
        return true; // If biometric not enabled, allow access

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        // Handle case when biometrics is not available or not enrolled
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Save PIN
  Future<void> savePin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return pin == storedPin;
  }

  // Check if PIN is set
  Future<bool> isPinSet() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _useBiometricKey,
      value: enabled.toString(),
    );
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _useBiometricKey);
    return value == 'true';
  }

  // Enable/disable authentication completely
  Future<void> setAuthEnabled(bool enabled) async {
    await _secureStorage.write(key: _useAuthKey, value: enabled.toString());
  }

  // Check if any authentication is enabled
  Future<bool> isAuthEnabled() async {
    final value = await _secureStorage.read(key: _useAuthKey);
    return value == 'true';
  }

  // Delete PIN
  Future<void> deletePin() async {
    await _secureStorage.delete(key: _pinKey);
  }

  // Reset all authentication settings
  Future<void> resetAuth() async {
    await _secureStorage.deleteAll();
  }
}
