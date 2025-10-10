import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

enum AccountState { initial, loading, loaded, error }

class AccountProvider extends ChangeNotifier {
  final AccountRepository repository;
  StreamSubscription? _eventSubscription;

  AccountState _state = AccountState.initial;
  List<Account> _accounts = [];
  String? _errorMessage;

  AccountProvider({required this.repository}) {
    // Listen to account events and refresh automatically
    _eventSubscription = AccountEventBus().events.listen((event) {
      if (event is AccountCreated ||
          event is AccountUpdated ||
          event is AccountDeleted) {
        loadAccounts(); // Automatically refresh when accounts change
      }
    });
  }

  // Getters
  AccountState get state => _state;
  List<Account> get accounts => _accounts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AccountState.loading;
  bool get hasError => _state == AccountState.error;

  // Load all accounts
  Future<void> loadAccounts() async {
    try {
      _state = AccountState.loading;
      _errorMessage = null;
      notifyListeners();

      final accounts = await repository.getAccounts();
      _accounts = accounts;
      _state = AccountState.loaded;
      notifyListeners();
    } catch (e) {
      _state = AccountState.error;
      _errorMessage = 'Failed to load accounts';
      notifyListeners();
    }
  }

  // Add new account
  Future<void> addAccount(Account account) async {
    try {
      _state = AccountState.loading;
      notifyListeners();

      await repository.insertAccount(account);
      await loadAccounts(); // refresh
    } catch (e) {
      _state = AccountState.error;
      _errorMessage = 'Failed to add account';
      notifyListeners();
    }
  }

  // Update account
  Future<void> updateAccount(Account account) async {
    try {
      _state = AccountState.loading;
      notifyListeners();

      await repository.updateAccount(account);
      await loadAccounts(); // refresh
    } catch (e) {
      _state = AccountState.error;
      _errorMessage = 'Failed to update account';
      notifyListeners();
    }
  }

  // Delete account
  Future<void> deleteAccount(String id) async {
    try {
      _state = AccountState.loading;
      notifyListeners();

      await repository.deleteAccount(id);
      AccountEventBus().publish(AccountDeleted(id));
      await loadAccounts(); // refresh
    } catch (e) {
      _state = AccountState.error;
      _errorMessage = 'Failed to delete account';
      notifyListeners();
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String id) async {
    try {
      _state = AccountState.loading;
      notifyListeners();

      await repository.toggleFavorite(id);
      await loadAccounts(); // refresh
    } catch (e) {
      _state = AccountState.error;
      _errorMessage = 'Failed to toggle favorite';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}