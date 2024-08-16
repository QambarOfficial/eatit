# eatit
Eatit is your ultimate kitchen companion, designed specifically for home chefs. 
This intuitive app takes the guesswork out of meal planning, helping you decide what's for breakfast, lunch, and dinner with ease.
Whether you're cooking for yourself, your family, or hosting a dinner party, Menu Maestro ensures every meal is a masterpiece.

Changelog

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
