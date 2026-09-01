import 'package:cloud_firestore/cloud_firestore.dart';

/// Single place that knows the Firestore layout. Repositories build every
/// query from here, so the `users/{uid}/...` scoping can never drift and no
/// code path can reach another user's subtree.
class FirestoreRefs {
  const FirestoreRefs(this._db, this.uid);

  final FirebaseFirestore _db;
  final String uid;

  static const String usersCollection = 'users';
  static const String accountsCollection = 'accounts';
  static const String categoriesCollection = 'categories';
  static const String transactionsCollection = 'transactions';
  static const String budgetsCollection = 'budgets';

  DocumentReference<Map<String, dynamic>> get user =>
      _db.collection(usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> get accounts =>
      user.collection(accountsCollection);

  CollectionReference<Map<String, dynamic>> get categories =>
      user.collection(categoriesCollection);

  CollectionReference<Map<String, dynamic>> get transactions =>
      user.collection(transactionsCollection);

  CollectionReference<Map<String, dynamic>> get budgets =>
      user.collection(budgetsCollection);

  WriteBatch batch() => _db.batch();

  FirebaseFirestore get db => _db;
}
