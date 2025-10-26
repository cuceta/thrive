import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const List<String> availableMoodIcons = [
  'assets/moods/star_1.svg',
  'assets/moods/star_2.svg',
  'assets/moods/star_3.svg',
  'assets/moods/star_4.svg',
  'assets/moods/star_5.svg',
];

class Mood extends StatefulWidget {
  const Mood({super.key});

  @override
  State<Mood> createState() => _MoodState();
}

class _MoodState extends State<Mood> {
  final TextStyle moodTextStyle = GoogleFonts.fredoka(
    color: const Color.fromRGBO(47, 76, 45, 1),
    fontWeight: FontWeight.w500,
  );

  final user = FirebaseAuth.instance.currentUser;

  // ---------- utils ----------
  List<DateTime> _past7DaysEndingToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  }

  Color _nightTop = const Color(0xFF0a0e27);
  Color _nightBottom = const Color(0xFF30125b);

  // ---------- ADD MOOD ----------
  Future<void> _showAddMoodDialog() async {
    final nameController = TextEditingController();
    String? selectedIcon;

    final usedIcons =
        (await FirebaseFirestore.instance
                .collection('moods')
                .where('userId', isEqualTo: user!.uid)
                .get())
            .docs
            .map((d) => d['iconPath'] as String)
            .toSet();

    final unusedIcons = availableMoodIcons
        .where((p) => !usedIcons.contains(p))
        .toList();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;

        void toast(String m) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m)));

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add Mood',
                style: moodTextStyle.copyWith(fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Mood name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Choose an icon:'),
                    ),
                    const SizedBox(height: 8),
                    if (unusedIcons.isEmpty)
                      Text(
                        'All icons are in use. Delete a mood to free one.',
                        style: moodTextStyle.copyWith(fontSize: 14),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: unusedIcons.map((iconPath) {
                          final selected = selectedIcon == iconPath;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedIcon = iconPath),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? const Color.fromRGBO(47, 76, 45, 1)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                iconPath,
                                width: 56,
                                height: 56,
                                colorFilter: const ColorFilter.mode(
                                  const Color.fromARGB(255, 235, 96, 57),
                                  BlendMode.srcIn, // replaces the fill color
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: moodTextStyle.copyWith(fontSize: 14,),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return toast('Enter a mood name.');
                          if (selectedIcon == null)
                            return toast('Select an icon.');

                          setDialogState(() => isSaving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('moods')
                                .add({
                                  'userId': user!.uid,
                                  'name': name,
                                  'iconPath': selectedIcon,
                                  'createdAt': FieldValue.serverTimestamp(),
                                })
                                .timeout(const Duration(seconds: 12));
                            if (mounted &&
                                Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }
                          } on TimeoutException {
                            setDialogState(() => isSaving = false);
                            toast('Network timeout — try again.');
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            toast('Error adding mood: $e');
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Add',
                          style: moodTextStyle.copyWith(fontSize: 14),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- LOG MOOD ----------
  Future<void> _showLogMoodDialog(String moodId) async {
    final controller = TextEditingController();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;
        void toast(String m) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m)));

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Log Mood Level (1–10)',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: const Color.fromRGBO(47, 76, 45, 1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mood level',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: moodTextStyle.copyWith(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final v = int.tryParse(controller.text);
                          if (v == null || v < 1 || v > 10)
                            return toast('Enter a number 1–10.');
                          setDialogState(() => isSaving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('moods')
                                .doc(moodId)
                                .collection('logs')
                                .add({
                                  'level': v,
                                  'timestamp': FieldValue.serverTimestamp(),
                                })
                                .timeout(const Duration(seconds: 12));
                            if (mounted &&
                                Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }
                          } on TimeoutException {
                            setDialogState(() => isSaving = false);
                            toast('Network timeout — try again.');
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            toast('Error saving log: $e');
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: moodTextStyle.copyWith(fontSize: 14),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- DELETE MOOD ----------
  Future<void> _deleteMoodWithLogs(String moodId) async {
    final moodRef = FirebaseFirestore.instance.collection('moods').doc(moodId);
    final logsSnap = await moodRef.collection('logs').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in logsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(moodRef);
    await batch.commit();
  }

  // ---------- DRAW: average path (simple smoothing) ----------
  Path _buildAveragePath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      // simple quadratic curve between points
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  // ---------- WIDGET: animated icons over gradient, with white average curve ----------
  Widget _weekCanvas({
    required List<Map<String, dynamic>> points,
    required List<DateTime> weekDays,
    double height = 200,
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    bool showStars = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        // Chart should take up about 86% of the available width and stay centered
        final innerWidth = containerWidth * 0.86;
        final sidePadding = (containerWidth - innerWidth) / 2;
        final cellWidth = innerWidth / 7.0; // one column per weekday
        final labelArea = 22.0;
        final chartHeight = height - labelArea;

        // Helper to find X-center of each day
        double centerX(int dayIdx) => sidePadding + cellWidth * (dayIdx + 0.5);

        return Center(
          child: Container(
            height: height + 40,
            width: containerWidth,
            margin: EdgeInsets.only(
              top: padding.top + 20,
              bottom: padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white, // keep outer white box
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // slightly smaller inset galaxy background layer
                Positioned(
                  left: 10,
                  right: 10,
                  top: 5,
                  bottom: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_nightTop, _nightBottom],
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // match shape but inset
                    ),
                  ),
                ),

                if (showStars)
                  _TinyStarsLayer(), // still covers entire inner galaxy area
                // ⭐ Animated yellow icons
                ...points.map((p) {
                  final int dayIdx = p['x'] as int; // 0..6
                  final double level = (p['y'] as num).toDouble().clamp(0, 10);
                  final String iconPath = p['iconPath'] as String;

                  final double cx = centerX(dayIdx);
                  final double cy =
                      chartHeight - (level / 10.0) * chartHeight; // Y position

                  return TweenAnimationBuilder<double>(
                    key: ValueKey('pt-$iconPath-$dayIdx-$level'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) {
                      final y = lerpDouble(chartHeight + 32, cy, t)!;
                      return Positioned(
                        left: cx - 14,
                        top: y - 14,
                        child: Opacity(
                          opacity: t,
                          child: SvgPicture.asset(
                            iconPath,
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFFFD54F), // soft golden yellow
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // 🗓 Weekday labels (same 7 columns)
                ...List.generate(7, (i) {
                  return Positioned(
                    left: sidePadding + cellWidth * i,
                    bottom: 2,
                    width: cellWidth,
                    child: Center(
                      child: Text(
                        DateFormat('E').format(weekDays[i]),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- MOOD GALAXY (all moods) ----------
  Widget _galaxySection() {
    final weekDays = _past7DaysEndingToday();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moods')
          .where('userId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, moodsSnap) {
        if (!moodsSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final moods = moodsSnap.data!.docs;
        if (moods.isEmpty) {
          return const SizedBox.shrink();
        }

        // Load logs for each mood (one-time per build). For simplicity we do gets here.
        return FutureBuilder<List<QuerySnapshot>>(
          future: Future.wait(
            moods.map((m) {
              return FirebaseFirestore.instance
                  .collection('moods')
                  .doc(m.id)
                  .collection('logs')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(weekDays.first),
                  )
                  .get();
            }),
          ),
          builder: (context, logsSnaps) {
            if (!logsSnaps.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Build all points (all moods together)
            final List<Map<String, dynamic>> points = [];
            for (int mi = 0; mi < moods.length; mi++) {
              final mood = moods[mi];
              final iconPath = mood['iconPath'] as String;
              final logs = logsSnaps.data![mi].docs;

              // For each day, take first log (or compute mean if multiple)
              for (int di = 0; di < weekDays.length; di++) {
                final day = weekDays[di];
                final dayLogs = logs.where((doc) {
                  final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                  return ts != null &&
                      ts.year == day.year &&
                      ts.month == day.month &&
                      ts.day == day.day;
                }).toList();

                if (dayLogs.isEmpty) continue;
                // average of this day's logs
                final avg =
                    dayLogs
                        .map((d) => (d['level'] as num).toDouble())
                        .fold<double>(0, (a, b) => a + b) /
                    dayLogs.length;
                points.add({'x': di, 'y': avg, 'iconPath': iconPath});
              }
            }

            // Sort points by day (optional aesthetic)
            points.sort((a, b) => (a['x'] as int).compareTo(b['x'] as int));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Mood Galaxy (Past Week)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                _weekCanvas(
                  points: points,
                  weekDays: weekDays,
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  showStars: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- INDIVIDUAL MOOD CARD ----------
  Widget _buildMoodCard(DocumentSnapshot mood) {
    final moodId = mood.id;
    final name = mood['name'] as String;
    final iconPath = mood['iconPath'] as String;
    final weekDays = _past7DaysEndingToday();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: SvgPicture.asset(
          iconPath,
          width: 36,
          height: 36,
          color: const Color.fromARGB(255, 235, 96, 57),
        ),
        title: Text(name, style: moodTextStyle.copyWith(fontSize: 24)),
        trailing: PopupMenuButton<String>(
          // color: const Color.fromRGBO(47, 76, 45, 1),
          surfaceTintColor: const Color.fromRGBO(47, 76, 45, 1),
          iconColor: const Color.fromRGBO(47, 76, 45, 1), // your custom color

          onSelected: (v) async {
            if (v == 'delete') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dc) => AlertDialog(
                  title: Text(
                    'Delete mood?',
                    style: moodTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  content: const Text(
                    'This will remove the mood and all its logs.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dc).pop(false),
                      child: Text(
                        'Cancel',
                        style: moodTextStyle.copyWith(fontSize: 14),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dc).pop(true),
                      child: Text(
                        'Delete',
                        style: moodTextStyle.copyWith(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 235, 96, 57),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) await _deleteMoodWithLogs(moodId);
            }
          },
          itemBuilder: (c) => const [
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete mood',
                style: TextStyle(color: const Color.fromRGBO(47, 76, 45, 1)),
              ),
            ),
          ],
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moods')
                .doc(moodId)
                .collection('logs')
                .where(
                  'timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(weekDays.first),
                )
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final logs = snap.data!.docs;

              // Build points for this mood (average per day if multiple)
              final List<Map<String, dynamic>> points = [];
              for (int di = 0; di < weekDays.length; di++) {
                final day = weekDays[di];
                final dayLogs = logs.where((doc) {
                  final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                  return ts != null &&
                      ts.year == day.year &&
                      ts.month == day.month &&
                      ts.day == day.day;
                }).toList();

                if (dayLogs.isEmpty) continue;
                final avg =
                    dayLogs
                        .map((d) => (d['level'] as num).toDouble())
                        .fold<double>(0, (a, b) => a + b) /
                    dayLogs.length;
                points.add({'x': di, 'y': avg, 'iconPath': iconPath});
              }

              if (points.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No logs yet this week. Add one below!',
                    style: moodTextStyle.copyWith(fontSize: 14),
                  ),
                );
              }

              return _weekCanvas(
                points: points,
                weekDays: weekDays,
                height: 220,

                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                showStars: true, // cleaner in cards
              );
            },
          ),
          TextButton.icon(
            onPressed: () => _showLogMoodDialog(moodId),
            icon: const Icon(
              Icons.add,
              color: const Color.fromRGBO(47, 76, 45, 1),
            ),
            label: Text(
              'Log Mood Level',
              style: moodTextStyle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.fredokaTextTheme().apply(
          bodyColor: const Color.fromRGBO(47, 76, 45, 1),
          displayColor: const Color.fromRGBO(47, 76, 45, 1),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFDBF9E6),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moods')
                .where('userId', isEqualTo: user!.uid)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final moods = snap.data!.docs;

              return ListView(
                children: [
                  // Galaxy section
                  _galaxySection(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Your Moods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (moods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No moods yet. Tap + to add one!'),
                    )
                  else
                    ...moods.map(_buildMoodCard),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMoodDialog,
          backgroundColor: Colors.green.shade400,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// ====== Painters / Decorative layers ======

class _AveragePainter extends CustomPainter {
  final Path path;
  _AveragePainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

    // scale to fit provided size
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AveragePainter oldDelegate) =>
      oldDelegate.path != path;
}

class _TinyStarsLayer extends StatelessWidget {
  _TinyStarsLayer({super.key});

  // Create 25 random star positions with fixed seed (so they look random but consistent)
  final List<_Star> _stars = List.generate(25, (i) {
    final dx = (i * 73 % 100) / 100; // pseudo-random pattern
    final dy = ((i * 37 + 11) % 100) / 100;
    final r = 0.8 + (i % 5) * 0.25;
    final opacity = 0.5 + (i % 7) * 0.06;
    return _Star(Offset(dx, dy), r, opacity);
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _StarsPainter(_stars)));
  }
}

class _Star {
  final Offset pos;
  final double radius;
  final double opacity;
  const _Star(this.pos, this.radius, this.opacity);
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  _StarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final p = Paint()..color = Colors.white.withOpacity(s.opacity);
      final pos = Offset(s.pos.dx * size.width, s.pos.dy * size.height);
      canvas.drawCircle(pos, s.radius, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}
