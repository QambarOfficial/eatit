import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CustomDrawer extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> contactsFuture;
  final Function(Map<String, dynamic>) onAddFamilyMember;
  final Function(String) onFilterContacts;
  final String searchQuery;
  final VoidCallback onSignOut;

  const CustomDrawer({
    super.key,
    required this.contactsFuture,
    required this.onAddFamilyMember,
    required this.onFilterContacts,
    required this.searchQuery,
    required this.onSignOut,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform(); // Initialize app info fetch
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Contacts'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: widget.onSignOut,
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
              onChanged: widget.onFilterContacts,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No contacts found.'));
                }

                final contacts = widget.searchQuery.isEmpty
                    ? snapshot.data!
                    : snapshot.data!.where((contact) {
                        final name = contact['name']?.toLowerCase() ?? '';
                        final email = contact['email']?.toLowerCase() ?? '';
                        return name.contains(widget.searchQuery) || email.contains(widget.searchQuery);
                      }).toList();

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
                        widget.onAddFamilyMember(contact);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
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
        ],
      ),
    );
  }
}
