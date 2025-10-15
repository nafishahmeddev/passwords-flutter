import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, error }

class SettingsProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Keys for secure storage
  static const String _themeModeKey = 'theme_mode';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _autoLockEnabledKey = 'auto_lock_enabled';
  static const String _autoLockDurationKey = 'auto_lock_duration';
  static const String _pinKey = 'app_pin';
  static const String _useBiometricKey = 'use_biometric';
  static const String _useAuthKey = 'use_auth';

  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;

  // Auto lock settings
  bool _autoLockEnabled = false;
  int _autoLockDuration = 1; // Minutes

  // Authentication settings
  bool _isAuthEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  AuthStatus _authStatus = AuthStatus.initial;
  String? _errorMessage;
  Timer? _autoLockTimer;
  DateTime? _lastActivityTime;

  // Getters for all settings
  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  bool get autoLockEnabled => _autoLockEnabled;
  int get autoLockDuration => _autoLockDuration;

  // Auth getters
  AuthStatus get authStatus => _authStatus;
  String? get errorMessage => _errorMessage;
  bool get isAuthEnabled => _isAuthEnabled;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;

  // Computed properties
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  SettingsProvider() {
    _lastActivityTime = DateTime.now();
    _loadSettings();
    _setupAutoLock();
  }

  Future<void> _loadSettings() async {
    // Load theme settings
    final themeModeStr = await _secureStorage.read(key: _themeModeKey);
    if (themeModeStr != null) {
      switch (themeModeStr) {
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
      }
    }

    final dynamicColorStr = await _secureStorage.read(key: _useDynamicColorKey);
    if (dynamicColorStr != null) {
      _useDynamicColor = dynamicColorStr == 'true';
    }

    // Load auto lock settings
    final autoLockEnabledStr = await _secureStorage.read(
      key: _autoLockEnabledKey,
    );
    if (autoLockEnabledStr != null) {
      _autoLockEnabled = autoLockEnabledStr == 'true';
    }

    final autoLockDurationStr = await _secureStorage.read(
      key: _autoLockDurationKey,
    );
    if (autoLockDurationStr != null) {
      _autoLockDuration = int.tryParse(autoLockDurationStr) ?? 1;
    }

    // Load authentication settings
    try {
      _isAuthEnabled = await _isAuthEnabledFromStorage();
      _isBiometricAvailable = await checkBiometricAvailability();
      _isBiometricEnabled = await _isBiometricEnabledFromStorage();

      // Check authentication status
      await checkAuthStatus();
    } catch (e) {
      _authStatus = AuthStatus.error;
      _errorMessage = 'Failed to load authentication settings: ${e.toString()}';
    }

    notifyListeners();
  }

  // Theme settings methods
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _secureStorage.write(
      key: _themeModeKey,
      value: mode.toString().split('.').last,
    );
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;

    _useDynamicColor = value;
    await _secureStorage.write(
      key: _useDynamicColorKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  // Auto lock settings methods
  Future<void> setAutoLockEnabled(bool value) async {
    if (_autoLockEnabled == value) return;

    _autoLockEnabled = value;
    await _secureStorage.write(
      key: _autoLockEnabledKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setAutoLockDuration(int minutes) async {
    if (_autoLockDuration == minutes) return;

    _autoLockDuration = minutes;
    await _secureStorage.write(
      key: _autoLockDurationKey,
      value: minutes.toString(),
    );
    notifyListeners();
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    await _secureStorage.delete(key: _themeModeKey);
    await _secureStorage.delete(key: _useDynamicColorKey);
    await _secureStorage.delete(key: _autoLockEnabledKey);
    await _secureStorage.delete(key: _autoLockDurationKey);

    _themeMode = ThemeMode.system;
    _useDynamicColor = true;
    _autoLockEnabled = false;
    _autoLockDuration = 1;

    notifyListeners();
  }

  // AUTHENTICATION METHODS

  // Check if authentication is required
  Future<void> checkAuthStatus() async {
    try {
      final isAuthEnabled = await _isAuthEnabledFromStorage();
      if (!isAuthEnabled) {
        _authStatus = AuthStatus.authenticated; // No auth required
      } else {
        _authStatus = AuthStatus.unauthenticated; // Authentication required
      }
      notifyListeners();
    } catch (e) {
      _authStatus = AuthStatus.error;
      _errorMessage = 'Failed to check authentication status';
      notifyListeners();
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    try {
      final result = await verifyPin(pin);
      if (result) {
        _authStatus = AuthStatus.authenticated;
        _lastActivityTime = DateTime.now(); // Reset activity timer
        notifyListeners();
      }
      return result;
    } catch (e) {
      _authStatus = AuthStatus.error;
      _errorMessage = 'PIN verification failed';
      notifyListeners();
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final biometricsEnabled = _isAuthEnabled && _isBiometricEnabled;
      if (!biometricsEnabled) {
        return true; // If biometric not enabled, allow access
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (result) {
        _authStatus = AuthStatus.authenticated;
        _lastActivityTime = DateTime.now(); // Reset activity timer
        notifyListeners();
      }
      return result;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        // Handle case when biometrics is not available or not enrolled
        _isBiometricAvailable = false;
        notifyListeners();
        return false;
      }
      _errorMessage = 'Biometric authentication failed';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Biometric authentication failed';
      notifyListeners();
      return false;
    }
  }

  // Check if biometric is available
  Future<bool> checkBiometricAvailability() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  // Read auth enabled setting from storage
  Future<bool> _isAuthEnabledFromStorage() async {
    final value = await _secureStorage.read(key: _useAuthKey);
    return value == 'true';
  }

  // Read biometric enabled setting from storage
  Future<bool> _isBiometricEnabledFromStorage() async {
    final value = await _secureStorage.read(key: _useBiometricKey);
    return value == 'true';
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

  // Set biometric enabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _useBiometricKey,
      value: enabled.toString(),
    );
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  // Set authentication enabled
  Future<void> setAuthEnabled(bool enabled) async {
    await _secureStorage.write(key: _useAuthKey, value: enabled.toString());
    _isAuthEnabled = enabled;
    await checkAuthStatus();
  }

  // Lock the app
  void lockApp() {
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Record user activity
  void recordUserActivity() {
    _lastActivityTime = DateTime.now();
  }

  // Auto lock functionality
  void _setupAutoLock() {
    // Cancel existing timer
    _autoLockTimer?.cancel();

    // If auto-lock is disabled, don't start timer
    if (!_autoLockEnabled) return;

    // Create periodic timer to check for inactivity
    _autoLockTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _checkAutoLock();
    });
  }

  void _checkAutoLock() {
    if (!_autoLockEnabled ||
        _authStatus != AuthStatus.authenticated ||
        _lastActivityTime == null) {
      return;
    }

    final now = DateTime.now();
    final inactivityDuration = now.difference(_lastActivityTime!);

    // Lock app if inactive for longer than auto-lock duration
    if (inactivityDuration.inMinutes >= _autoLockDuration) {
      lockApp();
    }
  }

  // Reset all authentication settings
  Future<void> resetAuth() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _useBiometricKey);
    await _secureStorage.delete(key: _useAuthKey);

    _isAuthEnabled = false;
    _isBiometricEnabled = false;
    _authStatus = AuthStatus.authenticated;

    notifyListeners();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }
}

// Extension for the ThemeMode enum to make it easier to display
extension ThemeModeExtension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
