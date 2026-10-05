import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/transaction_repository.dart';
import '../models/transaction.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = TransactionRepository();

  final _amountController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Ventes');
  final _activityController = TextEditingController(text: 'Menuiserie');
  final _clientController = TextEditingController();
  final _projectController = TextEditingController();
  final _motifController = TextEditingController();
  final _observationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.income;
  String _paymentMethod = 'Espèces';

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _activityController.dispose();
    _clientController.dispose();
    _projectController.dispose();
    _motifController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle opération'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.income, label: Text('Recette')),
                  ButtonSegment(value: TransactionType.expense, label: Text('Dépense')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                    if (_selectedType == TransactionType.income) {
                      _categoryController.text = _categoryController.text.isEmpty ? 'Ventes' : _categoryController.text;
                    } else {
                      _categoryController.text = _categoryController.text.isEmpty ? 'Fournitures' : _categoryController.text;
                    }
                  });
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  prefixText: '',
                  suffixText: '€',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Saisissez un montant';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(
                  labelText: 'Activité',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _projectController,
                decoration: const InputDecoration(
                  labelText: 'Chantier',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'Virement', child: Text('Virement')),
                  DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                  DropdownMenuItem(value: 'Carte', child: Text('Carte')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motifController,
                decoration: const InputDecoration(
                  labelText: 'Motif',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final transaction = TransactionModel(
      date: _selectedDate,
      type: _selectedType,
      amount: amount,
      category: _categoryController.text.trim().isEmpty ? 'Général' : _categoryController.text.trim(),
      activity: _activityController.text.trim().isEmpty ? 'Général' : _activityController.text.trim(),
      client: _clientController.text.trim().isEmpty ? null : _clientController.text.trim(),
      project: _projectController.text.trim().isEmpty ? null : _projectController.text.trim(),
      paymentMethod: _paymentMethod,
      motif: _motifController.text.trim().isEmpty ? null : _motifController.text.trim(),
      observation: _observationController.text.trim().isEmpty ? null : _observationController.text.trim(),
    );

    await _repository.insertTransaction(transaction);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
