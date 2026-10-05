import 'package:flutter/material.dart';

import '../data/transaction_repository.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TransactionRepository _repository = TransactionRepository();
  final Map<String, TextEditingController> _controllers = {
    'activities': TextEditingController(),
    'clients': TextEditingController(),
    'projects': TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Référentiels'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activités'),
              Tab(text: 'Clients'),
              Tab(text: 'Chantiers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CatalogTab(
              table: 'activities',
              controller: _controllers['activities']!,
              label: 'Ajouter une activité',
              repository: _repository,
            ),
            _CatalogTab(
              table: 'clients',
              controller: _controllers['clients']!,
              label: 'Ajouter un client',
              repository: _repository,
            ),
            _CatalogTab(
              table: 'projects',
              controller: _controllers['projects']!,
              label: 'Ajouter un chantier',
              repository: _repository,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab({
    required this.table,
    required this.controller,
    required this.label,
    required this.repository,
  });

  final String table;
  final TextEditingController controller;
  final String label;
  final TransactionRepository repository;

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  Future<List<Map<String, dynamic>>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _itemsFuture = widget.repository.listCatalog(widget.table);
  }

  Future<void> _addItem() async {
    final value = widget.controller.text.trim();
    if (value.isEmpty) {
      return;
    }

    await widget.repository.insertCatalogEntry(widget.table, name: value);
    widget.controller.clear();
    setState(() {
      _load();
    });
  }

  Future<void> _deleteItem(int id) async {
    await widget.repository.deleteCatalogEntry(widget.table, id);
    setState(() {
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: widget.label,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (items.isEmpty) {
                  return const Center(child: Text('Aucune donnée enregistrée.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['name'] as String),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final id = item['id'] as int;
                          await _deleteItem(id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
