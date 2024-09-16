# eatit
Eatit is your ultimate kitchen companion, designed specifically for home chefs. 
This intuitive app takes the guesswork out of meal planning, helping you decide what's for breakfast, lunch, and dinner with ease.
Whether you're cooking for yourself, your family, or hosting a dinner party, Menu Maestro ensures every meal is a masterpiece.

Changelog

[v1.7.9]
App Verison on singin screen as well
userService deleted
familyService deleted
appServie added


[v1.7.8]

Chat scoket implimented with firestore
Delete member function reintroduced with firestore connection
Drawer moved to right






[v1.7.7]

Family List created
Tags Introduced
Delete member function removed temporarily






[v1.7.6]

ProfileScreen.dart: Updated to include photo URLs and handle null values.
SignInScreen.dart: Updated to ensure photo URLs are handled and family documents are created correctly.





[v1.7.5]

Updated _createAccount Method:

Before: The _createAccount method did not accept BuildContext as a parameter, leading to issues accessing context within it.
After: Modified the _createAccount method to include BuildContext as a parameter. This allows for displaying SnackBars or other UI elements based on the result of the Firestore query.
Added Email Existence Check:

Before: There was no check to prevent creating multiple accounts with the same email.
After: Implemented a check to query Firestore for existing documents with the same email before creating a new account. If an account with the same email already exists, a SnackBar is shown to inform the user.
Passed BuildContext to _createAccount:

Before: The context parameter was not available in the _createAccount method, which could lead to issues with UI updates.
After: Passed BuildContext from _showAccountSetupDialog when calling _createAccount, ensuring that UI elements like SnackBars can be used correctly.
Updated Navigator.pushReplacement Calls:

Before: Navigation was handled directly in the dialog actions.
After: Ensured navigation is handled appropriately after creating or setting up the account, ensuring the user is directed to the correct screen based on the account type.
General Updates
Error Handling and User Feedback:

Improved error handling and user feedback by using ScaffoldMessenger.of(context).showSnackBar to display relevant messages in case of sign-in or account creation failures.
Added error handling for null user scenarios and improved messaging for sign-in failures.
Updated Firestore Document Paths:

Corrected the Firestore document paths to align with the intended structure, ensuring proper user and family document updates.


[v1.7.3]
Firestore user/admin subtype added.
admin_dialog file deleted


[v1.7.2]
Added App Info Section: A new section was added to the CustomDrawer to display app information.
Dependencies: Added package_info_plus package to fetch app details.
App Info Displayed:
App Version
Build Number
Package Name
UI Enhancements:
Added a Divider to separate the app info section from the rest of the drawer content.
Refactored Drawer:
Extracted drawer functionality into a separate CustomDrawer widget.
Passed contactsFuture, onAddFamilyMember, onFilterContacts, searchQuery, and onSignOut as parameters to CustomDrawer.
Updated the ProfileScreen to use CustomDrawer for improved modularity and code organization.
