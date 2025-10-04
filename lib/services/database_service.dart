import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'trackify.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Core table
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sms_id INTEGER,
            sender TEXT,
            body TEXT,
            type TEXT CHECK(type IN ('DEBIT','CREDIT')),
            amount REAL,
            account TEXT,
            date INTEGER NOT NULL, -- millis since epoch (UTC)
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000),
            -- Prevent duplicates from the same SMS by (sender, body, date).
            UNIQUE(sender, body, date)
          );
        ''');

        await db.execute('CREATE INDEX idx_tx_date ON transactions(date);');
        await db.execute('CREATE INDEX idx_tx_type ON transactions(type);');
        await db.execute('CREATE INDEX idx_tx_account ON transactions(account);');
      },
      onUpgrade: (db, oldV, newV) async {
        // Put future migrations here (switch on oldV).
      },
    );
  }
}
