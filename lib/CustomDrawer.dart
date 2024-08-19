import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For clipboard operations

class CustomDrawer extends StatefulWidget {
  final User user;
  final VoidCallback onSignOut;

  const CustomDrawer({
    super.key,
    required this.onSignOut,
    required this.user,
    required bool isAdmin, String? familyCode,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late Future<PackageInfo> _packageInfoFuture;
  bool _isAdmin = false;
  String? _familyCode;
  final TextEditingController _familyCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _isAdmin = userDoc['accountType'] == 'admin';
            _familyCode = userDoc['familyCode'];
          });
        } else {
          setState(() {
            _isAdmin = false;
            _familyCode = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _joinFamily() async {
    final code = _familyCodeController.text.trim();
    if (code.isNotEmpty) {
      try {
        final familyDoc = await FirebaseFirestore.instance
            .collection('families')
            .doc(code)
            .get();
        if (familyDoc.exists) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'familyCode': code});
            await FirebaseFirestore.instance
                .collection('families')
                .doc(code)
                .update({
              'members': FieldValue.arrayUnion([currentUser.uid]),
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joined family with code $code')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family code not found')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join family: $e')),
        );
      }
    }
  }

  Future<void> _copyCodeToClipboard(String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family code $code copied to clipboard')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy family code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Family Code'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: widget.onSignOut,
              ),
            ],
          ),
          if (_isAdmin && _familyCode != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share this code with your family members to let others join:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _familyCode!,
                    style: const TextStyle(fontSize: 24, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyCodeToClipboard(_familyCode!),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                  ),
                ],
              ),
            ),
          if (!_isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join a Family:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _familyCodeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter Family Code',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _joinFamily,
                    child: const Text('Join Family'),
                  ),
                ],
              ),
            )
          else if (_isAdmin && _familyCode == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Generating your family code...',
                  style: TextStyle(fontSize: 16)),
            ),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final packageInfo = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Version: ${packageInfo.version}'),
                    Text('Build Number: ${packageInfo.buildNumber}'),
                    Text('Package Name: ${packageInfo.packageName}'),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red button to indicate danger
              ),
              onPressed: _showDeleteAccountDialog,
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Remove user document from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .delete();

        // Remove the user from all family documents
        final families = FirebaseFirestore.instance.collection('families');
        final familyDocs = await families
            .where('members', arrayContains: currentUser.uid)
            .get();
        
        for (var doc in familyDocs.docs) {
          final members = List<dynamic>.from(doc.get('members'));
          members.remove(currentUser.uid);
          await doc.reference.update({'members': members});
        }

        // Delete the user's FirebaseAuth account
        await currentUser.delete();

        // Sign out and return to the login screen
        widget.onSignOut();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }
}
