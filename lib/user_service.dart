import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> updateUserFamilyCode(String uid, String familyCode) async {
    try {
      await _firestore.collection('users').doc(uid).update({'familyCode': familyCode});
    } catch (e) {
      print('Error updating user family code: $e');
    }
  }

  Future<void> updateUserTag(String uid, String tag) async { // Added method to update user tag
    try {
      await _firestore.collection('users').doc(uid).update({'tag': tag});
    } catch (e) {
      print('Error updating user tag: $e');
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      // Clean up family memberships
      await _removeFromAllFamilies(uid);
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> _removeFromAllFamilies(String uid) async {
    try {
      QuerySnapshot familyDocs = await _firestore.collection('families').where('members', arrayContains: uid).get();
      for (var doc in familyDocs.docs) {
        List<dynamic> members = doc.get('members');
        members.remove(uid);
        await doc.reference.update({'members': members});
      }
    } catch (e) {
      print('Error removing user from families: $e');
    }
  }
}
