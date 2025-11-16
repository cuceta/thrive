// lib/core/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Example: Save a mood entry
  Future<void> addMoodEntry({
    required int moodValue,
    String? note,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');

    await _db.collection('users').doc(uid).collection('moods').add({
      'value': moodValue,
      'note': note ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Example: Get recent moods
  Stream<QuerySnapshot<Map<String, dynamic>>> getRecentMoods() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');

    return _db
        .collection('users')
        .doc(uid)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .snapshots();
  }
}
