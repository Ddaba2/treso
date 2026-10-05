import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/transaction_repository.dart';
import '../models/transaction.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  String? _search;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().isEmpty ? null : value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: _repository.getTransactions(search: _search),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? const <TransactionModel>[];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Aucune transaction enregistrée.'),
                  );
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isIncome = transaction.type == TransactionType.income;
                    final color = isIncome ? Colors.green : Colors.red;

                    return Dismissible(
                      key: ValueKey(transaction.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        if (transaction.id != null) {
                          await _repository.deleteTransaction(transaction.id!);
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(25),
                          child: Icon(
                            isIncome ? Icons.trending_up : Icons.trending_down,
                            color: color,
                          ),
                        ),
                        title: Text(
                          '${transaction.type.label} • ${transaction.category}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(transaction.date)} • ${transaction.activity}${transaction.client != null ? ' • ${transaction.client}' : ''}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              transaction.formattedAmount,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              transaction.paymentMethod,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
          if (mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
