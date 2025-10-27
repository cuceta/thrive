import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  final List<String> prompts = [
    "What made you smile today?",
    "Describe a moment this week when you felt truly calm.",
    "What’s something you’re grateful for right now?",
    "How have you shown kindness recently?",
    "Write about a small win that made you proud.",
    "What’s a positive change you’d like to make this month?",
    "Describe a person who inspires you and why.",
    "What does self-care mean to you today?",
    "What’s something beautiful you noticed recently?",
    "How did you overcome a recent challenge?",
  ];

  String currentPrompt = "";
  String userAnswer = "";
  int wordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRandomPrompt();
  }

  void _loadRandomPrompt() {
    setState(() {
      currentPrompt = prompts[Random().nextInt(prompts.length)];
    });
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
                  SizedBox(height: 15),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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

  void _showAllEntriesPanel() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No user logged in")));
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('journalEntries')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final entries = snapshot.data!.docs;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ↓ Title row brought down a bit
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "All Entries",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: primaryColor),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),

                          // ↓ Entries aligned to the top
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 12),
                              itemCount:
                                  entries.length + 1, // +1 for footer text
                              itemBuilder: (context, index) {
                                // End of entries message
                                if (index == entries.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "— End of entries —",
                                        style: GoogleFonts.fredoka(
                                          fontSize: 13,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final entry = entries[index];
                                final formattedDate = DateFormat('MMMM d, y')
                                    .format(
                                      (entry['timestamp'] as Timestamp)
                                          .toDate(),
                                    );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color.fromARGB(
                                            255,
                                            22,
                                            22,
                                            22,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        entry['prompt'],
                                        style: GoogleFonts.fredoka(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry['answer'],
                                        style: GoogleFonts.fredoka(
                                          fontSize: 15,
                                          color: primaryColor,
                                        ),
                                      ),
                                      if (index != entries.length - 1)
                                        const Divider(
                                          thickness: 0.8,
                                          height: 20,
                                          color: Color.fromARGB(
                                            80,
                                            79,
                                            100,
                                            78,
                                          ), // subtle greenish grey line
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1, 0), // slides in from right
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 217, 251, 229),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              // Title
              // 🌟 Title + two random stars
Stack(
  clipBehavior: Clip.none,
  children: [
    // Column for the original text layout (unchanged)
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  Journal",
          style: GoogleFonts.fredoka(
            color: accentColor,
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          "    Reflect and grow through writing",
          style: GoogleFonts.fredoka(
            color: accentColor,
            fontSize: 16,
            fontWeight: FontWeight.w100,
          ),
        ),
      ],
    ),

    //  First random star (top right of “Journal”)
    Positioned(
      top: -10,
      right: 233,
      child:  
      SvgPicture.asset(
          'assets/images/star.svg',
          color: const Color.fromARGB(255, 236, 165, 84),
          width: 30,
          height: 30,
        
      ),
    ),

    // Second random star (bottom left of subtitle)
    Positioned(
      bottom: 25,
      left: 290,
      child: 
       SvgPicture.asset(
          'assets/images/star.svg',
          color: const Color.fromARGB(255, 236, 165, 84),
          width: 20,
          height: 20,
        
      ),
    ),
  ],
),

              const SizedBox(height: 40),

              // Prompt Section
              Container(
                padding: const EdgeInsets.all(16),
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
                        ElevatedButton.icon(
                          onPressed: _loadRandomPrompt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              233,
                              238,
                              235,
                            ),
                            side: const BorderSide(
                              color: Color.fromARGB(
                                255,
                                181,
                                200,
                                189,
                              ), // Border color
                              width: 0.5, // Border width
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
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _showEntryDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              233,
                              238,
                              235,
                            ),
                            side: const BorderSide(
                              color: Color.fromARGB(
                                255,
                                181,
                                200,
                                189,
                              ), // Border color
                              width: 0.5, // Border width
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
                            "Answer Prompt",
                            style: GoogleFonts.fredoka(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 252, 252, 252),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(114, 79, 100, 78),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Entries
                    Text(
                      "Recent Entries",
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('journalEntries')
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final entries = snapshot.data!.docs;
                        if (entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "No journal entries yet.",
                              style: GoogleFonts.fredoka(color: Colors.grey),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (var entry in entries)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🗓️ Nicely formatted date
                                    Text(
                                      DateFormat('MMMM d, y').format(
                                        (entry['timestamp'] as Timestamp)
                                            .toDate(),
                                      ),
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color.fromARGB(
                                          255,
                                          22,
                                          22,
                                          22,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      entry['prompt'],
                                      style: GoogleFonts.fredoka(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry['answer'],
                                      style: GoogleFonts.fredoka(
                                        fontSize: 15,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            ElevatedButton(
                              onPressed: _showAllEntriesPanel,
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
                              child: Text(
                                "See all entries",
                                style: GoogleFonts.fredoka(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
