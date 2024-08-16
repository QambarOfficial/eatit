import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'HomeNavigationBar.dart';

class SignInScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignInScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
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
          // Check if the user is already registered in Firestore
          DocumentSnapshot userDoc =
              await _firestore.collection('family').doc(user.uid).get();

          if (userDoc.exists) {
            // User is already registered, proceed with login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeNavigationBar(user: user)),
            );
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
                // Create a normal user account without family code
                await _createAccount(user, 'user');
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
                // Create an admin account with a family code
                await _createAccount(user, 'admin');
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

 Future<void> _createAccount(User user, String accountType) async {
  final String email = user.email ?? 'No email';
  final String displayName = user.displayName ?? 'No username';
  final String photoURL = user.photoURL ?? '';
  
  final String familyCode = accountType == 'admin' ? user.uid : '';
  
  // Save or update user details in Firestore
  await _firestore.collection('family').doc(user.uid).set({
    'email': email,
    'username': displayName,
    'photoURL': photoURL,
    'accountType': accountType,
    'createdAt': FieldValue.serverTimestamp(),
    'familyCode': familyCode,
  }, SetOptions(merge: true));
  
  // // If the user is an admin, create or update the admin document
  // if (accountType == 'admin') {
  //   await _firestore.collection('admins').doc(user.uid).set({
  //     'familyMembers': [], // Initialize with an empty list
  //   }, SetOptions(merge: true));
  // }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signInWithGoogle(context),
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
