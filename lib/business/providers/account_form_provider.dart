import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

enum AccountFormState { initial, loading, loaded, saving, error }

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
      notifyListeners();
    }
  }

  // Add a new field to the form
  void addField(AccountField newField) {
    if (_state == AccountFormState.loaded) {
      _fields = List<AccountField>.from(_fields)..add(newField);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Update account in memory only (doesn't persist to database)
  void updateAccount(Account updatedAccount) {
    if (_state == AccountFormState.loaded) {
      _account = updatedAccount;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Remove a field from the form
  void removeField(String fieldId) {
    if (_state == AccountFormState.loaded) {
      _fields = _fields.where((field) => field.id != fieldId).toList();
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Save all changes to database
  Future<void> saveChanges() async {
    if (_state == AccountFormState.loaded) {
      try {
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
