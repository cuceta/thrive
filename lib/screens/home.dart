import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  final void Function(int)? onNavigateToTab; // <— add this

  const Home({super.key, this.onNavigateToTab}); 

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  AnimationController? _pulse;
  Animation<double>? _pulseAnim;

  List<String> prompts = [];
  String currentPrompt = "";
  String userAnswer = "";
  int wordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPrompts();

    // Initialize safely
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulse!, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  // -------------------- JOURNAL PROMPTS --------------------
  Future<void> _loadPrompts() async {
    final text = await rootBundle.loadString(
      'assets/prompts/journal_prompts.txt',
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

  // -------------------- TODAY GARDEN --------------------
  Widget _todayGarden(List<DocumentSnapshot> habits) {
    final today = DateTime.now();
    final dayId = DateFormat('yyyy-MM-dd').format(today);

    return FutureBuilder<Map<String, double>>(
      future: () async {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final map = <String, double>{};
        for (final h in habits) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('habits')
              .doc(h.id)
              .collection('logs')
              .doc(dayId)
              .get();
          map[h.id] = (doc.data()?['completion'] ?? 0.0).toDouble();
        }
        return map;
      }(),
      builder: (context, snapshot) {
        final values = snapshot.data ?? {};
        final random = Random(today.millisecondsSinceEpoch);
        const plantWidth = 48.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final count = habits.length;
            if (count == 0) {
              return Center(
                child: Text(
                  "No habits yet 🌱",
                  style: GoogleFonts.fredoka(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            double spacing = count <= 5
                ? 20
                : count <= 8
                ? 5
                : -15;
            final totalWidth = count * plantWidth + (count - 1) * spacing;
            final startX = (width - totalWidth) / 2;

            return SizedBox(
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  for (int i = 0; i < count; i++)
                    Builder(
                      builder: (context) {
                        final h = habits[i];
                        final icon = h['iconPath'] as String;
                        final val = values[h.id] ?? 0.0;
                        final opacity = (0.1 + 0.9 * val).clamp(0.1, 1.0);
                        final wobbleX = (random.nextDouble() - 0.5) * 4;
                        final wobbleY = random.nextDouble() * 5;
                        final left =
                            startX + i * (plantWidth + spacing) + wobbleX;

                        final plant = SvgPicture.asset(
                          icon,
                          width: plantWidth,
                          height: plantWidth,
                        );

                        //  Animate only 100%-complete plants
                        final animatedPlant = val == 1.0 && _pulseAnim != null
                            ? ScaleTransition(
                                scale: Tween(
                                  begin: 1.0,
                                  end: 1.06,
                                ).animate(_pulseAnim!),
                                child: plant,
                              )
                            : plant;

                        return Positioned(
                          bottom: 18 + wobbleY,
                          left: left,
                          child: Opacity(
                            opacity: opacity,
                            child: animatedPlant,
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------- BUILD --------------------
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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

              const SizedBox(height: 30),

              //  Journal Prompt
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  233,
                                  238,
                                  235,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showEntryDialog,
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  233,
                                  238,
                                  235,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Today's Habits Summary
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('habits')
                    .snapshots(),
                builder: (context, habitsSnap) {
                  if (!habitsSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final habits = habitsSnap.data!.docs;
                  if (habits.isEmpty) return const SizedBox();

                  final todayId = DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.now());

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait(
                      habits.map((h) async {
                        final logRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('habits')
                            .doc(h.id)
                            .collection('logs')
                            .doc(todayId)
                            .get();
                        return logRef;
                      }),
                    ),
                    builder: (context, logSnaps) {
                      if (!logSnaps.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final completed = logSnaps.data!
                          .where(
                            (d) =>
                                d.exists &&
                                ((d.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >?)?['completion'] ??
                                        0) ==
                                    1.0,
                          )
                          .length;
                      final total = habits.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary container
                          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Today's Habits card (clickable)
    Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onNavigateToTab?.call(1), // Habit tab
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(right: 10),
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
                "Today's Habits:",
                style: GoogleFonts.fredoka(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "$completed / $total",
                style: GoogleFonts.fredoka(
                  color: primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Grow your garden by checking off habits",
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),

    // Moods card (clickable)
    Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onNavigateToTab?.call(2), // Mood tab
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(left: 10),
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
                "Moods",
                style: GoogleFonts.fredoka(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Log your mood to create your star constellations",
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
  ],
),

                          const SizedBox(height: 20),

                          //  Today's Garden section with title + grey container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromARGB(114, 79, 100, 78),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Garden",
                                  style: GoogleFonts.fredoka(
                                    color: primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      233,
                                      238,
                                      235,
                                    ), // light grey background
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: _todayGarden(habits),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
