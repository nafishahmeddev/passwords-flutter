import 'package:bloc/bloc.dart';
import '../../data/models/account.dart';
import '../../data/models/account_field.dart';
import '../../data/repositories/account_repository.dart';

part 'account_detail_state.dart';

class AccountDetailCubit extends Cubit<AccountDetailState> {
  final AccountRepository repository;
  final int accountId;

  AccountDetailCubit({required this.repository, required this.accountId})
    : super(AccountDetailInitial());

  Future<void> loadFields() async {
    try {
      emit(AccountDetailLoading());
      final account = await repository.getAccounts().then(
        (accounts) => accounts.firstWhere((acc) => acc.id == accountId),
      );
      final fields = await repository.getFields(accountId);
      emit(AccountDetailLoaded(account, fields));
    } catch (e) {
      emit(AccountDetailError('Failed to load account and fields'));
    }
  }

  Future<void> addField(AccountField field) async {
    try {
      await repository.insertField(field);
      await loadFields();
    } catch (e) {
      emit(AccountDetailError('Failed to add field'));
    }
  }

  Future<void> deleteField(int id) async {
    try {
      await repository.deleteField(id);
      await loadFields();
    } catch (e) {
      emit(AccountDetailError('Failed to delete field'));
    }
  }

  // Update account
  Future<void> updateAccount(Account account) async {
    try {
      await repository.updateAccount(account);
      await loadFields(); // This will reload both account and fields
    } catch (e) {
      emit(AccountDetailError('Failed to update account'));
    }
  }
}
