import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/transaction_repository.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  ReportPeriod _selectedPeriod = ReportPeriod.month;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final range = _resolveRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ReportPeriod>(
              segments: const <ButtonSegment<ReportPeriod>>[
                ButtonSegment(value: ReportPeriod.day, label: Text('Jour')),
                ButtonSegment(value: ReportPeriod.week, label: Text('Semaine')),
                ButtonSegment(value: ReportPeriod.month, label: Text('Mois')),
                ButtonSegment(value: ReportPeriod.year, label: Text('Année')),
                ButtonSegment(value: ReportPeriod.custom, label: Text('Perso.')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<ReportPeriod> selection) {
                setState(() {
                  _selectedPeriod = selection.first;
                  if (_selectedPeriod != ReportPeriod.custom) {
                    _customRange = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedPeriod == ReportPeriod.custom)
              _CustomRangeBar(
                range: _customRange,
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDateRange: _customRange ??
                        DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                  );

                  if (picked != null) {
                    setState(() {
                      _customRange = picked;
                    });
                  }
                },
              ),
            const SizedBox(height: 16),
            FutureBuilder<DashboardSummary>(
              future: _repository.getPeriodSummary(
                start: range.start,
                end: range.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final summary = snapshot.data ??
                    const DashboardSummary(
                      totalIncome: 0,
                      totalExpense: 0,
                      balance: 0,
                      dayBalance: 0,
                      monthBalance: 0,
                    );

                return GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _SummaryMetricCard(
                      title: 'Recettes',
                      value: _formatCurrency(summary.totalIncome),
                      color: Colors.green,
                    ),
                    _SummaryMetricCard(
                      title: 'Dépenses',
                      value: _formatCurrency(summary.totalExpense),
                      color: Colors.red,
                    ),
                    _SummaryMetricCard(
                      title: 'Solde',
                      value: _formatCurrency(summary.balance),
                      color: summary.balance >= 0 ? Colors.blue : Colors.orange,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Période: ${_formatRange(range)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TransactionModel>>(
              future: _repository.getTransactions(
                start: range.start,
                end: range.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final items = snapshot.data ?? const <TransactionModel>[];
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucune transaction dans cette période.'),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isIncome = item.type == TransactionType.income;
                      final color = isIncome ? Colors.green : Colors.red;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(25),
                          child: Icon(
                            isIncome ? Icons.trending_up : Icons.trending_down,
                            color: color,
                          ),
                        ),
                        title: Text('${item.category} • ${item.activity}'),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(item.date)} • ${item.paymentMethod}',
                        ),
                        trailing: Text(
                          item.formattedAmount,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTimeRange _resolveRange() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case ReportPeriod.day:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final normalizedStart = DateTime(start.year, start.month, start.day);
        final end = normalizedStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        return DateTimeRange(start: normalizedStart, end: end);
      case ReportPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.custom:
        return _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            );
    }
  }

  String _formatRange(DateTimeRange range) {
    final start = DateFormat('dd/MM/yyyy').format(range.start);
    final end = DateFormat('dd/MM/yyyy').format(range.end);
    return '$start - $end';
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 2);
    return '${formatter.format(value)} €';
  }
}

enum ReportPeriod { day, week, month, year, custom }

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomRangeBar extends StatelessWidget {
  const _CustomRangeBar({
    required this.range,
    required this.onTap,
  });

  final DateTimeRange? range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = range == null ? 'Choisir' : DateFormat('dd/MM/yyyy').format(range!.start);
    final end = range == null ? 'une période' : DateFormat('dd/MM/yyyy').format(range!.end);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range),
            const SizedBox(width: 12),
            Text('Période personnalisée: $start - $end'),
          ],
        ),
      ),
    );
  }
}
