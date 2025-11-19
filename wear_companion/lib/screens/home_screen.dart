import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wear_companion/screens/habit_list_screen.dart';
import 'package:wear_companion/screens/mood_list_screen.dart';
import '../core/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService firebaseService = FirebaseService();
  String? firstName;
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = firebaseService.currentUser;
    if (user != null && user.displayName != null) {
      setState(() {
        firstName = user.displayName!.split(' ').first;
      });
    } else {
      setState(() {
        firstName = 'Friend';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hey, ${firstName ?? '...'}!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            // Buttons
            _buildMenuButton(
              iconPath: 'assets/icons/habit-icon.svg',
              label: 'Log Habit',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HabitListScreen()),
                );
              },
            ),
            // const SizedBox(height: 5),
            _buildMenuButton(
              iconPath: 'assets/icons/mood-icon.svg',
              label: 'Log Mood',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MoodListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 233, 238, 235),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(
            color: Color.fromARGB(255, 181, 200, 189),
            width: 1.0,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            color: const Color.fromARGB(255, 49, 80, 47),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
