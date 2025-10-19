import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';
    final firstName = fullName.split(' ').first;
    final name =
        firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 217, 251, 229),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/joey.GIF',
                fit: BoxFit.cover,
                width: 370,
                height: 370,
              ),
              Center(
                child: Text(
                  "Welcomed back, $name!",
                  style: GoogleFonts.fredoka(
                    // top: ,
                    fontSize: 40,
                    color: const Color.fromARGB(255, 235, 96, 57),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
