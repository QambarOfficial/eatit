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
          // Check if the user is already registered in Firestore
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
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
                // Delete the previous account and set up a new account
                await _deleteExistingAccount(user);
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

  Future<void> _deleteExistingAccount(User user) async {
    // Remove user document from Firestore
    await _firestore.collection('users').doc(user.uid).delete();
    
    // Remove family document if the user was an admin
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final String familyCode = userDoc.get('familyCode');
      if (familyCode.isNotEmpty) {
        await _firestore.collection('families').doc(familyCode).delete();
      }
    }
    
    // Optionally, delete the user from Firebase Authentication
    await user.delete();
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
                await _createAccount(context, user, 'user');
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
                await _createAccount(context, user, 'admin');
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

  Future<void> _createAccount(BuildContext context, User user, String accountType) async {
    final String email = user.email ?? 'No email';
    final String displayName = user.displayName ?? 'No username';
    final String photoURL = user.photoURL ?? ''; // Default to empty string

    final String familyCode = accountType == 'admin' ? user.uid : '';

    // Check if a user with the same email already exists
    final querySnapshot = await _firestore.collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      // User with this email already exists
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An account with this email already exists')),
      );
      return;
    }

    // Save or update user details in Firestore
   await _firestore.collection('users').doc(user.uid).set({
  'email': email,
  'username': displayName,
  'photoURL': photoURL, // Ensure this is handled
  'accountType': accountType,
  'createdAt': FieldValue.serverTimestamp(),
  'familyCode': familyCode,
}, SetOptions(merge: true));

if (accountType == 'admin') {
  // Create a new family document
  await _firestore.collection('families').doc(familyCode).set({
    'adminId': user.uid,
    'familyCode': familyCode,
    'members': [user.uid], // Initialize with the admin as the first member
  });
} else {
  // Update the existing family document to include the new member
  await _firestore.collection('families').doc(familyCode).update({
    'members': FieldValue.arrayUnion([user.uid]), // Add the user to the members list
  });
}

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
