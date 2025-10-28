import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Habit extends StatefulWidget {
  const Habit({super.key});

  @override
  State<Habit> createState() => _HabitState();
}

class _HabitState extends State<Habit> {
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  String selectedView = "Daily"; // default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // 🌼 Title section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "  Habit Garden",
                        style: GoogleFonts.fredoka(
                          color: accentColor,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "    Build your garden, one habit at a time",
                        style: GoogleFonts.fredoka(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                    ],
                  ),

                  // ✨ decorative stars (optional, same style as others)
                  Positioned(
                    top: -15,
                    left: 0,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 30,
                      height: 30,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 17,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 20,
                      height: 20,
                    ),
                  ),
                  Positioned(
                    top: 32,
                    right: 10,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 15,
                      height: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Toggle bar (Daily / Weekly / Monthly)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ["Daily", "Weekly", "Monthly"].map((option) {
                    final bool isSelected = selectedView == option;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedView = option);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // Placeholder for the garden view
              Expanded(
                child: Center(
                  child: Text(
                    "$selectedView Garden View Coming Soon 🌸",
                    style: GoogleFonts.fredoka(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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
