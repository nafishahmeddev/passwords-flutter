import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'settings_provider.dart';

enum AuthStatus { initial, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  Timer? _autoLockTimer;
  DateTime? _lastActivityTime;
  SettingsProvider? _settingsProvider;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
    _setupAutoLock();
  }

  AuthProvider() {
    // Check if authentication is enabled
    checkAuthStatus();
    _lastActivityTime = DateTime.now();
  }

  // Check if any authentication is required
  Future<void> checkAuthStatus() async {
    try {
      final isAuthEnabled = await _authService.isAuthEnabled();
      if (!isAuthEnabled) {
        _status = AuthStatus.authenticated; // No auth required
      } else {
        _status = AuthStatus.unauthenticated; // Authentication required
      }
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to check authentication status';
      notifyListeners();
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    try {
      final result = await _authService.verifyPin(pin);
      if (result) {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      return result;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'PIN verification failed';
      notifyListeners();
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final result = await _authService.authenticateWithBiometrics();
      if (result) {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      return result;
    } catch (e) {
      _errorMessage = 'Biometric authentication failed';
      notifyListeners();
      return false;
    }
  }

  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    return await _authService.isBiometricEnabled();
  }

  // Save PIN
  Future<void> savePin(String pin) async {
    await _authService.savePin(pin);
  }

  // Set biometric enabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await _authService.setBiometricEnabled(enabled);
  }

  // Set auth enabled
  Future<void> setAuthEnabled(bool enabled) async {
    await _authService.setAuthEnabled(enabled);
    await checkAuthStatus();
  }

  // Log out (lock app)
  void lockApp() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Record user activity to prevent auto-lock during active use
  void recordUserActivity() {
    _lastActivityTime = DateTime.now();
  }

  // Setup auto-lock timer
  void _setupAutoLock() {
    // Cancel any existing timer
    _autoLockTimer?.cancel();

    // If settings provider is not set or auto-lock is disabled, return
    if (_settingsProvider == null || !_settingsProvider!.autoLockEnabled) {
      return;
    }

    // Create a periodic timer that checks if the app should be locked
    _autoLockTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _checkAutoLock();
    });
  }

  // Check if the app should be auto-locked based on inactivity
  void _checkAutoLock() {
    if (_settingsProvider == null ||
        !_settingsProvider!.autoLockEnabled ||
        _status != AuthStatus.authenticated ||
        _lastActivityTime == null) {
      return;
    }

    final now = DateTime.now();
    final inactivityDuration = now.difference(_lastActivityTime!);
    final autoLockMinutes = _settingsProvider!.autoLockDuration;

    // Lock the app if inactive for longer than the auto-lock duration
    if (inactivityDuration.inMinutes >= autoLockMinutes) {
      lockApp();
    }
  }

  // Update auto-lock settings when they change
  void updateAutoLockSettings() {
    _setupAutoLock();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }
}
