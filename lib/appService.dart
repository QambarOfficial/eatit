import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Public getters for _auth and _firestore
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // User-related functions
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> createAccount(
      String uid, String email, String username, String photoURL) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'families': [], // List of families the user is part of
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating account: $e');
    }
  }

  Future<void> createFamily(String familyName) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String email = currentUser.email!;

        DocumentReference familyRef = _firestore.collection('families').doc();

        await familyRef.set({
          'familyName': familyName,
          'adminEmail': email,
          'createdAt': FieldValue.serverTimestamp(),
          'members': [currentUser.uid], // Add the admin to the members list
        });

        await _firestore.collection('users').doc(currentUser.uid).update({
          'families': FieldValue.arrayUnion([familyRef.id]),
        });

        print("Family created with ID: ${familyRef.id}");
      }
    } catch (e) {
      print("Error creating family: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getFamilies() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    String uid = currentUser.uid;
    return _firestore
        .collection('families')
        .where('members',
            arrayContains: uid) // Filter families where user is a member
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'familyName': doc['familyName'],
          'familyId': doc.id,
        };
      }).toList();
    });
  }

  Future<void> deleteFamily(String familyId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('families').doc(familyId).delete();

        await _firestore.collection('users').doc(currentUser.uid).update({
          'families': FieldValue.arrayRemove([familyId]),
        });
      }
    } catch (e) {
      print("Error deleting family: $e");
    }
  }

  Future<void> joinFamily({String? adminEmail, String? familyId}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (familyId != null) {
          DocumentSnapshot familyDoc =
              await _firestore.collection('families').doc(familyId).get();

          if (familyDoc.exists) {
            await _firestore.collection('users').doc(currentUser.uid).update({
              'families': FieldValue.arrayUnion([familyId]),
            });

            await _firestore.collection('families').doc(familyId).update({
              'members': FieldValue.arrayUnion([currentUser.uid]),
            });

            print("Successfully joined the family: ${familyDoc['familyName']}");
          } else {
            print("No family found with the provided family ID: $familyId");
          }
        } else if (adminEmail != null) {
          QuerySnapshot familyQuery = await _firestore
              .collection('families')
              .where('adminEmail', isEqualTo: adminEmail)
              .get();

          if (familyQuery.docs.isNotEmpty) {
            List<String> familyIds =
                familyQuery.docs.map((doc) => doc.id).toList();

            await _firestore.collection('users').doc(currentUser.uid).update({
              'families': FieldValue.arrayUnion(familyIds),
            });

            for (String familyId in familyIds) {
              await _firestore.collection('families').doc(familyId).update({
                'members': FieldValue.arrayUnion([currentUser.uid]),
              });
            }

            print(
                "Successfully joined families associated with the admin email: $adminEmail");
          } else {
            print("No families found for the admin email: $adminEmail");
          }
        } else {
          print("Either adminEmail or familyId must be provided.");
        }
      }
    } catch (e) {
      print("Error joining family: $e");
    }
  }

  Future<void> updateFamily(
      String familyId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('families').doc(familyId).update(updates);
      print("Family updated successfully.");
    } catch (e) {
      print("Error updating family: $e");
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
      print("User updated successfully.");
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> addFamilyMember(String familyId, String memberId) async {
    try {
      await _firestore.collection('families').doc(familyId).update({
        'members': FieldValue.arrayUnion([memberId]),
      });
      print("Member added to family successfully.");
    } catch (e) {
      print("Error adding member to family: $e");
    }
  }

// New function to get family members
  Future<List<Map<String, String>>> getFamilyMembers(String familyId) async {
    try {
      DocumentSnapshot familyDoc =
          await _firestore.collection('families').doc(familyId).get();
      if (familyDoc.exists) {
        List<String> memberIds = List<String>.from(familyDoc['members'] ?? []);
        List<Map<String, String>> memberDetails = [];

        for (String memberId in memberIds) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            memberDetails.add({
              'username': userDoc['username'] ?? 'Unknown',
              'photoURL': userDoc['photoURL'] ?? '',
            });
          }
        }
        return memberDetails;
      } else {
        return [];
      }
    } catch (e) {
      print("Error getting family members: $e");
      return [];
    }
  }

  Future<void> removeFamilyMember(String familyId, String memberId) async {
    try {
      await _firestore.collection('families').doc(familyId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });
      print("Member removed from family successfully.");
    } catch (e) {
      print("Error removing member from family: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error logging out: $e");
    }
  }

// delete account method

  Future<void> deleteAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String uid = currentUser.uid;

        // Fetch the user's families
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          List<String> familyIds = List<String>.from(userDoc['families'] ?? []);

          // Remove user from all families they belong to
          for (String familyId in familyIds) {
            await _firestore.collection('families').doc(familyId).update({
              'members': FieldValue.arrayRemove([uid]),
            });
          }

          // Delete the user's document from Firestore
          await _firestore.collection('users').doc(uid).delete();

          // Delete the user's authentication account
          await currentUser.delete();

          print("User account deleted successfully.");
        } else {
          print("User document not found.");
        }
      }
    } catch (e) {
      print("Error deleting account: $e");
    }
  }
}
