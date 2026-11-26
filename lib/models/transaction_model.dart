class TransactionModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime transactionDate; // التاريخ المخصص للعملية
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.transactionDate,
    this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] != null ? int.parse(map['id'].toString()) : null,
      userId: int.parse(map['user_id'].toString()),
      title: map['title'].toString(),
      amount: double.parse(map['amount'].toString()),
      type: map['type'].toString(),
      category: map['category'].toString(),
      // تحويل تاريخ العملية القادم من MySQL إلى DateTime
      transactionDate: DateTime.parse(map['transaction_date'].toString()),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      // تحويل تاريخ العملية إلى صيغة YYYY-MM-DD ليفهمها MySQL
      'transaction_date':
          "${transactionDate.year.toString().padLeft(4, '0')}-"
          "${transactionDate.month.toString().padLeft(2, '0')}-"
          "${transactionDate.day.toString().padLeft(2, '0')}",
    };
  }
}
