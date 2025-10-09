import 'package:bloc/bloc.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

part 'account_form_state.dart';

class AccountFormCubit extends Cubit<AccountFormState> {
  final AccountRepository repository;
  final int? accountId; // Made nullable for create mode
  final bool isCreateMode;
  final List<AccountField>? templateFields; // Template fields for create mode

  AccountFormCubit({
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
    this.templateFields,
  }) : super(AccountFormInitial()) {
    if (!isCreateMode && accountId == null) {
      throw ArgumentError('accountId is required when not in create mode');
    }
  }

  // Load account and fields from database into form state
  Future<void> loadFields() async {
    try {
      emit(AccountFormLoading());
      if (isCreateMode) {
        // Create mode: start with empty account and template fields (if provided)
        final now = DateTime.now().millisecondsSinceEpoch;
        final newAccount = Account(name: '', createdAt: now, updatedAt: now);
        final fields = templateFields ?? [];
        emit(AccountFormLoaded(newAccount, fields));
      } else {
        // Edit mode: load existing account and fields
        final account = await repository.getAccounts().then(
          (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
        );
        final fields = await repository.getFields(accountId!);
        emit(AccountFormLoaded(account, fields));
      }
    } catch (e) {
      emit(AccountFormError('Failed to load account and fields'));
    }
  }

  // Update a field in memory only (doesn't persist to database)
  void updateField(AccountField updatedField) {
    if (state is AccountFormLoaded) {
      final currentState = state as AccountFormLoaded;
      final updatedFields = currentState.fields.map((field) {
        return field.id == updatedField.id ? updatedField : field;
      }).toList();
      emit(
        AccountFormLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Add a new field to the form
  void addField(AccountField newField) {
    if (state is AccountFormLoaded) {
      final currentState = state as AccountFormLoaded;
      final updatedFields = List<AccountField>.from(currentState.fields)
        ..add(newField);
      emit(
        AccountFormLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Update account in memory only (doesn't persist to database)
  void updateAccount(Account updatedAccount) {
    if (state is AccountFormLoaded) {
      final currentState = state as AccountFormLoaded;
      emit(
        AccountFormLoaded(
          updatedAccount,
          currentState.fields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Remove a field from the form
  void removeField(int fieldId) {
    if (state is AccountFormLoaded) {
      final currentState = state as AccountFormLoaded;
      final updatedFields = currentState.fields
          .where((field) => field.id != fieldId)
          .toList();
      emit(
        AccountFormLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Save all changes to database
  Future<void> saveChanges() async {
    if (state is AccountFormLoaded) {
      final currentState = state as AccountFormLoaded;
      try {
        emit(AccountFormSaving());

        // Save account to database
        int savedAccountId;
        if (isCreateMode) {
          // Create mode: insert new account
          final accountToInsert = currentState.account.copyWith(
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          savedAccountId = await repository.insertAccount(accountToInsert);
        } else {
          // Edit mode: update existing account
          await repository.updateAccount(
            currentState.account.copyWith(
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          savedAccountId = accountId!;
        }

        // Save all fields to database
        for (final field in currentState.fields) {
          if (field.id == null) {
            // New field - ensure it has the correct accountId
            final fieldToInsert = field.copyWith(accountId: savedAccountId);
            await repository.insertField(fieldToInsert);
          } else {
            // Existing field
            await repository.updateField(field);
          }
        }

        // Reload from database to get updated IDs and confirm save
        await loadFields();
        emit((state as AccountFormLoaded).copyWith(hasUnsavedChanges: false));

        // Publish event for other parts of the app to react
        final savedAccount = (state as AccountFormLoaded).account;
        if (isCreateMode) {
          AccountEventBus().publish(AccountCreated(savedAccount));
        } else {
          AccountEventBus().publish(AccountUpdated(savedAccount));
        }
      } catch (e) {
        emit(AccountFormError('Failed to save changes: $e'));
      }
    }
  }

  // Discard changes and reload from database
  Future<void> discardChanges() async {
    await loadFields();
  }
}
