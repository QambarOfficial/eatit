import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'SignInScreen.dart';
import 'UserPrefs.dart';
import 'CustomDrawer.dart'; // Import the CustomDrawer widget

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, dynamic>> _familyMembers = []; // List to store family members
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin(); // Check if the current user is an admin
    _fetchFamilyMembers(); // Fetch family members from Firestore
  }

  Future<void> _checkIfAdmin() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc['accountType'] == 'admin'; // Check the account type
        });
      }
    }
  }

 Future<void> _fetchFamilyMembers() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    DocumentSnapshot familyDoc = await FirebaseFirestore.instance.collection('families').doc(currentUser.uid).get();
    if (familyDoc.exists) {
      // Assuming family members are stored as a list of user IDs
      List<dynamic> memberIds = familyDoc['members'];

      List<Map<String, dynamic>> members = [];
print(memberIds);
      for (String memberId in memberIds) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          members.add(userDoc.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        _familyMembers.addAll(members);
      });
    }
  }
}


  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await UserPrefs.clearUser();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _signOut(BuildContext context) => _handleSignOut(context);

  void _removeFamilyMember(Map<String, dynamic> contact) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !_isAdmin) return; // Only allow admin users to remove members

      final familyDocRef = FirebaseFirestore.instance.collection('families').doc(currentUser.uid);

      // Remove the family member from the Firestore database
      await familyDocRef.update({
        'members': FieldValue.arrayRemove([contact]),
      });

      setState(() {
        _familyMembers.remove(contact);
      });
    } catch (e) {
      print('Error removing family member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: CustomDrawer(
        user: widget.user, 
        onSignOut: () => _signOut(context), // Pass the onSignOut function
      ), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user.photoURL ?? ''),
              radius: 50,
            ),
            const SizedBox(height: 16),
            Text(
              'Name: ${widget.user.displayName ?? 'No Name'}',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Email: ${widget.user.email ?? 'No Email'}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text(
              'Family Members:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
           Expanded(
  child: ListView.builder(
    itemCount: _familyMembers.length,
    itemBuilder: (context, index) {
      final contact = _familyMembers[index];
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: contact['photoURL'] != null && contact['photoURL'] != ''
              ? NetworkImage(contact['photoURL'])
              : null,
          child: contact['photoURL'] == null || contact['photoURL'] == ''
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(contact['username'] ?? 'No Name'), // Handle null username
        subtitle: Text(contact['email'] ?? 'No Email'), // Handle null email
        trailing: _isAdmin
            ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeFamilyMember(contact),
              )
            : null,
      );
    },
  ),
)
,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
