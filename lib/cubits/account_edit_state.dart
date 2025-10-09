part of 'account_edit_cubit.dart';

abstract class AccountEditState {}

class AccountEditInitial extends AccountEditState {}

class AccountEditLoading extends AccountEditState {}

class AccountEditLoaded extends AccountEditState {
  final Account account;
  final List<AccountField> fields;
  final bool hasUnsavedChanges;

  AccountEditLoaded(
    this.account,
    this.fields, {
    this.hasUnsavedChanges = false,
  });

  AccountEditLoaded copyWith({
    Account? account,
    List<AccountField>? fields,
    bool? hasUnsavedChanges,
  }) {
    return AccountEditLoaded(
      account ?? this.account,
      fields ?? this.fields,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class AccountEditSaving extends AccountEditState {}

class AccountEditError extends AccountEditState {
  final String message;
  AccountEditError(this.message);
}
