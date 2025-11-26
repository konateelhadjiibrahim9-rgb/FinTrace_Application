import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _transactionBoxName = 'transactions';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter());
    await Hive.openBox<Transaction>(_transactionBoxName);
  }

  static Box<Transaction> getTransactionBox() {
    return Hive.box<Transaction>(_transactionBoxName);
  }

  static Future<void> saveTransaction(Transaction transaction) async {
    final box = getTransactionBox();
    await box.put(transaction.id, transaction);
  }

  static List<Transaction> getAllTransactions() {
    final box = getTransactionBox();
    return box.values.toList();
  }

  static Future<void> deleteTransaction(String id) async {
    final box = getTransactionBox();
    await box.delete(id);
  }

  static Future<void> clearAllData() async {
    final box = getTransactionBox();
    await box.clear();
  }
}