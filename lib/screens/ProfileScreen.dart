import 'package:flutter/material.dart';
import 'CustomDrawer.dart';
import '../services/appService.dart'; // Assuming AppService is in this file

class ProfileScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  const ProfileScreen({super.key, required this.familyId, required this.familyName});  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final AppService _appService = AppService();
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _families = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchFamilies();
  }

  // Fetch user data using AppService
  Future<void> _fetchUserData() async {
    final user = _appService.auth.currentUser;
    if (user != null) {
      final userData = await _appService.getUserData(user.uid);
      setState(() {
        _userData = userData;
      });
    }
  }

  // Fetch families the user is part of using AppService
  void _fetchFamilies() {
    _appService.getFamilies().listen((families) {
      setState(() {
        _families = families;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      endDrawer: CustomDrawer(_families, _userData),
      body: _userData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Share Email To Let Others Join:\n${_userData?['email'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Family Members:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                ..._families.map((family) {
                  return FutureBuilder<List<Map<String, String>>>(
                    future: _appService.getFamilyMembers(family['familyId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No family members found.');
                      } else {
                        final members = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              tileColor: Colors.grey[200],
                              title: Text(
                                family['familyName'],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            ...members.map((member) {
                              return ListTile(
                                leading: member['photoURL'] != null
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(member['photoURL']!),
                                      )
                                    : const CircleAvatar(
                                        child: Icon(Icons.person),
                                      ),
                                title: Text(member['username']!),
                              );
                            }),
                          ],
                        );
                      }
                    },
                  );
                }),
              ],
            ),
    );
  }
}
