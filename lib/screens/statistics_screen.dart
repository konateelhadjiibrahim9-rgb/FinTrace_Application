import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Box<Transaction> transactionBox;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    transactionBox = StorageService.getTransactionBox();
  }

  Map<String, double> _getCategoryTotals(String type) {
    Map<String, double> categoryTotals = {};
    
    final transactions = transactionBox.values.where((t) => t.type == type).toList();
    
    for (var transaction in transactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    
    return categoryTotals;
  }

  double _getTotalByType(String type) {
    return transactionBox.values
        .where((transaction) => transaction.type == type)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: transactionBox.listenable(),
        builder: (context, box, widget) {
          final expensesByCategory = _getCategoryTotals('expense');
          final incomeByCategory = _getCategoryTotals('income');
          final totalExpenses = _getTotalByType('expense');
          final totalIncome = _getTotalByType('income');

          if (box.isEmpty) {
            return const Center(
              child: Text(
                'Aucune donnée à afficher',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildPeriodButton('Mois', 'month'),
                        const SizedBox(width: 10),
                        _buildPeriodButton('Semaine', 'week'),
                        const SizedBox(width: 10),
                        _buildPeriodButton('Total', 'all'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Revenus',
                        totalIncome,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'Dépenses',
                        totalExpenses,
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (expensesByCategory.isNotEmpty)
                  _buildCategorySection('Dépenses par Catégorie', expensesByCategory, totalExpenses, true),

                const SizedBox(height: 20),

                if (incomeByCategory.isNotEmpty)
                  _buildCategorySection('Revenus par Catégorie', incomeByCategory, totalIncome, false),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton(String text, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected 
              ? const Color(AppConstants.primaryColor).withAlpha(25)
              : null,
          side: BorderSide(
            color: isSelected 
                ? const Color(AppConstants.primaryColor) 
                : Colors.grey,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected 
                ? const Color(AppConstants.primaryColor) 
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, Map<String, double> categoryData, double total, bool isExpense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryData.entries.map((entry) {
              final percentage = total > 0 ? (entry.value / total * 100).toDouble() : 0.0;
              return _buildCategoryItem(entry.key, entry.value, percentage, isExpense);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage, bool isExpense) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                category,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExpense ? Colors.red : Colors.green,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            Text(
              '${amount.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}