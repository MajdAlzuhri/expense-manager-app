import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db/database_service.dart';
import 'models/transaction_model.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // index الشاشة الحالية (0 = Home, 1 = Profile)

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // جلب المصاريف وحساب المجاميع
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final userId = int.parse(widget.userData['id'].toString());
    final list = await DatabaseService.getUserTransactions(userId);

    double income = 0.0;
    double expense = 0.0;

    for (var item in list) {
      if (item.type == 'income') {
        income += item.amount;
      } else {
        expense += item.amount;
      }
    }

    setState(() {
      _transactions = list;
      _totalIncome = income;
      _totalExpense = expense;
      _totalBalance = income - expense;
      _isLoading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood_outlined;
      case 'transport':
        return Icons.directions_bus_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'salary':
        return Icons.attach_money_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _confirmDeleteTransaction(TransactionModel tx) {
    if (tx.id == null) return;

    final bool isExpense = tx.type == 'expense';

    showDialog(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete "${tx.title}" (\$${tx.amount.toStringAsFixed(2)})?\n\n'
            'Do you want to adjust your total balance accordingly?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dCtx);
                bool success = await DatabaseService.deleteTransaction(tx.id!);
                if (success) {
                  _showMessage(
                    'Transaction deleted without balance adjustment.',
                  );
                  _loadTransactions();
                } else {
                  _showMessage('Failed to delete transaction.');
                }
              },
              child: const Text(
                'Delete Only',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dCtx);

                final userId = int.parse(widget.userData['id'].toString());
                final adjustmentTx = TransactionModel(
                  userId: userId,
                  title: isExpense
                      ? 'Refund: ${tx.title}'
                      : 'Reversal: ${tx.title}',
                  amount: tx.amount,
                  type: isExpense ? 'income' : 'expense',
                  category: 'Other',
                  transactionDate: DateTime.now(),
                );

                bool deleted = await DatabaseService.deleteTransaction(tx.id!);
                if (deleted) {
                  await DatabaseService.addTransaction(adjustmentTx);
                  _showMessage('Transaction deleted & balance adjusted!');
                  _loadTransactions();
                } else {
                  _showMessage('Failed to delete transaction.');
                }
              },
              child: const Text(
                'Delete & Adjust Balance',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Food';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add New Transaction',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Expense')),
                          selected: selectedType == 'expense',
                          selectedColor: Colors.red.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedType = 'expense');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Income')),
                          selected: selectedType == 'income',
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedType = 'income');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Lunch, Salary',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(
                        value: 'Transport',
                        child: Text('Transport'),
                      ),
                      DropdownMenuItem(
                        value: 'Shopping',
                        child: Text('Shopping'),
                      ),
                      DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Date: ${_formatDate(selectedDate)}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amountText = amountController.text.trim();

                      if (title.isEmpty || amountText.isEmpty) {
                        showDialog(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Missing Information'),
                            content: const Text(
                              'Please fill in both title and amount.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        showDialog(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Invalid Amount'),
                            content: const Text(
                              'Please enter a valid amount greater than 0.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      if (selectedType == 'expense' && amount > _totalBalance) {
                        showDialog(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Insufficient Balance'),
                            content: Text(
                              'Your current balance is \$${_totalBalance.toStringAsFixed(2)}. You cannot add an expense of \$${amount.toStringAsFixed(2)}.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final userId = int.parse(
                        widget.userData['id'].toString(),
                      );

                      final newTx = TransactionModel(
                        userId: userId,
                        title: title,
                        amount: amount,
                        type: selectedType,
                        category: selectedCategory,
                        transactionDate: selectedDate,
                      );

                      Navigator.pop(ctx);

                      bool success = await DatabaseService.addTransaction(
                        newTx,
                      );
                      if (success) {
                        _showMessage('Transaction added successfully!');
                        _loadTransactions();
                      } else {
                        _showMessage('Failed to add transaction.');
                      }
                    },
                    child: const Text('Save Transaction'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // محتوى شاشة الـ Home
  Widget _buildHomeTab() {
    final userName = widget.userData['name'] ?? 'User';

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: Column(
        children: [
          // 1. بطاقة الرصيد
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Welcome, $userName',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _totalBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.green),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Income',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '\$${_totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.red),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expense',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '\$${_totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. ترويسة القائمة
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 3. قائمة العمليات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? const Center(child: Text('No transactions added yet.'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final isIncome = tx.type == 'income';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: Icon(
                              _getCategoryIcon(tx.category),
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            tx.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${tx.category} • ${_formatDate(tx.transactionDate)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _confirmDeleteTransaction(tx),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة الشاشات للتنقل بينها
    final List<Widget> pages = [
      _buildHomeTab(),
      ProfileScreen(userData: widget.userData),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(title: const Text('Expense Manager'), centerTitle: true)
          : null, // إخفاء الـ AppBar عند الانتقال لشاشة الـ Profile لعدم التكرار

      body: pages[_currentIndex],

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTransactionSheet,
              child: const Icon(Icons.add),
            )
          : null, // إخفاء زر الإضافة في صفحة البروفايل
      // شريط التنقل السفلي (Bottom Navigation Bar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
