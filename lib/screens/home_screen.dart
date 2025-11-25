import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  final List<Transaction> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text(
          'FinTrace',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(AppConstants.primaryColor),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Carte du solde
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text(
                  'Solde Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_totalBalance.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmountCard('Revenus', _totalIncome, Colors.green),
                    _buildAmountCard('Dépenses', _totalExpenses, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          
          // Liste des transactions
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        backgroundColor: const Color(AppConstants.primaryColor),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAmountCard(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          transaction.type == 'income' 
              ? Icons.arrow_circle_up 
              : Icons.arrow_circle_down,
          color: transaction.type == 'income' ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(
          '${transaction.amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
          ),
        ),
        subtitle: Text(transaction.category),
        trailing: Text(
          transaction.paymentMethod.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _addTransaction() {
    // Pour l'instant, on ajoute une transaction factice
    // Dans la prochaine étape, on créera un formulaire
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: 5000.0,
      category: 'Nourriture',
      date: DateTime.now(),
      type: 'expense',
      description: 'Courses alimentaires',
      paymentMethod: 'orange_money',
    );

    setState(() {
      _transactions.add(newTransaction);
      _totalExpenses += newTransaction.amount;
      _totalBalance = _totalIncome - _totalExpenses;
    });
  }
}