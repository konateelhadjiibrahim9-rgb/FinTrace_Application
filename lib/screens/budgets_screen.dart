import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class Budget {
  final String id;
  final String category;
  final double amount;
  final DateTime period;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'].toDouble(),
      period: DateTime.parse(map['period']),
    );
  }
}

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late Box<Transaction> transactionBox;
  late Box budgetBox;
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Nourriture';

  @override
  void initState() {
    super.initState();
    transactionBox = StorageService.getTransactionBox();
    budgetBox = StorageService.getBudgetBox();
  }

  double _getCurrentSpending(String category) {
    return transactionBox.values
        .where((transaction) => 
            transaction.type == 'expense' && 
            transaction.category == category)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  void _addBudget() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: AppConstants.expenseCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_amountController.text.isNotEmpty) {
                final newBudget = Budget(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  category: _selectedCategory,
                  amount: double.parse(_amountController.text),
                  period: DateTime.now(),
                );
                
                budgetBox.put(newBudget.id, newBudget.toMap());
                
                _amountController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _deleteBudget(String id) {
    budgetBox.delete(id);
    setState(() {});
  }

  List<Budget> _getBudgets() {
    final budgetMaps = budgetBox.values.toList();
    return budgetMaps.map((map) => Budget.fromMap(Map<String, dynamic>.from(map as Map))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final budgets = _getBudgets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Résumé des Budgets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBudgetSummary('Budget Total', _getTotalBudget(budgets), Colors.blue),
                      _buildBudgetSummary('Dépenses', _getTotalSpending(budgets), Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: budgets.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucun budget défini',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      final currentSpending = _getCurrentSpending(budget.category);
                      final percentage = budget.amount > 0 
                          ? (currentSpending / budget.amount * 100).toDouble()
                          : 0.0;
                      
                      return _buildBudgetCard(budget, currentSpending, percentage);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        backgroundColor: const Color(AppConstants.primaryColor),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetSummary(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget, double currentSpending, double percentage) {
    final isOverBudget = currentSpending > budget.amount;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBudget(budget.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage > 100 ? 1.0 : percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentSpending.toStringAsFixed(0)} FCFA / ${budget.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Budget dépassé de ${(currentSpending - budget.amount).toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getTotalBudget(List<Budget> budgets) {
    return budgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }

  double _getTotalSpending(List<Budget> budgets) {
    return budgets.fold(0.0, (sum, budget) => sum + _getCurrentSpending(budget.category));
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}