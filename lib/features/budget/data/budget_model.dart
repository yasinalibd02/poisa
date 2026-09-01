import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// `users/{uid}/budgets/{budgetId}`
///
/// A `null` [categoryId] is the single overall budget for that month.
@immutable
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.period,
    required this.year,
    required this.month,
    required this.createdAt,
  });

  final String id;
  final String? categoryId;
  final double limitAmount;

  /// Only `monthly` ships in v1; the field exists so weekly/yearly can be
  /// added without a migration.
  final String period;

  final int year;
  final int month;
  final DateTime createdAt;

  bool get isOverall => categoryId == null;

  /// Stable key for "same budget, different month" lookups.
  String get slot => '$year-${month.toString().padLeft(2, '0')}';

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      categoryId: map['categoryId'] as String?,
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0,
      period: (map['period'] as String?) ?? 'monthly',
      year: (map['year'] as num?)?.toInt() ?? 0,
      month: (map['month'] as num?)?.toInt() ?? 1,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory BudgetModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BudgetModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, Object?> toMap() => <String, Object?>{
    'categoryId': categoryId,
    'limitAmount': limitAmount,
    'period': period,
    'year': year,
    'month': month,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    bool clearCategory = false,
    double? limitAmount,
    String? period,
    int? year,
    int? month,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is BudgetModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
