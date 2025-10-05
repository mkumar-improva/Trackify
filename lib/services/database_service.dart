import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'trackify.db';
  static const _dbVersion = 3;

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
        // -------- transactions (existing) --------
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sms_id INTEGER,
            sender TEXT,
            body TEXT,
            type TEXT CHECK(type IN ('DEBIT','CREDIT')),
            amount REAL,
            account TEXT,
            date INTEGER NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000),
            UNIQUE(sender, body, date)
          );
        ''');

        await db.execute('CREATE INDEX idx_tx_date ON transactions(date);');
        await db.execute('CREATE INDEX idx_tx_type ON transactions(type);');
        await db.execute('CREATE INDEX idx_tx_account ON transactions(account);');

        // -------- payment_methods (new) --------
        await _createPaymentMethods(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // v1 -> v2: add payment_methods
        if (oldV < 2) {
          await _createPaymentMethods(db);
        }

        // v2 -> v3: add senders column
        if (oldV < 3) {
          await db.execute('ALTER TABLE payment_methods ADD COLUMN senders TEXT;');
        }
      },
    );
  }

  Future<void> _createPaymentMethods(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('card','bank')),
        label TEXT NOT NULL,
        brand TEXT,
        last4 TEXT,
        expiry_month INTEGER,
        expiry_year INTEGER,
        holder TEXT,
        bank_name TEXT,
        account_mask TEXT,
        ifsc TEXT,
        upi_id TEXT,
        senders TEXT, -- 🆕 new column
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000),
        variant INTEGER DEFAULT 0,
        card_type TEXT,
        card_network TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pm_type ON payment_methods(type);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pm_label ON payment_methods(label);',
    );
  }
}
