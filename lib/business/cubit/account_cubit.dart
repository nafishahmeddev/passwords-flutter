import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

part 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AccountRepository repository;
  StreamSubscription? _eventSubscription;

  AccountCubit({required this.repository}) : super(AccountInitial()) {
    // Listen to account events and refresh automatically
    _eventSubscription = AccountEventBus().events.listen((event) {
      if (event is AccountCreated ||
          event is AccountUpdated ||
          event is AccountDeleted) {
        loadAccounts(); // Automatically refresh when accounts change
      }
    });
  }

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
      AccountEventBus().publish(AccountDeleted(id));
      await loadAccounts(); // refresh
    } catch (e) {
      emit(AccountError('Failed to delete account'));
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(int id) async {
    try {
      await repository.toggleFavorite(id);
      await loadAccounts(); // refresh
    } catch (e) {
      emit(AccountError('Failed to toggle favorite'));
    }
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
