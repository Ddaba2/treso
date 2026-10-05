import 'package:intl/intl.dart';

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Recette';
      case TransactionType.expense:
        return 'Dépense';
    }
  }

  String get storageValue {
    switch (this) {
      case TransactionType.income:
        return 'RECETTE';
      case TransactionType.expense:
        return 'DEPENSE';
    }
  }

  static TransactionType fromStorageValue(String value) {
    switch (value) {
      case 'RECETTE':
        return TransactionType.income;
      case 'DEPENSE':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}

class TransactionModel {
  TransactionModel({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    this.activity = 'Général',
    this.client,
    this.project,
    this.paymentMethod = 'Espèces',
    this.motif,
    this.observation,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String category;
  final String activity;
  final String? client;
  final String? project;
  final String paymentMethod;
  final String? motif;
  final String? observation;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get formattedAmount {
    final sign = type == TransactionType.income ? '+' : '-';
    final value = NumberFormat.currency(locale: 'fr_FR', symbol: '').format(amount);
    return '$sign $value €';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'type': type.storageValue,
      'amount': amount,
      'category': category,
      'activity': activity,
      'client': client,
      'project': project,
      'payment_method': paymentMethod,
      'motif': motif,
      'observation': observation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      type: TransactionTypeX.fromStorageValue(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String? ?? 'Général',
      activity: map['activity'] as String? ?? 'Général',
      client: map['client'] as String?,
      project: map['project'] as String?,
      paymentMethod: map['payment_method'] as String? ?? 'Espèces',
      motif: map['motif'] as String?,
      observation: map['observation'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.dayBalance,
    required this.monthBalance,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double dayBalance;
  final double monthBalance;
}

class ActivitySummary {
  const ActivitySummary({
    required this.activity,
    required this.amount,
  });

  final String activity;
  final double amount;
}
