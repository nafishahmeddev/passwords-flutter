// lib/database/db_helper.dart
import 'dart:io';
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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Account(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            note TEXT,
            logoType TEXT,
            logo TEXT,
            isFavorite INTEGER DEFAULT 0,
            createdAt INTEGER,
            updatedAt INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE AccountField(
            id TEXT PRIMARY KEY,
            accountId TEXT,
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
