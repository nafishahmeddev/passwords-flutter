import '../../data/models/account.dart';

abstract class AccountEvent {}

class AccountCreated extends AccountEvent {
  final Account account;
  AccountCreated(this.account);
}

class AccountUpdated extends AccountEvent {
  final Account account;
  AccountUpdated(this.account);
}

class AccountDeleted extends AccountEvent {
  final String accountId;
  AccountDeleted(this.accountId);
}