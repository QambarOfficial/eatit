import 'package:eatit/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appService.dart'; // Assuming this is the file where AppService is defined

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AppService _appService = AppService();
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _familyIdController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController(); // Added for family members
  final String _appVersion = '1.0.0'; // Set your app version here

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Text(
              'Family Management',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),

          // Create Family Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Family',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _familyNameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter Family Name'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_familyNameController.text.isNotEmpty) {
                      await _appService
                          .createFamily(_familyNameController.text);
                      _familyNameController.clear(); // Clear the text field
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _adminEmailController,
                  decoration:
                      const InputDecoration(hintText: 'Enter Admin Email'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _familyIdController,
                  decoration: const InputDecoration(
                      hintText: 'Enter Family ID (optional)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (_adminEmailController.text.isNotEmpty) {
                      // Check for families associated with the admin email
                      QuerySnapshot familyQuery = await _appService.firestore
                          .collection('families')
                          .where('adminEmail',
                              isEqualTo: _adminEmailController.text)
                          .get();

                      if (familyQuery.docs.length > 1) {
                        // Multiple families found, prompt user for family ID
                        _showFamilySelectionDialog(context, familyQuery.docs);
                      } else if (familyQuery.docs.isNotEmpty) {
                        // Only one family found, join it directly
                        await _appService.joinFamily(
                          familyId: familyQuery.docs.first.id,
                        );
                        _adminEmailController.clear();
                        _familyIdController.clear(); // Clear the text fields
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

          // Add Family Member Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Family Member',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _memberEmailController,
                  decoration:
                      const InputDecoration(hintText: 'Enter Family Member Email'),
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
                      _memberEmailController.clear(); // Clear the text field
                    }
                  },
                  child: const Text('Add Member'),
                ),
              ],
            ),
          ),

          // Logout option
          ListTile(
            title: const Text('Logout'),
            onTap: () async {
              await _appService.logout();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => SignInScreen()));
            },
          ),

          // App Version Display
          const Spacer(), // Push the version info to the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('App Version: $_appVersion',
                style: const TextStyle(color: Colors.grey)),
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
                  await _appService.joinFamily(familyId: doc.id);
                  _adminEmailController.clear();
                  _familyIdController.clear(); // Clear the text fields
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
