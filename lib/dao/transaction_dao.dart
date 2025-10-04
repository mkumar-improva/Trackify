import 'package:intl/intl.dart';
import 'package:trackify/services/database_service.dart';
import 'package:trackify/types/monthly_summary.dart';
import 'package:trackify/types/transaction.dart';

class TransactionDao {
  static const table = 'transactions';

  Future<void> insertMany(List<Transaction> items) async {
    if (items.isEmpty) return;
    final db = await AppDatabase.instance.database;

    // Use a batch for speed; ignore conflicts via UNIQUE constraint.
    final batch = db.batch();
    for (final t in items) {
      batch.insert(
        table,
        _toRow(t),
      );
    }
    await batch.commit(noResult: true);
  }

  // Fetch all transactions in a given yyyy-MM month key (local time grouping).
  Future<List<Transaction>> fetchByMonthKey(String yyyyMm) async {
    final db = await AppDatabase.instance.database;

    // Compute first/last day bounds in Dart for stable filtering on millis.
    final year = int.parse(yyyyMm.split('-')[0]);
    final month = int.parse(yyyyMm.split('-')[1]);

    final start = DateTime(year, month, 1);
    final end = DateTime(month == 12 ? year + 1 : year, month == 12 ? 1 : month + 1, 1);

    final rows = await db.query(
      table,
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );

    return rows.map(_fromRow).toList();
  }

  // Return a map of yyyy-MM -> MonthlySummary with transactions loaded
  Future<Map<String, MonthlySummary>> fetchMonthlySummaries() async {
    final db = await AppDatabase.instance.database;

    // Grab month buckets via SQL (fast), then load txns per month.
    final monthRows = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', datetime(date/1000,'unixepoch','localtime')) AS month_key,
        SUM(CASE WHEN type='DEBIT' THEN IFNULL(amount,0) ELSE 0 END) AS total_debit,
        SUM(CASE WHEN type='CREDIT' THEN IFNULL(amount,0) ELSE 0 END) AS total_credit,
        COUNT(*) AS count_tx
      FROM $table
      GROUP BY month_key
      ORDER BY month_key DESC;
    ''');

    final Map<String, MonthlySummary> out = {};
    for (final r in monthRows) {
      final monthKey = (r['month_key'] as String?) ?? _monthKey(DateTime.now());
      final txns = await fetchByMonthKey(monthKey);
      out[monthKey] = MonthlySummary(month: monthKey, transactions: txns);
    }
    return out;
  }

  // Generic fetch for UI lists (optional).
  Future<List<Transaction>> fetchAll({int limit = 200, int offset = 0}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      table,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  // Helpers

  Map<String, dynamic> _toRow(Transaction t) => {
    'sms_id': null, // fill if you have SmsMessage.id
    'sender': t.sender,
    'body': t.body,
    'type': t.type,
    'amount': t.amount,
    'account': t.account,
    'date': t.date.millisecondsSinceEpoch,
  };

  Transaction _fromRow(Map<String, dynamic> row) => Transaction(
    sender: row['sender'] as String? ?? '',
    body: row['body'] as String? ?? '',
    type: row['type'] as String? ?? 'DEBIT',
    amount: (row['amount'] as num?)?.toDouble(),
    account: row['account'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
  );

  String _monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
}
