import '../models/account.dart';
import '../models/account_field.dart';
import 'package:sqflite/sqflite.dart';

class AccountRepository {
  final Database _db;

  AccountRepository(this._db);

  // --- Account CRUD ---
  Future<String> insertAccount(Account account) async {
    await _db.insert('Account', account.toMap());
    return account.id;
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

  Future<int> deleteAccount(String id) async {
    return await _db.delete('Account', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleFavorite(String id) async {
    // First get the current favorite status
    final List<Map<String, dynamic>> maps = await _db.query(
      'Account',
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      bool currentFavorite = maps.first['isFavorite'] == 1;
      return await _db.update(
        'Account',
        {'isFavorite': currentFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  // --- AccountField CRUD ---
  Future<String> insertField(AccountField field) async {
    await _db.insert('AccountField', field.toMap());
    return field.id;
  }

  Future<List<AccountField>> getFields(String accountId) async {
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

  Future<int> deleteField(String id) async {
    return await _db.delete('AccountField', where: 'id = ?', whereArgs: [id]);
  }
}
