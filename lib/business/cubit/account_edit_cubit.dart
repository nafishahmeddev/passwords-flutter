import 'package:bloc/bloc.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

part 'account_edit_state.dart';

class AccountEditCubit extends Cubit<AccountEditState> {
  final AccountRepository repository;
  final int? accountId; // Made nullable for create mode
  final bool isCreateMode;

  AccountEditCubit({
    required this.repository,
    this.accountId,
    this.isCreateMode = false,
  }) : super(AccountEditInitial()) {
    if (!isCreateMode && accountId == null) {
      throw ArgumentError('accountId is required when not in create mode');
    }
  }

  // Load account and fields from database into form state
  Future<void> loadFields() async {
    try {
      emit(AccountEditLoading());
      if (isCreateMode) {
        // Create mode: start with empty account and no fields
        final now = DateTime.now().millisecondsSinceEpoch;
        final newAccount = Account(name: '', createdAt: now, updatedAt: now);
        emit(AccountEditLoaded(newAccount, []));
      } else {
        // Edit mode: load existing account and fields
        final account = await repository.getAccounts().then(
          (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
        );
        final fields = await repository.getFields(accountId!);
        emit(AccountEditLoaded(account, fields));
      }
    } catch (e) {
      emit(AccountEditError('Failed to load account and fields'));
    }
  }

  // Update a field in memory only (doesn't persist to database)
  void updateField(AccountField updatedField) {
    if (state is AccountEditLoaded) {
      final currentState = state as AccountEditLoaded;
      final updatedFields = currentState.fields.map((field) {
        return field.id == updatedField.id ? updatedField : field;
      }).toList();
      emit(
        AccountEditLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Add a new field to the form
  void addField(AccountField newField) {
    if (state is AccountEditLoaded) {
      final currentState = state as AccountEditLoaded;
      final updatedFields = List<AccountField>.from(currentState.fields)
        ..add(newField);
      emit(
        AccountEditLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Update account in memory only (doesn't persist to database)
  void updateAccount(Account updatedAccount) {
    if (state is AccountEditLoaded) {
      final currentState = state as AccountEditLoaded;
      emit(
        AccountEditLoaded(
          updatedAccount,
          currentState.fields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Remove a field from the form
  void removeField(int fieldId) {
    if (state is AccountEditLoaded) {
      final currentState = state as AccountEditLoaded;
      final updatedFields = currentState.fields
          .where((field) => field.id != fieldId)
          .toList();
      emit(
        AccountEditLoaded(
          currentState.account,
          updatedFields,
          hasUnsavedChanges: true,
        ),
      );
    }
  }

  // Save all changes to database
  Future<void> saveChanges() async {
    if (state is AccountEditLoaded) {
      final currentState = state as AccountEditLoaded;
      try {
        emit(AccountEditSaving());

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
        emit((state as AccountEditLoaded).copyWith(hasUnsavedChanges: false));

        // Publish event for other parts of the app to react
        final savedAccount = (state as AccountEditLoaded).account;
        if (isCreateMode) {
          AccountEventBus().publish(AccountCreated(savedAccount));
        } else {
          AccountEventBus().publish(AccountUpdated(savedAccount));
        }
      } catch (e) {
        emit(AccountEditError('Failed to save changes: $e'));
      }
    }
  }

  // Discard changes and reload from database
  Future<void> discardChanges() async {
    await loadFields();
  }
}
