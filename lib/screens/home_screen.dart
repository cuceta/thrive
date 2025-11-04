import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/bottom_nav.dart';
import 'home.dart';
import 'Habit.dart';
import 'Mood.dart';
import 'Journal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // ✅ Pass the navigation callback to Home so it can switch tabs
    _pages = [
      Home(onNavigateToTab: _onNavTapped),
      Habit(),
      Mood(),
      Journal(),
    ];
  }

  // Handle nav bar taps and home-page tab switches
  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Confirmation dialog for Sign Out
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Color.fromARGB(255, 49, 80, 47),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color.fromARGB(255, 246, 251, 245),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.fredoka(
            color: const Color.fromARGB(255, 49, 80, 47),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(), // close dialog
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 233, 238, 235),
              side: const BorderSide(
                color: Color.fromARGB(255, 181, 200, 189),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(
                color: const Color.fromARGB(255, 79, 100, 78),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(235, 96, 57, 1),
              side: const BorderSide(
                color: Color.fromARGB(255, 181, 200, 189),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Sign out',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 249, 230),
      body: Stack(
        children: [
          // Main content (current tab)
          Positioned.fill(
            child: _pages[_selectedIndex],
          ),

          // Floating Sign-out button (top-right corner)
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: _confirmLogout,
              child: SvgPicture.asset(
                'assets/icons/sign-out-icon.svg',
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 49, 80, 47),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),

      //  Bottom navigation bar (stays always visible)
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
