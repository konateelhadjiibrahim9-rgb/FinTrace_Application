import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<String> _generateCSV() async {
    final transactionBox = StorageService.getTransactionBox();
    final transactions = transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    List<List<dynamic>> csvData = [];
    
    csvData.add([
      'Date',
      'Type',
      'Catégorie',
      'Montant (FCFA)',
      'Méthode de paiement',
      'Description'
    ]);

    for (var transaction in transactions) {
      csvData.add([
        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
        transaction.type == 'income' ? 'Revenu' : 'Dépense',
        transaction.category,
        transaction.amount.toStringAsFixed(0),
        _getPaymentMethodText(transaction.paymentMethod),
        transaction.description
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
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

  Future<void> _exportCSV() async {
    try {
      final csvString = await _generateCSV();
      final fileName = 'fintrace_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final csvBytes = utf8.encode(csvString);
      
      await Share.shareXFiles(
        [XFile.fromData(csvBytes, name: fileName, mimeType: 'text/csv')],
        subject: 'Export FinTrace',
      );
    } catch (e) {
      // Erreur gérée silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export des Données'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: StorageService.getTransactionBox().listenable(),
        builder: (context, box, widget) {
          final transactionCount = box.values.length;
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Résumé des Données',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('Transactions', transactionCount.toString(), Icons.receipt),
                            _buildStatCard('Revenus', '${_getTotalIncome(box.values.toList()).toStringAsFixed(0)} FCFA', Icons.arrow_upward),
                            _buildStatCard('Dépenses', '${_getTotalExpenses(box.values.toList()).toStringAsFixed(0)} FCFA', Icons.arrow_downward),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Options d\'Export',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('Export CSV'),
                    subtitle: const Text('Format compatible avec Excel et Google Sheets'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _exportCSV,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('Rapport PDF'),
                    subtitle: const Text('Rapport détaillé avec graphiques (bientôt disponible)'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité en cours de développement'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'L\'export CSV contient toutes vos transactions avec leurs détails complets. Vous pouvez l\'ouvrir dans Excel, Google Sheets ou tout autre tableur.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: const Color(AppConstants.primaryColor)),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _getTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}