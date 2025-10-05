import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'trackify.db';
  // ⬇️ Bump to 2 to add payment_methods table
  static const _dbVersion = 2;

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
        await db.execute(
          'CREATE INDEX idx_tx_account ON transactions(account);',
        );

        // -------- payment_methods (new) --------
        await _createPaymentMethods(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // v1 -> v2: add payment_methods
        if (oldV < 2) {
          await _createPaymentMethods(db);
        }
        // Put future migrations behind version checks.
      },
    );
  }

  Future<void> _createPaymentMethods(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id TEXT PRIMARY KEY,                     -- keep your existing string id
        type TEXT NOT NULL CHECK(type IN ('card','bank')),
        label TEXT NOT NULL,                     -- display name (e.g., "HDFC **** 1234")
        brand TEXT,                              -- Visa/Master/HDFC/etc (optional)
        last4 TEXT,                              -- last 4 digits (optional)
        expiry_month INTEGER,                    -- nullable for bank accounts
        expiry_year INTEGER,
        holder TEXT,                             -- card holder or account holder
        bank_name TEXT,                          -- for bank accounts (optional)
        account_mask TEXT,                       -- masked acct (e.g., XX1234)
        ifsc TEXT,                               -- optional
        upi_id TEXT,                             -- optional, if you store UPI
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000), -- epoch ms
        variant INTEGER DEFAULT 0,               -- future use (e.g., virtual cards)
        card_type TEXT,                           -- future use (e.g., credit/debit),
        card_network TEXT                        -- future use (e.g., Visa/Master/RuPay/etc)        
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
