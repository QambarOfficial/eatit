import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/people/v1.dart' as people_api;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'SignInScreen.dart';
import 'UserPrefs.dart';

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
  List<Map<String, dynamic>> _familyMembers = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String _searchQuery = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Added key

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchContacts();
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

  void _addFamilyMember(Map<String, dynamic> contact) {
    setState(() {
      _familyMembers.add(contact);
    });
  }

  void _removeFamilyMember(Map<String, dynamic> contact) {
    setState(() {
      _familyMembers.remove(contact);
    });
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
      key: _scaffoldKey, // Added key here
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Using the GlobalKey to open the end drawer
              _scaffoldKey.currentState?.openEndDrawer(); // Updated
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text('Contacts'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOut(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterContacts,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _contactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No contacts found.'));
                  }

                  final contacts = _searchQuery.isEmpty
                      ? snapshot.data!
                      : _filteredContacts;

                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
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
                        onTap: () {
                          _addFamilyMember(contact);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
              onPressed: () {
                // Using the GlobalKey to open the end drawer
                _scaffoldKey.currentState?.openEndDrawer(); // Updated
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}
