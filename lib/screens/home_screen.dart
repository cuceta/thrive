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
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [Home(), Habit(), Mood(), Journal()];

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Confirmation dialog
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: const Color.fromARGB(255, 49, 80, 47),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color.fromARGB(255, 246, 251, 245),
        // backgroundColor: Colors.grey,
        // title: const Text('Sign Out'),
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
              // textStyle: const TextStyle(fontSize: 32),
              side: BorderSide(
                color: const Color.fromARGB(255, 181, 200, 189), 
                width: 1.5, 
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), 
              ),
            ),

            child: Text('Cancel',
            style: GoogleFonts.fredoka(
              color: const Color.fromARGB(255, 79, 100, 78),
              fontSize: 16,
            ),
            ),
          ),
          const SizedBox(width: 16.0),
          ElevatedButton(
            // style: ElevatedButton.styleFrom(
            //   backgroundColor: const Color.fromRGBO(235, 96, 57, 1),
              
            // ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(235, 96, 57, 1),
              // textStyle: const TextStyle(fontSize: 32),

              side: BorderSide(
                color: const Color.fromARGB(255, 181, 200, 189), 
                width: 1.5, 
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), 
              ),
            ),
            child: Text('Sign out',
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
          // Main content (current page)
          Positioned.fill(child: _pages[_selectedIndex]),

          // Floating sign-out icon
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
                  const Color.fromARGB(255, 49, 80, 47),
                  BlendMode.srcIn,
                ),
                // color: const Color.fromARGB(255, 49, 80, 47),
              ),
            ),
          ),
        ],
      ),

      // Bottom nav still stays
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}
