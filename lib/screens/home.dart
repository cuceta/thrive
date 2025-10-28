import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  List<String> prompts = [];
  String currentPrompt = "";
  String userAnswer = "";
  int wordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    final text = await rootBundle.loadString(
      'assets/journalPrompts/journal_prompts.txt',
    );
    setState(() {
      prompts = text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      _loadRandomPrompt();
    });
  }

  void _loadRandomPrompt() {
    if (prompts.isNotEmpty) {
      setState(() {
        currentPrompt = prompts[Random().nextInt(prompts.length)];
      });
    }
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || userAnswer.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('journalEntries')
        .add({
          'prompt': currentPrompt,
          'answer': userAnswer.trim(),
          'timestamp': Timestamp.now(),
        });

    setState(() {
      userAnswer = "";
      wordCount = 0;
    });
  }

  void _showEntryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryColor, width: 2),
          ),
          title: Text(
            "Tell me all about it...",
            style: GoogleFonts.fredoka(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentPrompt,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    maxLines: 5,
                    cursorColor: Colors.grey,
                    onChanged: (val) {
                      setState(() {
                        userAnswer = val;
                        wordCount = val.trim().isEmpty
                            ? 0
                            : val.trim().split(RegExp(r'\s+')).length;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Write your thoughts...",
                      hintStyle: GoogleFonts.fredoka(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: GoogleFonts.fredoka(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "$wordCount words",
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: primaryColor, width: 0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.fredoka(color: primaryColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                await _saveEntry();
                Navigator.pop(context);
              },
              child: Text(
                "Save Entry",
                style: GoogleFonts.fredoka(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';
    final firstName = fullName.split(' ').first;
    final name =
        firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero image and stars (unchanged)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/joey.GIF',
                        fit: BoxFit.cover,
                        width: 370,
                        height: 370,
                      ),
                      Center(
                        child: Text(
                          "Welcome back, $name!",
                          style: GoogleFonts.fredoka(
                            fontSize: 40,
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 30,
                    left: 10,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 35,
                      height: 35,
                    ),
                  ),
                  Positioned(
                    top: 25,
                    left: -5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 15,
                      height: 15,
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 10,
                      height: 10,
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: -5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 35,
                      height: 35,
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: 30,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 15,
                      height: 15,
                    ),
                  ),
                  Positioned(
                    top: 145,
                    right: 25,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      color: const Color.fromARGB(255, 236, 165, 84),
                      width: 10,
                      height: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Prompt section (scrollable-safe now)
              if (currentPrompt.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 181, 209, 192),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromARGB(114, 79, 100, 78),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tell me about it...",
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentPrompt,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: primaryColor,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadRandomPrompt,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  233,
                                  238,
                                  235,
                                ),
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 181, 200, 189),
                                  width: 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: SvgPicture.asset(
                                'assets/journal/reload.svg',
                                color: primaryColor,
                                width: 13,
                                height: 13,
                              ),
                              label: Text(
                                "New Prompt",
                                style: GoogleFonts.fredoka(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showEntryDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  233,
                                  238,
                                  235,
                                ),
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 181, 200, 189),
                                  width: 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: SvgPicture.asset(
                                'assets/journal/pencil.svg',
                                color: primaryColor,
                                width: 19,
                                height: 19,
                              ),
                              label: Text(
                                "Answer",
                                style: GoogleFonts.fredoka(color: primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
