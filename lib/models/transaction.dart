enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  final String userId;
  final String savingsPotId;
  final double amount;
  final TransactionType type; 
  final DateTime date;
  final String? notes;
  final String? category;
  final String? categoryId;
  final DateTime createdAt;

  // Constructor
  Transaction({
    required this.id,
    required this.userId,
    required this.savingsPotId,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.category,
    this.categoryId,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      savingsPotId: json['savings_pot_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      category: json['category'],
      categoryId: json['category_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'savings_pot_id': savingsPotId,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'date': date.toIso8601String(),
      'notes': notes,
      'category': category,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
    };
    
    // Add ID only if it's not empty
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }

  // Copy with method for updating
  Transaction copyWith({
    String? id,
    String? userId,
    String? savingsPotId,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? notes,
    String? category,
    String? categoryId,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      savingsPotId: savingsPotId ?? this.savingsPotId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 