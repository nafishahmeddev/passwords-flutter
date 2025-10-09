// lib/database/db_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> init() async {
    if (_db != null) return _db!;

    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'passwords.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Account(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            note TEXT,
            logoUrl TEXT,
            logoFile TEXT,
            logoIcon TEXT,
            createdAt INTEGER,
            updatedAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE AccountField(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            accountId INTEGER,
            label TEXT,
            type TEXT,
            required INTEGER,
            fieldOrder INTEGER,
            metadata TEXT,
            FOREIGN KEY(accountId) REFERENCES Account(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
    return _db!;
  }
}
