import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/enums.dart';

/// `users/{uid}/accounts/{accountId}`
@immutable
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.openingBalance,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final String icon;
  final String colorHex;
  final double openingBalance;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;

  factory AccountModel.fromMap(String id, Map<String, dynamic> map) {
    return AccountModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      type: AccountType.fromName(map['type'] as String?),
      icon: (map['icon'] as String?) ?? 'cash',
      colorHex: (map['colorHex'] as String?) ?? '#1B7F6B',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0,
      isArchived: (map['isArchived'] as bool?) ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory AccountModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AccountModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'type': type.name,
    'icon': icon,
    'colorHex': colorHex,
    'openingBalance': openingBalance,
    'isArchived': isArchived,
    'sortOrder': sortOrder,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? icon,
    String? colorHex,
    double? openingBalance,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      openingBalance: openingBalance ?? this.openingBalance,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is AccountModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
