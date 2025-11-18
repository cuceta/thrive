// lib/core/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;
  


  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // optional: create account automatically
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        rethrow;
      }
    }
  }

  // Example Firestore write
  Future<void> addMoodEntry({required int moodValue}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');
    await _db.collection('users').doc(uid).collection('moods').add({
      'value': moodValue,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
