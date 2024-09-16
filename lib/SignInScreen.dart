import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import the package
import 'HomeNavigationBar.dart';
import 'appService.dart'; // Use the new consolidated service

class SignInScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppService _appService = AppService(); // Initialize AppService

  SignInScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Sign out of any existing Google account before signing in again
      await _googleSignIn.signOut();
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // Check if the user is already registered using AppService
          final userDoc = await _appService.getUserData(user.uid);

          if (userDoc != null) {
            // User is already registered, prompt to continue or delete account
            _showExistingAccountDialog(context, user);
          } else {
            // User is not registered, prompt to set up a new account
            _showAccountSetupDialog(context, user);
          }
        } else {
          // Handle the case where the user is null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Display an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  void _showExistingAccountDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: const Text('An account with this email already exists. Choose an option:'),
          actions: [
            TextButton(
              onPressed: () async {
                // Delete the previous account using AppService and set up a new account
                await _appService.deleteUserAccount(user.uid);
                Navigator.pop(context); // Close the dialog
                _showAccountSetupDialog(context, user);
              },
              child: const Text('Delete Previous Account and Set Up New'),
            ),
            TextButton(
              onPressed: () async {
                // Continue with the old account
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeNavigationBar(user: user)),
                );
              },
              child: const Text('Continue with Existing Account'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the user's account and navigate back to the login screen
                await user.delete();
                Navigator.pop(context); // Close the dialog
                _googleSignIn.signOut(); // Sign out of Google
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SignInScreen()), // Go back to login screen
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAccountSetupDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set up your account'),
          content: const Text('Choose your account type:'),
          actions: [
            TextButton(
              onPressed: () async {
                // Create a normal user account using AppService
                await _appService.createAccount(user.uid, user.email ?? '', user.displayName ?? '', user.photoURL ?? '', 'user');
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeNavigationBar(user: user)),
                );
              },
              child: const Text('Normal User'),
            ),
            TextButton(
              onPressed: () async {
                // Create an admin account using AppService
                await _appService.createAccount(user.uid, user.email ?? '', user.displayName ?? '', user.photoURL ?? '', 'admin');
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeNavigationBar(user: user)),
                );
              },
              child: const Text('Admin'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the user's account and navigate back to the login screen
                await user.delete();
                Navigator.pop(context); // Close the dialog
                _googleSignIn.signOut(); // Sign out of Google
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SignInScreen()), // Go back to login screen
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _signInWithGoogle(context),
              child: const Text('Sign in with Google'),
            ),
            FutureBuilder<String>(
              future: _getAppVersion(), // Fetch the app version
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error fetching version');
                } else if (snapshot.hasData) {
                  return Text('App Version: ${snapshot.data}', style: const TextStyle(fontSize: 16));
                } else {
                  return const Text('App Version: Unknown', style: TextStyle(fontSize: 16));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
