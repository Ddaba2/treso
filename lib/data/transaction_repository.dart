import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart';
import 'app_database.dart';

class TransactionRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<int> insertCatalogEntry(String table, {required String name, String? type}) async {
    final db = await _database.database;
    final payload = {'name': name.trim(), 'created_at': DateTime.now().toIso8601String()};
    if (type != null) {
      payload['type'] = type;
    }
    return db.insert(table, payload, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> listCatalog(String table, {String? type}) async {
    final db = await _database.database;
    if (type == null) {
      final rows = await db.query(table, orderBy: 'name ASC');
      return rows;
    }
    final rows = await db.query(
      table,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
    return rows;
  }

  Future<void> deleteCatalogEntry(String table, int id) async {
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _database.database;
    return db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions({
    TransactionType? type,
    DateTime? start,
    DateTime? end,
    String? search,
  }) async {
    final db = await _database.database;

    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += ' type = ?';
      whereArgs.add(type.storageValue);
    }

    if (start != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND';
      }
      whereClause += ' date >= ?';
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND';
      }
      whereClause += ' date <= ?';
      whereArgs.add(end.toIso8601String());
    }

    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim()}%';
      if (whereClause.isNotEmpty) {
        whereClause += ' AND';
      }
      whereClause += ' (category LIKE ? OR activity LIKE ? OR client LIKE ? OR project LIKE ? OR motif LIKE ? OR observation LIKE ?)';
      whereArgs.addAll([value, value, value, value, value, value]);
    }

    final rows = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereClause.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, id DESC',
    );

    final transactions = rows.map(TransactionModel.fromMap).toList();
    return transactions;
  }

  Future<DashboardSummary> getDashboardSummary({DateTime? start, DateTime? end}) async {
    final transactions = await getTransactions(start: start, end: end);

    double totalIncome = 0;
    double totalExpense = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0, 23, 59, 59, 999);

    final dayTransactions = await getTransactions(start: dayStart, end: dayEnd);
    final monthTransactions = await getTransactions(start: monthStart, end: monthEnd);

    double dayBalance = 0;
    for (final item in dayTransactions) {
      if (item.type == TransactionType.income) {
        dayBalance += item.amount;
      } else {
        dayBalance -= item.amount;
      }
    }

    double monthBalance = 0;
    for (final item in monthTransactions) {
      if (item.type == TransactionType.income) {
        monthBalance += item.amount;
      } else {
        monthBalance -= item.amount;
      }
    }

    return DashboardSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      dayBalance: dayBalance,
      monthBalance: monthBalance,
    );
  }

  Future<List<ActivitySummary>> getActivityBreakdown({DateTime? start, DateTime? end}) async {
    final db = await _database.database;
    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (start != null) {
      whereClause += ' date >= ?';
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND';
      }
      whereClause += ' date <= ?';
      whereArgs.add(end.toIso8601String());
    }

    final rows = await db.rawQuery(
      '''
        SELECT activity, SUM(amount) as total
        FROM transactions
        ${whereClause.isEmpty ? '' : 'WHERE $whereClause'}
        GROUP BY activity
        ORDER BY total DESC
      ''',
      whereArgs,
    );

    return rows.map((row) {
      final activity = row['activity'] as String? ?? 'Général';
      final amount = (row['total'] as num?)?.toDouble() ?? 0;
      return ActivitySummary(activity: activity, amount: amount);
    }).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _database.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
