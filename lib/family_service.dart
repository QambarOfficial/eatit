import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getFamilyData(String familyCode) async {
    try {
      DocumentSnapshot familyDoc = await _firestore.collection('families').doc(familyCode).get();
      return familyDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching family data: $e');
      return null;
    }
  }

  Future<void> updateFamilyMembers(String familyCode, String uid) async {
    try {
      await _firestore.collection('families').doc(familyCode).update({
        'members': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      print('Error updating family members: $e');
    }
  }
}
