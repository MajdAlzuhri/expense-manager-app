import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class DatabaseService {
  static const String baseUrl =
      'https://expense-manager-api-tau.vercel.app/api';

  // ==================== Auth Operations ====================

  static Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e, stackTrace) {
      print("===== REGISTER DETAILED ERROR =====");
      print(e);
      print(stackTrace);
      print("===================================");
      return false;
    }
  }

  static Future<dynamic> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['user'] != null) {
          final user = data['user'];
          return <String, dynamic>{
            "id": user['id'].toString(),
            "name": user['name'],
            "email": user['email'],
          };
        }
      }
      return null;
    } catch (e, stackTrace) {
      print("===== LOGIN DETAILED ERROR =====");
      print(e);
      print(stackTrace);
      print("===================================");
      return null;
    }
  }

  // ==================== Transactions Operations ====================

  static Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': transaction.userId,
          'title': transaction.title,
          'amount': transaction.amount,
          'type': transaction.type,
          'category': transaction.category,
          'transaction_date': transaction.toMap()['transaction_date'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e, stackTrace) {
      print("===== ADD TRANSACTION ERROR =====");
      print(e);
      print(stackTrace);
      print("=================================");
      return false;
    }
  }

  static Future<List<TransactionModel>> getUserTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List items = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['transactions'] ?? []);

        return items.map((item) {
          final stringMap = <String, String>{};
          (item as Map).forEach((key, value) {
            stringMap[key.toString()] = value?.toString() ?? '';
          });
          return TransactionModel.fromMap(stringMap);
        }).toList();
      }
      return [];
    } catch (e, stackTrace) {
      print("===== GET TRANSACTIONS ERROR =====");
      print(e);
      print(stackTrace);
      print("==================================");
      return [];
    }
  }

  static Future<bool> deleteTransaction(int transactionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$transactionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e, stackTrace) {
      print("===== DELETE TRANSACTION ERROR =====");
      print(e);
      print(stackTrace);
      print("====================================");
      return false;
    }
  }
}
