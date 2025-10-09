import 'package:bloc/bloc.dart';
import '../models/account.dart';
import '../repositories/account_repository.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AccountRepository repository;

  AccountCubit({required this.repository}) : super(AccountInitial());

  // Load all accounts
  Future<void> loadAccounts() async {
    try {
      emit(AccountLoading());
      final accounts = await repository.getAccounts();
      emit(AccountLoaded(accounts));
    } catch (e) {
      emit(AccountError('Failed to load accounts'));
    }
  }

  // Add new account
  Future<void> addAccount(Account account) async {
    try {
      await repository.insertAccount(account);
      await loadAccounts(); // refresh
    } catch (e) {
      emit(AccountError('Failed to add account'));
    }
  }

  // Update account
  Future<void> updateAccount(Account account) async {
    try {
      await repository.updateAccount(account);
      await loadAccounts(); // refresh
    } catch (e) {
      emit(AccountError('Failed to update account'));
    }
  }

  // Delete account
  Future<void> deleteAccount(int id) async {
    try {
      await repository.deleteAccount(id);
      await loadAccounts(); // refresh
    } catch (e) {
      emit(AccountError('Failed to delete account'));
    }
  }
}
