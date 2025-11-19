import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/firebase_service.dart';
import 'mood_log_screen.dart';

class MoodListScreen extends StatelessWidget {
  MoodListScreen({super.key});

  final FirebaseService firebaseService = FirebaseService();
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  @override
  Widget build(BuildContext context) {
    final uid = firebaseService.currentUser!.uid;

    final moodsStream = firebaseService.db
        .collection('users')
        .doc(uid)
        .collection('moods')
        .orderBy('createdAt')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),
      body: SafeArea(
        child: StreamBuilder(
          stream: moodsStream,
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

                    // ----- HEADER (matches HabitListScreen exactly) -----
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
                                "Your Moods",
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
                        child: Text(
                          "No moods yet.\nAdd them on your phone!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            color: primaryColor,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: docs.map((mood) {
                          final name = mood['name'];
                          final iconPath = mood['iconPath'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
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
                                    builder: (_) => MoodLogScreen(
                                      moodId: mood.id,
                                      moodName: name,
                                      iconPath: iconPath,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    iconPath,
                                    width: 22,
                                    height: 22,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFFFD54F),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),
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
