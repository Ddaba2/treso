import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/transaction_repository.dart';
import '../models/transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionRepository _repository = TransactionRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _repository.getDashboardSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
        }

        final summary = snapshot.data ??
            const DashboardSummary(
              totalIncome: 0,
              totalExpense: 0,
              balance: 0,
              dayBalance: 0,
              monthBalance: 0,
            );

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tableau de bord',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    label: 'Total recettes',
                    value: _formatCurrency(summary.totalIncome),
                    color: Colors.green,
                  ),
                  _MetricCard(
                    label: 'Total dépenses',
                    value: _formatCurrency(summary.totalExpense),
                    color: Colors.red,
                  ),
                  _MetricCard(
                    label: 'Solde',
                    value: _formatCurrency(summary.balance),
                    color: summary.balance >= 0 ? Colors.blue : Colors.orange,
                  ),
                  _MetricCard(
                    label: 'Situation du jour',
                    value: _formatCurrency(summary.dayBalance),
                    color: summary.dayBalance >= 0 ? Colors.teal : Colors.deepOrange,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SummaryTile(
                label: 'Situation du mois',
                value: _formatCurrency(summary.monthBalance),
                icon: Icons.calendar_month,
              ),
              const SizedBox(height: 20),
              _ActivityBreakdownCard(repository: _repository),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2);
    return '${formatter.format(value)} €';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBreakdownCard extends StatelessWidget {
  const _ActivityBreakdownCard({required this.repository});

  final TransactionRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActivitySummary>>(
      future: repository.getActivityBreakdown(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }

        final items = snapshot.data ?? const <ActivitySummary>[];

        if (items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune donnée pour le moment.'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Répartition par activité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.activity),
                        ),
                        Text(
                          '${NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2).format(item.amount)} €',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
