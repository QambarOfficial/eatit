import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'CustomDrawer.dart';
import 'SignInScreen.dart';
import 'user_service.dart'; // Import the user service
import 'family_service.dart'; // Import the family service

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final FamilyService _familyService = FamilyService();
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isAdmin = false;
  String? _familyCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = widget.user.uid;
    final userData = await _userService.getUserData(uid);

    if (userData != null) {
      setState(() {
        _isAdmin = userData['accountType'] == 'admin';
        _familyCode = userData['familyCode'];
      });

      if (_familyCode != null) {
        _fetchFamilyMembers();
      }
    }
  }

  Future<void> _fetchFamilyMembers() async {
    if (_familyCode != null) {
      final familyData = await _familyService.getFamilyData(_familyCode!);

      if (familyData != null) {
        final memberIds = List<String>.from(familyData['members'] ?? []);
        final List<Map<String, dynamic>> members = [];

        for (String memberId in memberIds) {
          final userData = await _userService.getUserData(memberId);
          if (userData != null) {
            members.add({
              'uid': memberId,
              'username': userData['username'],
              'email': userData['email'],
              'photoURL': userData['photoURL'],
              'tag': userData['tag'] ?? 'User', // Default to 'User' if no tag
            });
          }
        }

        setState(() {
          _familyMembers = members;
        });
      }
    }
  }

  Future<void> _removeFamilyMember(String memberId) async {
    if (_isAdmin && _familyCode != null) {
      await _familyService.updateFamilyMembers(_familyCode!, memberId);
      setState(() {
        _familyMembers.removeWhere((member) => member['uid'] == memberId);
      });
    }
  }

  Future<void> _assignTag(String memberId, String tag) async {
    if (_isAdmin && _familyCode != null) {
      try {
        await _userService.updateUserTag(memberId, tag);
        setState(() {
          final member = _familyMembers.firstWhere((m) => m['uid'] == memberId);
          member['tag'] = tag;
        });
      } catch (e) {
        print('Error assigning tag: $e');
      }
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: CustomDrawer(
        user: widget.user,
        onSignOut: () => _signOut(context),
        isAdmin: _isAdmin,
        familyCode: _familyCode,
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
            Text('Name: ${widget.user.displayName ?? 'No Name'}', style: const TextStyle(fontSize: 20)),
            Text('Email: ${widget.user.email ?? 'No Email'}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            const Text('Family Members:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _familyMembers.length,
                itemBuilder: (context, index) {
                  final member = _familyMembers[index];
                  final currentTag = member['tag'] ?? 'User'; // Default to 'User'

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['photoURL'] != null && member['photoURL'] != ''
                          ? NetworkImage(member['photoURL'])
                          : null,
                      child: member['photoURL'] == null || member['photoURL'] == ''
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(member['username'] ?? 'No Name'),
                    subtitle: Text(member['email'] ?? 'No Email'),
                    trailing: _isAdmin
                        ? (currentTag == 'Admin'
                            ? Text(currentTag, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                            : DropdownButton<String>(
                                value: currentTag, // Ensure the value is valid
                                items: ['User', 'Cook'].map((tag) {
                                  return DropdownMenuItem<String>(
                                    value: tag,
                                    child: Text(tag),
                                  );
                                }).toList(),
                                onChanged: (String? newTag) {
                                  if (newTag != null) {
                                    _assignTag(member['uid'], newTag);
                                  }
                                },
                              ))
                        : Text(
                            currentTag,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
