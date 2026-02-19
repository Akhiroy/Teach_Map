import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 SAVE USER DATA
  Future<void> saveUser({
    required String email,
    required String name,
    required String department,
    required String password,
    required String role,
  }) async {
    try {
      await _db.collection('users').doc(email).set({
        'email': email,
        'name': name,
        'department': department,
        'password': password,
        'role': role,
      });
      print("✅ User $email saved to Firestore");
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 READ USER DATA
  Future<Map<String, dynamic>?> getUser(String email) async {
    try {
      final doc = await _db.collection('users').doc(email).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
