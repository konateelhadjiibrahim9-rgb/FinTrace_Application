import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Box<Transaction> transactionBox;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;
  String _selectedCategory = 'all';
  String _selectedPaymentMethod = 'all';

  @override
  void initState() {
    super.initState();
    transactionBox = StorageService.getTransactionBox();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Transaction> _getFilteredTransactions() {
    final searchText = _searchController.text.toLowerCase();
    
    return transactionBox.values.where((transaction) {
      // Filtre par texte de recherche
      if (searchText.isNotEmpty) {
        final matchesDescription = transaction.description.toLowerCase().contains(searchText);
        final matchesCategory = transaction.category.toLowerCase().contains(searchText);
        if (!matchesDescription && !matchesCategory) return false;
      }

      // Filtre par type
      if (_selectedFilter != 'all' && transaction.type != _selectedFilter) {
        return false;
      }

      // Filtre par catégorie
      if (_selectedCategory != 'all' && transaction.category != _selectedCategory) {
        return false;
      }

      // Filtre par méthode de paiement
      if (_selectedPaymentMethod != 'all' && transaction.paymentMethod != _selectedPaymentMethod) {
        return false;
      }

      // Filtre par montant
      if (_minAmount != null && transaction.amount < _minAmount!) return false;
      if (_maxAmount != null && transaction.amount > _maxAmount!) return false;

      // Filtre par date
      if (_selectedDateRange != null) {
        if (transaction.date.isBefore(_selectedDateRange!.start) || 
            transaction.date.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showAmountFilterDialog(BuildContext context) {
    final minController = TextEditingController(text: _minAmount?.toStringAsFixed(0) ?? '');
    final maxController = TextEditingController(text: _maxAmount?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par montant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant minimum (FCFA)',
                prefixIcon: Icon(Icons.arrow_upward),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant maximum (FCFA)',
                prefixIcon: Icon(Icons.arrow_downward),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minAmount = null;
                _maxAmount = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _minAmount = minController.text.isNotEmpty ? double.parse(minController.text) : null;
                _maxAmount = maxController.text.isNotEmpty ? double.parse(maxController.text) : null;
              });
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = 'all';
      _selectedDateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _selectedCategory = 'all';
      _selectedPaymentMethod = 'all';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();
    final hasActiveFilters = _selectedFilter != 'all' ||
        _selectedDateRange != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _selectedCategory != 'all' ||
        _selectedPaymentMethod != 'all';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par description ou catégorie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Tout', 'all', _selectedFilter, (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }),
                _buildFilterChip('Revenus', 'income', _selectedFilter, (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }),
                _buildFilterChip('Dépenses', 'expense', _selectedFilter, (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }),
                _buildFilterChip('Aujourd\'hui', 'today', _selectedFilter, (value) {
                  setState(() {
                    _selectedFilter = value;
                    _selectedDateRange = DateTimeRange(
                      start: DateTime.now(),
                      end: DateTime.now(),
                    );
                  });
                }),
                _buildFilterChip('Cette semaine', 'week', _selectedFilter, (value) {
                  final now = DateTime.now();
                  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  setState(() {
                    _selectedFilter = value;
                    _selectedDateRange = DateTimeRange(
                      start: startOfWeek,
                      end: now,
                    );
                  });
                }),
              ],
            ),
          ),

          // Filtres avancés
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Filtres avancés',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterButton(
                          'Date',
                          _selectedDateRange != null
                              ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                              : 'Toutes dates',
                          Icons.calendar_today,
                          () => _selectDateRange(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterButton(
                          'Montant',
                          _minAmount != null || _maxAmount != null
                              ? '${_minAmount?.toStringAsFixed(0) ?? 'Min'} - ${_maxAmount?.toStringAsFixed(0) ?? 'Max'}'
                              : 'Tous montants',
                          Icons.attach_money,
                          () => _showAmountFilterDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Toutes catégories'),
                            ),
                            ...{...AppConstants.expenseCategories, ...AppConstants.incomeCategories}
                                .map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Paiement',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Tous paiements'),
                            ),
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('Espèces'),
                            ),
                            DropdownMenuItem(
                              value: 'orange_money',
                              child: Text('Orange Money'),
                            ),
                            DropdownMenuItem(
                              value: 'mtn_money',
                              child: Text('MTN Money'),
                            ),
                            DropdownMenuItem(
                              value: 'wave',
                              child: Text('Wave'),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text('Banque'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: _clearAllFilters,
                        child: const Text('Effacer tous les filtres'),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Résultats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredTransactions.length} transaction${filteredTransactions.length > 1 ? 's' : ''} trouvée${filteredTransactions.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                if (filteredTransactions.isNotEmpty)
                  Text(
                    'Total: ${_calculateTotal(filteredTransactions).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),

          // Liste des transactions filtrées
          Expanded(
            child: filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Function(String) onSelected) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          onSelected(selected ? value : 'all');
        },
        selectedColor: const Color(AppConstants.primaryColor).withAlpha(50),
        checkmarkColor: const Color(AppConstants.primaryColor),
      ),
    );
  }

  Widget _buildFilterButton(String title, String subtitle, IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction.type == 'income'
                ? Colors.green.withAlpha(25)
                : Colors.red.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          '${transaction.amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category),
            Text(
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (transaction.description.isNotEmpty)
              Text(
                transaction.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text(
          _getPaymentMethodText(transaction.paymentMethod),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune transaction trouvée',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Essayez avec d\'autres critères de recherche',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'orange_money': return 'Orange Money';
      case 'mtn_money': return 'MTN Money';
      case 'wave': return 'Wave';
      case 'cash': return 'Espèces';
      case 'bank': return 'Banque';
      default: return method.toUpperCase();
    }
  }

  double _calculateTotal(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, transaction) {
      if (transaction.type == 'income') {
        return sum + transaction.amount;
      } else {
        return sum - transaction.amount;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}