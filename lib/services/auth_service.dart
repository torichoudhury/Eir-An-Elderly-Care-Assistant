import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> saveUserDetails(
    String uid,
    String name,
    String place,
    int age,
    String gender,
    String userType,
    String phoneNumber, [
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? emergencyContactRelation,
    String? receiverId,
  ]) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'place': place,
        'age': age,
        'gender': gender,
        'userType': userType,
        'phoneNumber': phoneNumber, // Save phone number
        'emergencyContactName': emergencyContactName,
        'emergencyContactNumber': emergencyContactNumber,
        'emergencyContactRelation': emergencyContactRelation,
        'receiverId': receiverId,
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
