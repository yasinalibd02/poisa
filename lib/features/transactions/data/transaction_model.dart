import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/enums.dart';

/// `users/{uid}/transactions/{transactionId}`
///
/// [amount] is always stored positive; [type] carries the direction. That
/// keeps aggregation queries simple and stops a stray minus sign from turning
/// an expense into income.
@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.toAccountId,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final double amount;

  /// `null` for transfers.
  final String? categoryId;

  /// Source account (or the only account, for income/expense).
  final String accountId;

  /// Destination account — transfers only.
  final String? toAccountId;

  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Signed value for balance math: expenses and outgoing transfers are
  /// negative from the perspective of [accountId].
  double get signedAmount => switch (type) {
    TransactionType.income => amount,
    TransactionType.expense => -amount,
    TransactionType.transfer => -amount,
  };

  /// Effect on a specific account's balance.
  double effectOn(String targetAccountId) {
    if (type == TransactionType.transfer) {
      if (targetAccountId == accountId) return -amount;
      if (targetAccountId == toAccountId) return amount;
      return 0;
    }
    if (targetAccountId != accountId) return 0;
    return type == TransactionType.income ? amount : -amount;
  }

  bool touchesAccount(String id) => accountId == id || toAccountId == id;

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      type: TransactionType.fromName(map['type'] as String?),
      amount: ((map['amount'] as num?)?.toDouble() ?? 0).abs(),
      categoryId: map['categoryId'] as String?,
      accountId: (map['accountId'] as String?) ?? '',
      toAccountId: map['toAccountId'] as String?,
      note: (map['note'] as String?) ?? '',
      date:
          (map['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory TransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      TransactionModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'amount': amount,
    'categoryId': categoryId,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'note': note,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    String? toAccountId,
    bool clearToAccount = false,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccount ? null : (toAccountId ?? this.toAccountId),
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is TransactionModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
