part of 'account_form_cubit.dart';

abstract class AccountFormState {}

class AccountFormInitial extends AccountFormState {}

class AccountFormLoading extends AccountFormState {}

class AccountFormLoaded extends AccountFormState {
  final Account account;
  final List<AccountField> fields;
  final bool hasUnsavedChanges;

  AccountFormLoaded(
    this.account,
    this.fields, {
    this.hasUnsavedChanges = false,
  });

  AccountFormLoaded copyWith({
    Account? account,
    List<AccountField>? fields,
    bool? hasUnsavedChanges,
  }) {
    return AccountFormLoaded(
      account ?? this.account,
      fields ?? this.fields,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class AccountFormSaving extends AccountFormState {}

class AccountFormError extends AccountFormState {
  final String message;
  AccountFormError(this.message);
}
