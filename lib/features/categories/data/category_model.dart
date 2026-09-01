import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/enums.dart';

/// `users/{uid}/categories/{categoryId}`
///
/// Names are stored in both languages so switching the UI language relabels
/// existing data instead of leaving English names behind.
@immutable
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String nameEn;
  final String nameBn;
  final CategoryType type;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  /// The name to show for [languageCode], falling back to the other language
  /// when one side was left blank.
  String displayName(String languageCode) {
    if (languageCode == 'bn') {
      return nameBn.trim().isNotEmpty ? nameBn : nameEn;
    }
    return nameEn.trim().isNotEmpty ? nameEn : nameBn;
  }

  /// Used by search, so a query matches either language.
  String get searchableText => '$nameEn $nameBn'.toLowerCase();

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      nameEn: (map['nameEn'] as String?) ?? '',
      nameBn: (map['nameBn'] as String?) ?? '',
      type: CategoryType.fromName(map['type'] as String?),
      icon: (map['icon'] as String?) ?? 'category',
      colorHex: (map['colorHex'] as String?) ?? '#1B7F6B',
      isDefault: (map['isDefault'] as bool?) ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      CategoryModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, Object?> toMap() => <String, Object?>{
    'nameEn': nameEn,
    'nameBn': nameBn,
    'type': type.name,
    'icon': icon,
    'colorHex': colorHex,
    'isDefault': isDefault,
    'sortOrder': sortOrder,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  CategoryModel copyWith({
    String? id,
    String? nameEn,
    String? nameBn,
    CategoryType? type,
    String? icon,
    String? colorHex,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameBn: nameBn ?? this.nameBn,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is CategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
