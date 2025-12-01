import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';
import 'budgets_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Transaction> transactionBox;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    transactionBox = StorageService.getTransactionBox();
  }

  double get _totalIncome {
    return transactionBox.values
        .where((transaction) => transaction.type == 'income')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get _totalExpenses {
    return transactionBox.values
        .where((transaction) => transaction.type == 'expense')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get _totalBalance {
    return _totalIncome - _totalExpenses;
  }

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
        actions: [
          if (transactionBox.isNotEmpty && _currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearDataDialog,
              tooltip: 'Effacer toutes les données',
            ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.import_export),
            label: 'Export',
          ),
        ],
        selectedItemColor: const Color(AppConstants.primaryColor),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: _addTransaction,
              backgroundColor: const Color(AppConstants.primaryColor),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const StatisticsScreen();
      case 2:
        return const BudgetsScreen();
      case 3:
        return const ExportScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: transactionBox.listenable(),
      builder: (context, box, widget) {
        final transactions = box.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          children: [
            _buildBalanceCard(),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsList(transactions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
              _buildAmountCard('Revenus', _totalIncome, Colors.green[300]!),
              _buildAmountCard('Dépenses', _totalExpenses, Colors.red[300]!),
            ],
          ),
        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune transaction',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Commencez par ajouter votre première transaction',
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

  Widget _buildTransactionsList(List<Transaction> transactions) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteTransaction(transaction.id);
      },
      child: Card(
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
              transaction.type == 'income' 
                  ? Icons.arrow_upward 
                  : Icons.arrow_downward,
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
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getPaymentMethodText(transaction.paymentMethod),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.type == 'income' ? 'REVENU' : 'DÉPENSE',
                style: TextStyle(
                  fontSize: 10,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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

  void _addTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
  }

  void _deleteTransaction(String id) async {
    await StorageService.deleteTransaction(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction supprimée'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les transactions ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              StorageService.clearAllData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les données ont été effacées'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}