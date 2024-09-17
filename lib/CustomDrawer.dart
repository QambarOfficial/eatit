import 'package:eatit/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import the package for app version
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for user info
import 'ProfileScreen.dart';
import 'appService.dart'; // Assuming this is the file where AppService is defined

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AppService _appService = AppService();
  List<Map<String, dynamic>> _families = [];
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _familyIdController = TextEditingController();
  final TextEditingController _memberEmailController =
      TextEditingController(); // Added for family members
  String _appVersion = 'Loading...'; // Default value while fetching version
  String _username = 'Loading...'; // Placeholder for the username
  String _profilePhotoUrl = ''; // Placeholder for the profile photo URL

  @override
  void initState() {
    super.initState();
    _fetchAppVersion(); // Fetch the app version when the widget is initialized
    _loadUserProfile(); // Fetch the user's profile photo and username
    _fetchFamilies();
  }

  void _fetchFamilies() {
    _appService.getFamilies().listen((families) {
      setState(() {
        _families = families;
      });
    });
  }

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version; // Fetch version
    });
  }

  Future<void> _loadUserProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Use the getUserData method from appService
      Map<String, dynamic>? userData =
          await _appService.getUserData(currentUser.uid);

      setState(() {
        _username = userData?['username'] ?? currentUser.displayName ?? 'User';
        _profilePhotoUrl =
            userData?['profilePhotoUrl'] ?? currentUser.photoURL ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Custom Header with Profile Info and Logout Button and App Version
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                // Logout Button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.logout), // Logout icon
                    onPressed: () async {
                      await _appService.logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => SignInScreen()),
                      );
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePhotoUrl.isNotEmpty
                      ? NetworkImage(_profilePhotoUrl)
                      : null,
                  child: _profilePhotoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // App Version Display
                Text('App Version: $_appVersion',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // Expanded section for content
          Expanded(
            child: SingleChildScrollView(
              // Wrap the content in SingleChildScrollView
              child: Column(
                children: [
                  // Create Family Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Family',
                            style: TextStyle(fontSize: 18)),
                        TextFormField(
                          controller: _familyNameController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter Family Name'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_familyNameController.text.isNotEmpty) {
                              await _appService
                                  .createFamily(_familyNameController.text);
                              _familyNameController.clear();
                            }
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  ),

                  // Join Family Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join Family',
                            style: TextStyle(fontSize: 18)),
                        TextFormField(
                          controller: _adminEmailController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter Admin Email'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _familyIdController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter Family ID (optional)'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_adminEmailController.text.isNotEmpty) {
                              // Check for families associated with the admin email
                              QuerySnapshot familyQuery = await _appService
                                  .firestore
                                  .collection('families')
                                  .where('adminEmail',
                                      isEqualTo: _adminEmailController.text)
                                  .get();

                              if (familyQuery.docs.length > 1) {
                                // Multiple families found, prompt user for family ID
                                _showFamilySelectionDialog(
                                    context, familyQuery.docs);
                              } else if (familyQuery.docs.isNotEmpty) {
                                // Only one family found, join it directly
                                await _appService.joinFamily(
                                  familyId: familyQuery.docs.first.id,
                                );
                                _adminEmailController.clear();
                                _familyIdController
                                    .clear(); // Clear the text fields
                              } else {
                                print(
                                    "No families found for the admin email: ${_adminEmailController.text}");
                              }
                            }
                          },
                          child: const Text('Join'),
                        ),
                      ],
                    ),
                  ),

                  // families list
                  const Text(
                    'Families:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._families.map((family) {
                    return FutureBuilder<List<Map<String, String>>>(
                      future: _appService.getFamilyMembers(family['familyId']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                  tileColor: Colors.grey[200],
                                  title: Text(family['familyName']),
                                  onTap: () {
                                    print(
                                        "pass the tapped family and family members to profile screen");
                                  }),
                              const SizedBox(height: 8.0),
                            ],
                          );
                        }
                      },
                    );
                  }).toList(),
                  // Add Family Member Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Family Member',
                            style: TextStyle(fontSize: 18)),
                        TextFormField(
                          controller: _memberEmailController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter Family Member Email'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (_memberEmailController.text.isNotEmpty &&
                                _familyIdController.text.isNotEmpty) {
                              // Update the family with the new member
                              await _appService.updateFamily(
                                _familyIdController.text,
                                {
                                  'members': FieldValue.arrayUnion([
                                    _memberEmailController.text,
                                  ]),
                                },
                              );
                              _memberEmailController
                                  .clear(); // Clear the text field
                            }
                          },
                          child: const Text('Add Member'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show the Family Selection dialog
 void _showFamilySelectionDialog(
    BuildContext context, List<QueryDocumentSnapshot> familyDocs) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Select a Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: familyDocs.map((doc) {
            return ListTile(
              title: Text(doc['familyName']),
              onTap: () async {
                Navigator.of(context).pop(); // Close the dialog
                // Pass the selected family data to the ProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      familyId: doc.id,
                      familyName: doc['familyName'],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    },
  );
}
}
