class Transaction {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String type; // 'income' ou 'expense'
  final String description;
  final String paymentMethod; // 'cash', 'orange_money', 'mtn_money', 'bank'

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.description,
    required this.paymentMethod,
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'paymentMethod': paymentMethod,
    };
  }

  // Créer depuis Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      description: map['description'],
      paymentMethod: map['paymentMethod'],
    );
  }
}