import 'package:bloc/bloc.dart';
import '../models/account.dart';
import '../models/account_field.dart';
import '../repositories/account_repository.dart';

part 'account_edit_state.dart';

class AccountEditCubit extends Cubit<AccountEditState> {
  final AccountRepository repository;
  final int accountId;

  AccountEditCubit({required this.repository, required this.accountId})
    : super(AccountEditInitial());

  // Load account and fields from database into form state
  Future<void> loadFields() async {
    try {
      emit(AccountEditLoading());
      final account = await repository.getAccounts().then(
        (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
      );
      final fields = await repository.getFields(accountId);
      emit(AccountEditLoaded(account, fields));
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
        await repository.updateAccount(currentState.account);

        // Save all fields to database
        for (final field in currentState.fields) {
          if (field.id == null) {
            // New field
            await repository.insertField(field);
          } else {
            // Existing field
            await repository.updateField(field);
          }
        }

        // Reload from database to get updated IDs and confirm save
        await loadFields();
        emit((state as AccountEditLoaded).copyWith(hasUnsavedChanges: false));
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
