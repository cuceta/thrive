import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const Home({super.key, this.onNavigateToTab});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  // --- Colors ---
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  // --- Animations ---
  AnimationController? _pulse;
  Animation<double>? _pulseAnim;
  late AnimationController _starController;

  // --- Journal State ---
  List<String> prompts = [];
  String currentPrompt = "";
  String userAnswer = "";
  int wordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPrompts();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(parent: _pulse!, curve: Curves.easeInOut);

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse?.dispose();
    _starController.dispose();
    super.dispose();
  }

  // ============================================================
  //                     JOURNAL PROMPTS
  // ============================================================

  Future<void> _loadPrompts() async {
    final text =
        await rootBundle.loadString('assets/prompts/journal_prompts.txt');

    setState(() {
      prompts =
          text.split('\n').where((line) => line.trim().isNotEmpty).toList();
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
        return StatefulBuilder(
          builder: (context, setState) {
            final bool overLimit = wordCount >= 5000;

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
              content: Column(
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
                      final words = val.trim().isEmpty
                          ? 0
                          : val.trim().split(RegExp(r'\s+')).length;

                      if (words > 5000) return;

                      setState(() {
                        userAnswer = val;
                        wordCount = words;
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

                  if (overLimit)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Word limit reached (5000 words)",
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

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
                  onPressed: wordCount == 0
                      ? null
                      : () async {
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
      },
    );
  }

  // ============================================================
  //                       EMPTY SECTIONS
  // ============================================================

  Widget _emptyHabitsCard() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: _sectionBoxDecoration(),
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
            "0 / 0",
            style: GoogleFonts.fredoka(
              color: primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add habits to start your garden 🌱",
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: primaryColor,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMoodsCard() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: _sectionBoxDecoration(),
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
          const SizedBox(height: 6),
          Text(
            "Add moods to build your constellations ✨",
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: primaryColor,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyGardenSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _outerCardDecoration(),
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
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 233, 238, 235),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "No habits yet 🌱",
                style: GoogleFonts.fredoka(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMoodGalaxySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _outerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mood Galaxy",
            style: GoogleFonts.fredoka(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 233, 238, 235),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "No moods yet 🌙",
                style: GoogleFonts.fredoka(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //                         GARDEN SECTION
  // ============================================================

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
                        color: const Color.fromARGB(255, 116, 66, 42),
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

                        final animatedPlant =
                            val == 1.0 && _pulseAnim != null
                                ? ScaleTransition(
                                    scale: Tween(begin: 1.0, end: 1.06)
                                        .animate(_pulseAnim!),
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

  // ============================================================
  //                        DECORATIONS
  // ============================================================

  BoxDecoration _sectionBoxDecoration() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 181, 209, 192),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color.fromARGB(114, 79, 100, 78),
        width: 1,
      ),
    );
  }

  BoxDecoration _outerCardDecoration() {
    return BoxDecoration(
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
    );
  }

  // ============================================================
  //                      MOOD GALAXY SECTION
  // ============================================================

  Widget _homeMoodGalaxy(Animation<double> animation) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final past7Days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('moods')
          .orderBy('createdAt')
          .get(),
      builder: (context, moodsSnap) {
        if (!moodsSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final moods = moodsSnap.data!.docs;

        if (moods.isEmpty) {
          return Center(
            child: Text(
              "No moods logged yet 🌙",
              style: GoogleFonts.fredoka(
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return FutureBuilder<List<QuerySnapshot>>(
          future: Future.wait(
            moods.map((m) {
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('moods')
                  .doc(m.id)
                  .collection('logs')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo:
                        Timestamp.fromDate(past7Days.first),
                  )
                  .get();
            }),
          ),
          builder: (context, logsSnap) {
            if (!logsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<Map<String, dynamic>> points = [];

            for (int mi = 0; mi < moods.length; mi++) {
              final mood = moods[mi];
              final iconPath = mood['iconPath'] as String;
              final logs = logsSnap.data![mi].docs;

              for (int di = 0; di < past7Days.length; di++) {
                final day = past7Days[di];
                final dayLogs = logs.where((doc) {
                  final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                  return ts != null &&
                      ts.year == day.year &&
                      ts.month == day.month &&
                      ts.day == day.day;
                }).toList();

                if (dayLogs.isEmpty) continue;

                final avg = dayLogs
                        .map((d) => (d['level'] as num).toDouble())
                        .reduce((a, b) => a + b) /
                    dayLogs.length;

                points.add({
                  'x': di,
                  'y': avg,
                  'iconPath': iconPath,
                });
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = 180.0;
                final cellWidth = width / 7;
                final chartHeight = height - 25;

                return SizedBox(
                  height: height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _YellowStarsPainter(
                                offset: animation.value,
                              ),
                            );
                          },
                        ),
                      ),

                      for (final p in points)
                        Positioned(
                          left: p['x'] * cellWidth + cellWidth / 2 - 14,
                          top: chartHeight -
                              (p['y'] / 10) * chartHeight,
                          child: SvgPicture.asset(
                            p['iconPath'],
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFFFD54F),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),

                      for (int i = 0; i < 7; i++)
                        Positioned(
                          left: cellWidth * i,
                          bottom: 4,
                          width: cellWidth,
                          child: Center(
                            child: Text(
                              DateFormat('E').format(past7Days[i]),
                              style: GoogleFonts.fredoka(
                                color: primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  //                         BUILD()
  // ============================================================

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
              // HEADER ---------------------------------------------------------
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/joey.GIF',
                        width: 370,
                        height: 370,
                        fit: BoxFit.cover,
                      ),
                      Text(
                        "Welcome back, $name!",
                        style: GoogleFonts.fredoka(
                          fontSize: 40,
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  // Star decorations
                  Positioned(
                    top: 30,
                    left: 10,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 35,
                      height: 35,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                  Positioned(
                    top: 25,
                    left: -5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 15,
                      height: 15,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 10,
                      height: 10,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: -5,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 35,
                      height: 35,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: 30,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 15,
                      height: 15,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                  Positioned(
                    top: 145,
                    right: 25,
                    child: SvgPicture.asset(
                      'assets/images/star.svg',
                      width: 10,
                      height: 10,
                      color: const Color.fromARGB(255, 236, 165, 84),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // JOURNAL -------------------------------------------------------
              if (currentPrompt.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: _sectionBoxDecoration(),
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
                          // New Prompt Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadRandomPrompt,
                              icon: SvgPicture.asset(
                                'assets/journal/reload.svg',
                                width: 13,
                                height: 13,
                                color: primaryColor,
                              ),
                              label: Text(
                                "New Prompt",
                                style: GoogleFonts.fredoka(
                                  color: primaryColor,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 233, 238, 235),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Answer Prompt Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showEntryDialog,
                              icon: SvgPicture.asset(
                                'assets/journal/pencil.svg',
                                width: 19,
                                height: 19,
                                color: primaryColor,
                              ),
                              label: Text(
                                "Answer",
                                style: GoogleFonts.fredoka(
                                  color: primaryColor,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 233, 238, 235),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // HABITS + GARDEN ------------------------------------------------
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('habits')
                    .snapshots(),
                builder: (context, habitsSnap) {
                  if (!habitsSnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final habits = habitsSnap.data!.docs;

                  // EMPTY USER STATE
                  if (habits.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _emptyHabitsCard()),
                            const SizedBox(width: 20),
                            Expanded(child: _emptyMoodsCard()),
                          ],
                        ),
                        // const SizedBox(height: 20),
                        const SizedBox(height: 20),
                        _emptyGardenSection(),
                        const SizedBox(height: 20),
                        _emptyMoodGalaxySection(),
                      ],
                    );
                  }

                  // USER HAS HABITS ------------------------------------------
                  final todayId =
                      DateFormat('yyyy-MM-dd').format(DateTime.now());

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait(
                      habits.map((h) async {
                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('habits')
                            .doc(h.id)
                            .collection('logs')
                            .doc(todayId)
                            .get();
                        return doc;
                      }),
                    ),
                    builder: (context, logSnaps) {
                      if (!logSnaps.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final completed = logSnaps.data!
                          .where((d) =>
                              d.exists &&
                              ((d.data() as Map<String, dynamic>?)?[
                                          'completion'] ??
                                      0) ==
                                  1.0)
                          .length;

                      final total = habits.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SUMMARY ROW --------------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      widget.onNavigateToTab?.call(1),
                                  child: Container(
                                    height: 150,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: _sectionBoxDecoration(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      widget.onNavigateToTab?.call(2),
                                  child: Container(
                                    height: 150,
                                    margin: const EdgeInsets.only(left: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: _sectionBoxDecoration(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // GARDEN CARD --------------------------------------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: _outerCardDecoration(),
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
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 233, 238, 235),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: _todayGarden(habits),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // MOOD GALAXY ---------------------------------------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: _outerCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Mood Galaxy",
                                  style: GoogleFonts.fredoka(
                                    color: primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 233, 238, 235),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: _homeMoodGalaxy(_starController),
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

// ============================================================
//                YELLOW STARS PAINTER (GLOBAL)
// ============================================================

class _YellowStarsPainter extends CustomPainter {
  final double offset;
  final Random rand = Random(42);

  _YellowStarsPainter({this.offset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 25; i++) {
      paint.color = const Color(0xFFFFD54F)
          .withOpacity(0.6 + rand.nextDouble() * 0.3);

      final dx =
          (rand.nextDouble() * size.width +
                  offset * 40 * (i.isEven ? 1 : -1)) %
              size.width;

      final dy =
          (rand.nextDouble() * size.height +
                  offset * 25 * (i % 3 == 0 ? 1 : -1)) %
              size.height;

      final radius = 0.8 + rand.nextDouble() * 1.2;

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _YellowStarsPainter oldDelegate) => true;
}
