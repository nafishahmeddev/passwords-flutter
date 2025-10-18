import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import '../services/favicon_service.dart';
import '../services/service_icon_service.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

enum AccountFormState { initial, loading, loaded, saving, error }

// Validation results
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.valid() {
    return ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

class AccountFormProvider extends ChangeNotifier {
  final AccountRepository repository;
  final String? accountId; // Made nullable for create mode
  final bool isCreateMode;
  final List<AccountField>? templateFields; // Template fields for create mode

  List<AccountField> _originalFields = [];
  AccountFormState _state = AccountFormState.initial;
  Account? _account;
  List<AccountField> _fields = [];
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  bool _isInitialLoad = true;
  final Map<String, bool> _loadingFavicons = {};
  final Map<String, List<Uint8List>> _cachedFavicons = {};
  final Map<String, String> _validationErrors = {};
  final Map<String, Map<String, String>> _fieldValidationErrors = {};

  AccountFormProvider({
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
    this.templateFields,
  }) {
    if (!isCreateMode && accountId == null) {
      throw ArgumentError('accountId is required when not in create mode');
    }
  }

  // Getters
  AccountFormState get state => _state;
  Account? get account => _account;
  List<AccountField> get fields => _fields;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AccountFormState.loading;
  bool get isSaving => _state == AccountFormState.saving;
  bool get hasError => _state == AccountFormState.error;
  // True if any favicon is currently being fetched
  bool get isLoadingFavicon => _loadingFavicons.values.any((v) => v);
  Map<String, List<Uint8List>> get cachedFavicons => _cachedFavicons;

  /// Returns favicon candidates for a given website URL
  List<Uint8List> getFaviconsForUrl(String url) => _cachedFavicons[url] ?? [];

  /// Save a favicon candidate to a file and return the file path
  Future<String?> saveFaviconCandidateToFile(String url, int index) async {
    final candidates = _cachedFavicons[url];
    if (candidates == null || index < 0 || index >= candidates.length)
      return null;
    try {
      final bytes = candidates[index];
      final dir = await getApplicationDocumentsDirectory();
      final hash = sha256
          .convert(
            utf8.encode('$url-$index-${DateTime.now().millisecondsSinceEpoch}'),
          )
          .toString();
      final filePath = '${dir.path}/selected_favicon_$hash.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Map<String, String> get validationErrors => _validationErrors;
  Map<String, Map<String, String>> get fieldValidationErrors =>
      _fieldValidationErrors;

  // Load account and fields from database into form state
  Future<void> loadFields() async {
    _state = AccountFormState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      if (isCreateMode) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _account = Account(name: '', createdAt: now, updatedAt: now);
        _fields = templateFields ?? [];
      } else {
        _account = await repository.getAccounts().then(
          (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
        );
        _fields = await repository.getFields(accountId!);
        _originalFields = List.from(_fields);
      }
      _hasUnsavedChanges = false;
      _isInitialLoad = false;
      _state = AccountFormState.loaded;
    } catch (e) {
      _state = AccountFormState.error;
      _errorMessage = 'Failed to load account and fields';
    }
    notifyListeners();

    // After fields are loaded, attempt to fetch favicons for existing website fields
    if (_state == AccountFormState.loaded) {
      _fetchFaviconsForExistingFields();
    }
  }

  // Update a field in memory only (doesn't persist to database)
  void updateField(AccountField updatedField) {
    if (_state != AccountFormState.loaded) return;
    _fields = _fields
        .map((field) => field.id == updatedField.id ? updatedField : field)
        .toList();
    _hasUnsavedChanges = true;
    _validateField(updatedField);
    if (updatedField.type == AccountFieldType.website) {
      _autoFetchFaviconIfNeeded(updatedField);
      _autoAssignLogoIfNeeded();
    }
    notifyListeners();
  }

  // Add a new field to the form
  void addField(AccountField newField) {
    if (_state != AccountFormState.loaded) return;
    _fields = List<AccountField>.from(_fields)..add(newField);
    _hasUnsavedChanges = true;
    _validateField(newField);
    if (newField.type == AccountFieldType.website) {
      _autoFetchFaviconIfNeeded(newField);
      _autoAssignLogoIfNeeded();
    }
    notifyListeners();
  }

  // Update account in memory only (doesn't persist to database)
  void updateAccount(Account updatedAccount) {
    if (_state != AccountFormState.loaded) return;
    _isInitialLoad = false;
    _account = updatedAccount;
    _hasUnsavedChanges = true;
    _validateAccount();
    _autoAssignLogoIfNeeded();
    notifyListeners();
  }

  // Update account logo
  void updateAccountLogo(LogoType? logoType, String? logoData) {
    if (_state != AccountFormState.loaded || _account == null) return;
    _account = _account!.copyWith(logoType: logoType, logo: logoData);
    _hasUnsavedChanges = true;
    notifyListeners();
    // If logo is removed, do NOT auto-assign a service icon
    if (logoType == null && logoData == null) {
      // Prevent auto-assign logic from running
      // Clear any cached favicon selection for this account
      if (_account != null) {
        // Remove any favicon file previously selected for this account
        // Optionally, clear favicon cache for all website URLs for this account
        for (final url in getWebsiteUrls()) {
          _cachedFavicons.remove(url);
        }
      }
      return;
    }
  }

  // Remove a field from the form
  void removeField(String fieldId) {
    if (_state != AccountFormState.loaded) return;
    _fields = _fields.where((field) => field.id != fieldId).toList();
    _fieldValidationErrors.remove(fieldId);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  // Validation methods
  void _validateAccount() {
    _validationErrors.clear();
    if (_isInitialLoad) return;
    if (_account?.name.trim().isEmpty ?? true) {
      _validationErrors['name'] = 'Account name is required';
    } else if (_account!.name.trim().length < 2) {
      _validationErrors['name'] = 'Account name must be at least 2 characters';
    } else if (_account!.name.trim().length > 100) {
      _validationErrors['name'] =
          'Account name must be less than 100 characters';
    }
  }

  // Silent version that doesn't call notifyListeners

  void _validateField(AccountField field) {
    final errors = <String, String>{};
    if (field.label.trim().isEmpty) {
      errors['label'] = 'Field label is required';
    } else if (field.label.trim().length < 2) {
      errors['label'] = 'Field label must be at least 2 characters';
    } else if (field.label.trim().length > 50) {
      errors['label'] = 'Field label must be less than 50 characters';
    }
    switch (field.type) {
      case AccountFieldType.credential:
        _validateCredentialField(field, errors);
        break;
      case AccountFieldType.password:
        _validatePasswordField(field, errors);
        break;
      case AccountFieldType.website:
        _validateWebsiteField(field, errors);
        break;
      case AccountFieldType.text:
        _validateTextField(field, errors);
        break;
      case AccountFieldType.otp:
        _validateOtpField(field, errors);
        break;
    }
    if (errors.isEmpty) {
      _fieldValidationErrors.remove(field.id);
    } else {
      _fieldValidationErrors[field.id] = errors;
    }
  }

  // Removed silent version, merged into _validateField

  void _validateCredentialField(
    AccountField field,
    Map<String, String> errors,
  ) {
    final username = field.getMetadata('username');
    final password = field.getMetadata('password');
    if (username.isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.length < 2) {
      errors['username'] = 'Username must be at least 2 characters';
    } else if (username.length > 100) {
      errors['username'] = 'Username must be less than 100 characters';
    }
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length > 500) {
      errors['password'] = 'Password must be less than 500 characters';
    }
  }

  void _validatePasswordField(AccountField field, Map<String, String> errors) {
    final password = field.getMetadata('value');

    if (password.isEmpty) {
      errors['value'] = 'Password is required';
    } else if (password.length < 8) {
      errors['value'] = 'Password must be at least 8 characters';
    } else if (password.length > 500) {
      errors['value'] = 'Password must be less than 500 characters';
    }
  }

  void _validateWebsiteField(AccountField field, Map<String, String> errors) {
    final url = field.getMetadata('value');

    if (url.isEmpty) {
      errors['value'] = 'Website URL is required';
    } else if (!_isValidUrl(url)) {
      errors['value'] = 'Please enter a valid URL (e.g., https://example.com)';
    }
  }

  void _validateTextField(AccountField field, Map<String, String> errors) {
    final value = field.getMetadata('value');

    if (value.isEmpty) {
      errors['value'] = 'Text value is required';
    } else if (value.length > 1000) {
      errors['value'] = 'Text must be less than 1000 characters';
    }
  }

  void _validateOtpField(AccountField field, Map<String, String> errors) {
    final secret = field.getMetadata('secret');
    final issuer = field.getMetadata('issuer');
    final accountName = field.getMetadata('account_name');
    final period = field.getMetadata('period');
    final digits = field.getMetadata('digits');

    if (secret.isEmpty) {
      errors['secret'] = 'Secret key is required';
    } else if (secret.length < 16) {
      errors['secret'] = 'Secret key must be at least 16 characters';
    }

    if (issuer.isNotEmpty && issuer.length > 50) {
      errors['issuer'] = 'Issuer must be less than 50 characters';
    }

    if (accountName.isNotEmpty && accountName.length > 50) {
      errors['account_name'] = 'Account name must be less than 50 characters';
    }

    final periodInt = int.tryParse(period);
    if (period.isNotEmpty &&
        (periodInt == null || periodInt < 15 || periodInt > 300)) {
      errors['period'] = 'Period must be between 15 and 300 seconds';
    }

    final digitsInt = int.tryParse(digits);
    if (digits.isNotEmpty &&
        (digitsInt == null || digitsInt < 6 || digitsInt > 8)) {
      errors['digits'] = 'Digits must be between 6 and 8';
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  ValidationResult validateForm() {
    final errors = <String>[];
    _validateAccount();
    if (_validationErrors.isNotEmpty) {
      errors.addAll(_validationErrors.values);
    }
    for (final field in _fields) {
      _validateField(field);
    }
    if (_fieldValidationErrors.isNotEmpty) {
      for (final fieldErrors in _fieldValidationErrors.values) {
        errors.addAll(fieldErrors.values);
      }
    }
    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  // Get validation error for a specific field property
  String? getFieldValidationError(String fieldId, String property) {
    return _fieldValidationErrors[fieldId]?[property];
  }

  // Get validation error for account property
  String? getAccountValidationError(String property) {
    return _validationErrors[property];
  }

  // Save all changes to database
  Future<void> saveChanges() async {
    if (_state == AccountFormState.loaded) {
      try {
        // Validate form before saving
        final validationResult = validateForm();
        if (!validationResult.isValid) {
          _state = AccountFormState.error;
          _errorMessage =
              'Please fix the following errors:\n• ${validationResult.errors.join('\n• ')}';
          notifyListeners();
          return;
        }

        _state = AccountFormState.saving;
        _errorMessage = null;
        notifyListeners();

        // Save account to database
        String savedAccountId;
        if (isCreateMode) {
          // Create mode: insert new account
          final accountToInsert = _account!.copyWith(
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          savedAccountId = await repository.insertAccount(accountToInsert);
        } else {
          // Edit mode: update existing account
          await repository.updateAccount(
            _account!.copyWith(
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          savedAccountId = accountId!;
        }

        // Delete fields that were removed
        final currentFieldIds = _fields.map((f) => f.id).toSet();
        final fieldsToDelete = _originalFields
            .where((field) => !currentFieldIds.contains(field.id))
            .toList();
        for (final field in fieldsToDelete) {
          await repository.deleteField(field.id);
        }

        // Save all fields to database using upsert logic
        for (final field in _fields) {
          // Check if field exists by trying to get it
          final existingFields = await repository.getFields(savedAccountId);
          final existingField = existingFields
              .where((f) => f.id == field.id)
              .firstOrNull;

          if (existingField == null) {
            // Field doesn't exist - insert it
            final fieldToInsert = field.copyWith(accountId: savedAccountId);
            await repository.insertField(fieldToInsert);
          } else {
            // Field exists - update it
            await repository.updateField(field);
          }
        }

        // Reload from database to get updated IDs and confirm save
        await loadFields();
        _hasUnsavedChanges = false;

        // Publish event for other parts of the app to react
        final savedAccount = _account!;
        if (isCreateMode) {
          AccountEventBus().publish(AccountCreated(savedAccount));
        } else {
          AccountEventBus().publish(AccountUpdated(savedAccount));
        }
      } catch (e) {
        _state = AccountFormState.error;
        _errorMessage = 'Failed to save changes: $e';
        notifyListeners();
      }
    }
  }

  // Discard changes and reload from database
  Future<void> discardChanges() async {
    await loadFields();
  }

  // Auto-fetch favicon for website fields if service is not known
  Future<void> _autoFetchFaviconIfNeeded(AccountField websiteField) async {
    final url = websiteField.getMetadata('value');
    if (url.isEmpty || !FaviconService.isValidUrl(url)) return;
    if (_cachedFavicons.containsKey(url) || _loadingFavicons[url] == true)
      return;
    _loadingFavicons[url] = true;
    notifyListeners();
    try {
      final favs = await FaviconService.fetchFavicons(url);
      if (favs.isNotEmpty) {
        _cachedFavicons[url] = favs;
      } else {
        _cachedFavicons[url] = [];
      }
      _autoAssignLogoIfNeeded();
    } catch (e) {
      _cachedFavicons[url] = [];
    } finally {
      _loadingFavicons[url] = false;
      notifyListeners();
    }
  }

  // Trigger favicon fetching for all website fields asynchronously
  void _fetchFaviconsForExistingFields() {
    for (final websiteField in _fields.where(
      (f) => f.type == AccountFieldType.website,
    )) {
      // Don't await - start fetches concurrently and let them update state
      _autoFetchFaviconIfNeeded(websiteField);
    }
  }

  // Auto-assign logo based on priority: service detection > favicon > fallback
  void _autoAssignLogoIfNeeded() {
    if (!isCreateMode || _account?.logo != null) return;
    // Only auto-assign if logoType and logo are both null AND not just removed
    if (_account?.logoType == null && _account?.logo == null) {
      final websiteUrls = getWebsiteUrls();
      final firstWebsiteUrl = websiteUrls.isNotEmpty ? websiteUrls.first : null;
      final detectedService = ServiceIconService.findServiceIcon(
        _account?.name,
        firstWebsiteUrl,
      );
      if (detectedService != null) {
        updateAccountLogo(LogoType.icon, detectedService.name);
        return;
      }
      final faviconUrl = websiteUrls.firstWhere(
        (url) => (_cachedFavicons[url] ?? []).isNotEmpty,
        orElse: () => '',
      );
      if (faviconUrl.isNotEmpty) {
        updateAccountLogo(LogoType.url, faviconUrl);
        return;
      }
      // Fallback: let AccountLogo widget handle
    }
  }

  // Get all website URLs from fields
  List<String> getWebsiteUrls() {
    return _fields
        .where((field) => field.type == AccountFieldType.website)
        .map((field) => field.getMetadata('value'))
        .where((url) => url.isNotEmpty && FaviconService.isValidUrl(url))
        .toList();
  }

  // Check if save should be disabled (while loading favicon)
  bool get canSave {
    // Disable save if any favicon is loading or not loaded
    if (isLoadingFavicon || _state != AccountFormState.loaded) {
      return false;
    }
    // For create mode, allow saving when form is valid (even without changes)
    // For edit mode, require unsaved changes
    return isCreateMode || _hasUnsavedChanges;
  }
}
