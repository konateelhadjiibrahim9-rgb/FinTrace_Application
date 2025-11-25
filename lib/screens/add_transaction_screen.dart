import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../constants/app_constants.dart';

class AddTransactionScreen extends StatefulWidget {
  final Function(Transaction) onTransactionAdded;

  const AddTransactionScreen({super.key, required this.onTransactionAdded});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du formulaire
  final _amountController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Nourriture';
  String _selectedPaymentMethod = 'cash';
  final _descriptionController = TextEditingController();

  // Liste des méthodes de paiement spécifiques à la Côte d'Ivoire
  final List<String> _paymentMethods = [
    'cash',
    'orange_money', 
    'mtn_money',
    'wave',
    'bank',
    'autre'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Transaction'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Type de transaction (Revenu/Dépense)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de transaction',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton('Dépense', 'expense'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTypeButton('Revenu', 'income'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: (_selectedType == 'income' 
                    ? AppConstants.incomeCategories 
                    : AppConstants.expenseCategories
                ).map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Méthode de paiement
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Méthode de paiement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                items: _paymentMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(
                      method == 'orange_money' ? 'Orange Money' :
                      method == 'mtn_money' ? 'MTN Money' :
                      method == 'wave' ? 'Wave' :
                      method.replaceAll('_', ' ').toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String text, String type) {
    final isSelected = _selectedType == type;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedType = type;
          // Reset category quand le type change
          _selectedCategory = type == 'income' 
              ? AppConstants.incomeCategories.first 
              : AppConstants.expenseCategories.first;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected 
            ? const Color(AppConstants.primaryColor).withOpacity(0.1)
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
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: DateTime.now(),
        type: _selectedType,
        description: _descriptionController.text.isEmpty 
            ? 'Transaction ${_selectedType == 'income' ? 'revenu' : 'dépense'}' 
            : _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
      );

      // Retour à l'écran précédent avec la nouvelle transaction
      Navigator.pop(context);
      widget.onTransactionAdded(newTransaction);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}