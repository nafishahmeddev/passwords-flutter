import '../models/account.dart';
import '../models/account_field.dart';
import 'package:sqflite/sqflite.dart';

class AccountRepository {
  final Database _db;

  AccountRepository(this._db);

  // --- Account CRUD ---
  Future<int> insertAccount(Account account) async {
    return await _db.insert('Account', account.toMap());
  }

  Future<List<Account>> getAccounts() async {
    final List<Map<String, dynamic>> maps = await _db.query('Account');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> updateAccount(Account account) async {
    return await _db.update(
      'Account',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    return await _db.delete('Account', where: 'id = ?', whereArgs: [id]);
  }

  // --- AccountField CRUD ---
  Future<int> insertField(AccountField field) async {
    return await _db.insert('AccountField', field.toMap());
  }

  Future<List<AccountField>> getFields(int accountId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'AccountField',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'fieldOrder ASC',
    );
    return maps.map((map) => AccountField.fromMap(map)).toList();
  }

  Future<int> updateField(AccountField field) async {
    return await _db.update(
      'AccountField',
      field.toMap(),
      where: 'id = ?',
      whereArgs: [field.id],
    );
  }

  Future<int> deleteField(int id) async {
    return await _db.delete('AccountField', where: 'id = ?', whereArgs: [id]);
  }
}
