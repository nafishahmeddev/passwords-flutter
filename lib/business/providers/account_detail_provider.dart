import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_event_bus.dart';

enum AccountDetailState { initial, loading, loaded, error }

class AccountDetailProvider extends ChangeNotifier {
  final AccountRepository repository;
  final String accountId;
  StreamSubscription? _eventSubscription;

  AccountDetailState _state = AccountDetailState.initial;
  Account? _account;
  List<AccountField> _fields = [];
  String? _errorMessage;

  AccountDetailProvider({required this.repository, required this.accountId}) {
    // Listen to account events and refresh if this account is affected
    _eventSubscription = AccountEventBus().events.listen((event) {
      if (event is AccountUpdated && event.account.id == accountId) {
        loadFields(); // Refresh this account's details
      }
    });
  }

  // Getters
  AccountDetailState get state => _state;
  Account? get account => _account;
  List<AccountField> get fields => _fields;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AccountDetailState.loading;
  bool get hasError => _state == AccountDetailState.error;

  // Toggle favorite status
  Future<void> toggleFavorite(String accountId) async {
    if (_account == null) return;

    try {
      final updatedAccount = _account!.copyWith(
        isFavorite: !(_account!.isFavorite),
      );

      await updateAccount(updatedAccount);
      // Account will be reloaded by updateAccount
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to update favorite status';
      notifyListeners();
    }
  }

  Future<void> loadFields() async {
    try {
      _state = AccountDetailState.loading;
      _errorMessage = null;
      notifyListeners();

      final account = await repository.getAccounts().then(
        (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
      );
      final fields = await repository.getFields(accountId);

      _account = account;
      _fields = fields;
      _state = AccountDetailState.loaded;
      notifyListeners();
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to load account and fields';
      notifyListeners();
    }
  }

  Future<void> addField(AccountField field) async {
    try {
      _state = AccountDetailState.loading;
      notifyListeners();

      await repository.insertField(field);
      await loadFields();
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to add field';
      notifyListeners();
    }
  }

  Future<void> updateField(AccountField field) async {
    try {
      await repository.updateField(field);
      // Update the field in memory
      final index = _fields.indexWhere((f) => f.id == field.id);
      if (index != -1) {
        _fields[index] = field;
        notifyListeners();
      }
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to update field';
      notifyListeners();
    }
  }

  Future<void> deleteField(String id) async {
    try {
      _state = AccountDetailState.loading;
      notifyListeners();

      await repository.deleteField(id);
      await loadFields();
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to delete field';
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      _state = AccountDetailState.loading;
      notifyListeners();

      await repository.deleteAccount(id);
      _state = AccountDetailState.loaded;
      notifyListeners();
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to delete account';
      notifyListeners();
    }
  }

  // Update account
  Future<void> updateAccount(Account account) async {
    try {
      _state = AccountDetailState.loading;
      notifyListeners();

      await repository.updateAccount(account);
      await loadFields(); // This will reload both account and fields
    } catch (e) {
      _state = AccountDetailState.error;
      _errorMessage = 'Failed to update account';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
