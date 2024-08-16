import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/people/v1.dart' as people_api;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

import 'SignInScreen.dart';
import 'UserPrefs.dart';
import 'CustomDrawer.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/contacts.readonly'],
  );

  late Future<List<Map<String, dynamic>>> _contactsFuture;
  final List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String _searchQuery = '';
  bool _isAdmin = false; // To check account type

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchContacts();
    _checkIfAdmin(); // Check if the current user is an admin
  }

  Future<void> _checkIfAdmin() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('family').doc(currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc['accountType'] == 'admin'; // Check the account type
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchContacts() async {
    try {
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently() ??
          await _googleSignIn.signIn();

      if (googleUser == null) throw Exception('User did not sign in with Google.');

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) throw Exception('Google access token is missing.');

      final authClient = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            accessToken,
            DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
          null,
          ['https://www.googleapis.com/auth/contacts.readonly'],
        ),
      );

      final peopleApi = people_api.PeopleServiceApi(authClient);
      final response = await peopleApi.people.connections.list(
        'people/me',
        personFields: 'names,emailAddresses,photos,phoneNumbers',
      );

      final contacts = response.connections ?? [];
      return contacts.map((contact) {
        return {
          'name': contact.names?.first.displayName ?? 'No Name',
          'email': contact.emailAddresses?.first.value ?? 'No Email',
          'photoUrl': contact.photos?.first.url ?? '',
          'phoneNumber': contact.phoneNumbers?.first.value ?? 'No Phone Number',
        };
      }).toList();
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await UserPrefs.clearUser();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _signOut(BuildContext context) => _handleSignOut(context);

  Future<void> _addFamilyMember(Map<String, dynamic> contact) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !_isAdmin) return; // Only allow admin users to add members

      final familyDocRef = FirebaseFirestore.instance.collection('family').doc(currentUser.uid);

      // Add the family member to the Firestore database
      await familyDocRef.update({
        'familyMembers': FieldValue.arrayUnion([contact]),
      });

      setState(() {
        _familyMembers.add(contact);
      });
    } catch (e) {
      print('Error adding family member: $e');
    }
  }

  void _removeFamilyMember(Map<String, dynamic> contact) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !_isAdmin) return; // Only allow admin users to remove members

      final familyDocRef = FirebaseFirestore.instance.collection('family').doc(currentUser.uid);

      // Remove the family member from the Firestore database
      await familyDocRef.update({
        'familyMembers': FieldValue.arrayRemove([contact]),
      });

      setState(() {
        _familyMembers.remove(contact);
      });
    } catch (e) {
      print('Error removing family member: $e');
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _contactsFuture.then((contacts) {
        _filteredContacts = contacts.where((contact) {
          final name = contact['name']?.toLowerCase() ?? '';
          final email = contact['email']?.toLowerCase() ?? '';
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsFuture = _fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: CustomDrawer(
        onSignOut: () => _signOut(context),
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
                      backgroundImage: contact['photoUrl'] != ''
                          ? NetworkImage(contact['photoUrl'])
                          : null,
                      child: contact['photoUrl'] == ''
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(contact['name'] ?? 'No Name'),
                    subtitle: Text(contact['email'] ?? 'No Email'),
                    trailing: Text(contact['phoneNumber'] ?? 'No Phone Number'),
                    onLongPress: () => _removeFamilyMember(contact),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAdmin ? () {
                _scaffoldKey.currentState?.openEndDrawer();
              } : null, // Disable the button if not an admin
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAdmin ? Theme.of(context).primaryColor : Colors.grey, // Grey out the button if not an admin
              ),
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}
