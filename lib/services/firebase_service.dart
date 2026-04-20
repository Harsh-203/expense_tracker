import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Auth ──────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Expenses ──────────────────────────────────────
  CollectionReference get expensesCollection {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('expenses');
  }

  Future<void> addExpense(String title, double amount, String category) async {
    await expensesCollection.add({
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getExpenses() {
    return expensesCollection
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> deleteExpense(String docId) async {
    await expensesCollection.doc(docId).delete();
  }

  // ── Custom Categories ─────────────────────────────
  CollectionReference get categoriesCollection {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('categories');
  }

  Future<void> addCategory(String name) async {
    await categoriesCollection.add({'name': name});
  }

  Stream<QuerySnapshot> getCustomCategories() {
    return categoriesCollection.snapshots();
  }
}