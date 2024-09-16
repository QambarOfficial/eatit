import 'package:cloud_firestore/cloud_firestore.dart';

class AppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User-related functions
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserTag(String uid, String tag) async {
    try {
      await _firestore.collection('users').doc(uid).update({'tag': tag});
    } catch (e) {
      print('Error updating user tag: $e');
    }
  }

  Future<void> updateUserFamilyCode(String uid, String? familyCode) async {
    try {
      await _firestore.collection('users').doc(uid).update({'familyCode': familyCode});
    } catch (e) {
      print('Error updating user family code: $e');
    }
  }

  Future<void> createAccount(
      String uid, String email, String username, String photoURL, String accountType) async {
    try {
      String familyCode = accountType == 'admin' ? uid : '';
      
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'photoURL': photoURL,
        'accountType': accountType,
        'createdAt': FieldValue.serverTimestamp(),
        'familyCode': familyCode,
      }, SetOptions(merge: true));

      if (accountType == 'admin') {
        // Create a new family document for admin
        await _firestore.collection('families').doc(familyCode).set({
          'adminId': uid,
          'familyCode': familyCode,
          'members': [uid],
        });
      }
    } catch (e) {
      print('Error creating account: $e');
    }
  }

   Future<void> deleteUserAccount(String uid) async {
  try {
    // Get user data before deleting
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      String? familyCode = userDoc.get('familyCode');
      String accountType = userDoc.get('accountType');

      if (accountType == 'admin' && familyCode != null && familyCode.isNotEmpty) {
        // If the user is admin, unlink all family members
        DocumentSnapshot familyDoc = await _firestore.collection('families').doc(familyCode).get();

        if (familyDoc.exists) {
          List<dynamic> members = familyDoc.get('members');

          // Unlink each family member from the family
          for (var memberId in members) {
            if (memberId != uid) {
              // Unlink family member from the family
              await _firestore.collection('users').doc(memberId).update({
                'familyCode': FieldValue.delete(), // Clear family code
              });
            }
          }

          // Delete the family document after unlinking members
          await _firestore.collection('families').doc(familyCode).delete();
        }
      }
    }

    // Delete the user document
    await _firestore.collection('users').doc(uid).delete();
  } catch (e) {
    print('Error deleting user account: $e');
  }
}



  // Family-related functions
  Future<Map<String, dynamic>?> getFamilyData(String familyCode) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('families').doc(familyCode).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting family data: $e');
      return null;
    }
  }

  Future<void> unlinkFamilyMember(String familyCode, String memberId) async {
    try {
      await _firestore.collection('families').doc(familyCode).update({
        'members': FieldValue.arrayRemove([memberId])
      });
    } catch (e) {
      print('Error unlinking family member: $e');
    }
  }

  Future<void> addFamilyMember(String familyCode, String memberId) async {
    try {
      await _firestore.collection('families').doc(familyCode).update({
        'members': FieldValue.arrayUnion([memberId])
      });
    } catch (e) {
      print('Error adding family member: $e');
    }
  }
}
