import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
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

  List<AccountField> _originalFields =
      []; // Track original fields for deletion detection

  AccountFormState _state = AccountFormState.initial;
  Account? _account;
  List<AccountField> _fields = [];
  bool _hasUnsavedChanges = false;
  String? _errorMessage;

  // Validation state
  Map<String, String> _validationErrors = {};
  Map<String, Map<String, String>> _fieldValidationErrors = {};

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
  Map<String, String> get validationErrors => _validationErrors;
  Map<String, Map<String, String>> get fieldValidationErrors =>
      _fieldValidationErrors;

  // Load account and fields from database into form state
  Future<void> loadFields() async {
    try {
      _state = AccountFormState.loading;
      _errorMessage = null;
      notifyListeners();

      if (isCreateMode) {
        // Create mode: start with empty account and template fields (if provided)
        final now = DateTime.now().millisecondsSinceEpoch;
        final newAccount = Account(name: '', createdAt: now, updatedAt: now);
        final fields = templateFields ?? [];
        _account = newAccount;
        _fields = fields;
        _hasUnsavedChanges = false;
        _state = AccountFormState.loaded;
        notifyListeners();
      } else {
        // Edit mode: load existing account and fields
        final account = await repository.getAccounts().then(
          (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
        );
        final fields = await repository.getFields(accountId!);
        _originalFields = List.from(
          fields,
        ); // Store original fields for deletion detection
        _account = account;
        _fields = fields;
        _hasUnsavedChanges = false;
        _state = AccountFormState.loaded;
        notifyListeners();
      }
    } catch (e) {
      _state = AccountFormState.error;
      _errorMessage = 'Failed to load account and fields';
      notifyListeners();
    }
  }

  // Update a field in memory only (doesn't persist to database)
  void updateField(AccountField updatedField) {
    if (_state == AccountFormState.loaded) {
      _fields = _fields.map((field) {
        return field.id == updatedField.id ? updatedField : field;
      }).toList();
      _hasUnsavedChanges = true;
      validateField(updatedField);
      notifyListeners();
    }
  }

  // Add a new field to the form
  void addField(AccountField newField) {
    if (_state == AccountFormState.loaded) {
      _fields = List<AccountField>.from(_fields)..add(newField);
      _hasUnsavedChanges = true;
      validateField(newField);
      notifyListeners();
    }
  }

  // Update account in memory only (doesn't persist to database)
  void updateAccount(Account updatedAccount) {
    if (_state == AccountFormState.loaded) {
      _account = updatedAccount;
      _hasUnsavedChanges = true;
      _validateAccount();
      notifyListeners();
    }
  }

  // Remove a field from the form
  void removeField(String fieldId) {
    if (_state == AccountFormState.loaded) {
      _fields = _fields.where((field) => field.id != fieldId).toList();
      _fieldValidationErrors.remove(fieldId);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Validation methods
  void _validateAccount() {
    _validationErrors.clear();
    print('🔍 Validating account: ${_account?.name ?? 'null'}'); // DEBUG

    if (_account?.name.trim().isEmpty ?? true) {
      _validationErrors['name'] = 'Account name is required';
      print('❌ Account validation error: Account name is required'); // DEBUG
    } else if (_account!.name.trim().length < 2) {
      _validationErrors['name'] = 'Account name must be at least 2 characters';
      print('❌ Account validation error: Account name must be at least 2 characters'); // DEBUG
    } else if (_account!.name.trim().length > 100) {
      _validationErrors['name'] =
          'Account name must be less than 100 characters';
      print('❌ Account validation error: Account name must be less than 100 characters'); // DEBUG
    } else {
      print('✅ Account validation passed'); // DEBUG
    }
  }

  void validateField(AccountField field) {
    final errors = <String, String>{};
    print('🔍 Validating field: ${field.label} (${field.type})'); // DEBUG

    // Validate label
    if (field.label.trim().isEmpty) {
      errors['label'] = 'Field label is required';
      print('❌ Field validation error: Field label is required'); // DEBUG
    } else if (field.label.trim().length < 2) {
      errors['label'] = 'Field label must be at least 2 characters';
      print('❌ Field validation error: Field label must be at least 2 characters'); // DEBUG
    } else if (field.label.trim().length > 50) {
      errors['label'] = 'Field label must be less than 50 characters';
      print('❌ Field validation error: Field label must be less than 50 characters'); // DEBUG
    }

    // Validate field-specific data
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
      print('✅ Field validation passed for ${field.label}'); // DEBUG
    } else {
      _fieldValidationErrors[field.id] = errors;
      print('❌ Field validation errors for ${field.label}: $errors'); // DEBUG
    }

    notifyListeners();
  }

  void _validateCredentialField(
    AccountField field,
    Map<String, String> errors,
  ) {
    final username = field.getMetadata('username');
    final password = field.getMetadata('password');
    print('🔍 Validating credential field - username: "$username", password: "$password"'); // DEBUG

    // Validate username
    if (username.isEmpty) {
      errors['username'] = 'Username is required';
      print('❌ Credential error: Username is required'); // DEBUG
    } else if (username.length < 2) {
      errors['username'] = 'Username must be at least 2 characters';
      print('❌ Credential error: Username must be at least 2 characters'); // DEBUG
    } else if (username.length > 100) {
      errors['username'] = 'Username must be less than 100 characters';
      print('❌ Credential error: Username must be less than 100 characters'); // DEBUG
    }

    // Validate password
    if (password.isEmpty) {
      errors['password'] = 'Password is required';
      print('❌ Credential error: Password is required'); // DEBUG
    } else if (password.length > 500) {
      errors['password'] = 'Password must be less than 500 characters';
      print('❌ Credential error: Password must be less than 500 characters'); // DEBUG
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

    // Validate account
    _validateAccount();
    if (_validationErrors.isNotEmpty) {
      errors.addAll(_validationErrors.values);
    }

    // Validate all fields
    for (final field in _fields) {
      validateField(field);
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
}
