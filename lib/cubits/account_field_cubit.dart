import 'package:bloc/bloc.dart';
import '../models/account_field.dart';
import '../repositories/account_repository.dart';

part 'account_field_state.dart';

class AccountFieldCubit extends Cubit<AccountFieldState> {
  final AccountRepository repository;
  final int accountId;

  AccountFieldCubit({required this.repository, required this.accountId})
    : super(AccountFieldInitial());

  Future<void> loadFields() async {
    try {
      emit(AccountFieldLoading());
      final fields = await repository.getFields(accountId);
      emit(AccountFieldLoaded(fields));
    } catch (e) {
      emit(AccountFieldError('Failed to load fields'));
    }
  }

  Future<void> addField(AccountField field) async {
    try {
      await repository.insertField(field);
      await loadFields();
    } catch (e) {
      emit(AccountFieldError('Failed to add field'));
    }
  }

  Future<void> deleteField(int id) async {
    try {
      await repository.deleteField(id);
      await loadFields();
    } catch (e) {
      emit(AccountFieldError('Failed to delete field'));
    }
  }
}
