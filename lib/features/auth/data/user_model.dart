import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// `users/{uid}` — the profile document, which also mirrors the user's
/// preferences so a second device can adopt them.
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.currencyCode,
    required this.languageCode,
    required this.themeMode,
    required this.useBanglaNumerals,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String currencyCode;
  final String languageCode;
  final String themeMode;
  final bool useBanglaNumerals;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Just the given name, for the dashboard greeting.
  String get firstName {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) return email.split('@').first;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final String source = displayName.trim().isEmpty
        ? email
        : displayName.trim();
    if (source.isEmpty) return '?';
    final List<String> parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      currencyCode: (map['currencyCode'] as String?) ?? 'BDT',
      languageCode: (map['languageCode'] as String?) ?? 'en',
      themeMode: (map['themeMode'] as String?) ?? 'system',
      useBanglaNumerals: (map['useBanglaNumerals'] as bool?) ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});

  Map<String, Object?> toMap() => <String, Object?>{
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'currencyCode': currencyCode,
    'languageCode': languageCode,
    'themeMode': themeMode,
    'useBanglaNumerals': useBanglaNumerals,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? currencyCode,
    String? languageCode,
    String? themeMode,
    bool? useBanglaNumerals,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      currencyCode: currencyCode ?? this.currencyCode,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      useBanglaNumerals: useBanglaNumerals ?? this.useBanglaNumerals,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
