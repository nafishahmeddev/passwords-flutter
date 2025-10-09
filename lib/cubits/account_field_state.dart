part of 'account_field_cubit.dart';

abstract class AccountFieldState {}

class AccountFieldInitial extends AccountFieldState {}

class AccountFieldLoading extends AccountFieldState {}

class AccountFieldLoaded extends AccountFieldState {
  final List<AccountField> fields;
  AccountFieldLoaded(this.fields);
}

class AccountFieldError extends AccountFieldState {
  final String message;
  AccountFieldError(this.message);
}
