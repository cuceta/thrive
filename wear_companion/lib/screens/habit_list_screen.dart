import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/firebase_service.dart';
import 'habit_log_screen.dart';
import 'package:intl/intl.dart';

class HabitListScreen extends StatelessWidget {
  HabitListScreen({super.key});

  final FirebaseService firebaseService = FirebaseService();
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  @override
  Widget build(BuildContext context) {
    final uid = firebaseService.currentUser?.uid;
    final habitsStream = firebaseService.db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .orderBy('createdAt')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),

      body: SafeArea(
        child: StreamBuilder(
          stream: habitsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 15),
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/back-arrow.svg',
                                    width: 18,
                                    height: 18,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Your Habits",
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 10),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    if (docs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            "No habits yet.\nAdd them on your phone!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: docs.map((habit) {
                          final name = habit['name'];
                          final icon = habit['iconPath'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  233,
                                  238,
                                  235,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 181, 200, 189),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HabitLogScreen(
                                      habitId: habit.id,
                                      habitName: name,
                                      iconPath: icon,
                                    ),
                                  ),
                                );
                              },
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SvgPicture.asset(
                                          icon,
                                          width: 22,
                                          height: 22,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          // important: prevents right overflow
                                          child: Text(
                                            name,
                                            style: GoogleFonts.fredoka(
                                              fontSize: 16,
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow:
                                                TextOverflow.ellipsis, // safety
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
