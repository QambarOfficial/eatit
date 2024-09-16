import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'ChatScreen.dart';
import 'SearchScreen.dart';
import 'ProfileScreen.dart';

class HomeNavigationBar extends StatefulWidget {
  final User user; // User object passed from SignInScreen

  const HomeNavigationBar({super.key, required this.user});

  @override
  _HomeNavigationBarState createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar> {
  int _selectedIndex = 1; // Default to Search screen
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! < 0) {
            // Swiped left
            if (_selectedIndex < _widgetOptions.length - 1) {
              setState(() {
                _selectedIndex++;
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              });
            }
          } else if (details.primaryVelocity! > 0) {
            // Swiped right
            if (_selectedIndex > 0) {
              setState(() {
                _selectedIndex--;
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                );
              });
            }
          }
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _widgetOptions,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  // Define _widgetOptions with the ProfileScreen accepting the user object
  List<Widget> get _widgetOptions => <Widget>[
     const ChatScreen(),
    // SearchScreen(user: widget.user), // Pass the user object to SearchScreen
    const SearchScreen(),
    ProfileScreen(user: widget.user), // Pass the user object to ProfileScreen
  ];
}