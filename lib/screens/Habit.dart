import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Habit extends StatefulWidget {
  const Habit({super.key});

  @override
  State<Habit> createState() => _HabitState();
}

class _HabitState extends State<Habit> {
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);
  String selectedView = "Daily";
  int _weekOffset = 0;

  // ---------- HELPERS ----------
  DateTime _startOfWeek(DateTime d) {
    final dow = d.weekday % 7; // Sunday=0
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: dow));
  }

  String _dateId(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Stream<QuerySnapshot> _habitsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<double?> _getCompletionForDate(String habitId, DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = _dateId(day);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return (doc.data()!['completion'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _saveCompletionForDate(String habitId, DateTime day, double value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = _dateId(day);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .doc(id);

    if (value <= 0.0) {
      final snap = await ref.get();
      if (snap.exists) await ref.delete();
    } else {
      await ref.set({
        'date': id,
        'completion': value.clamp(0.0, 1.0),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _ensureZeroLogsForDate(Iterable<DocumentSnapshot> habits, DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();
    final id = _dateId(day);

    for (final h in habits) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(h.id)
          .collection('logs')
          .doc(id);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'date': id,
          'completion': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // ---------- DIALOGS ----------
  Future<void> _showAddHabitDialog() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final controller = TextEditingController();
    String selectedIcon = 'assets/habitIcons/plant1.svg';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Habit', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Pick a plant:', style: GoogleFonts.fredoka(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(9, (i) => i + 1).map((n) {
                  final path = 'assets/habitIcons/plant$n.svg';
                  final isSel = path == selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = path),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSel ? primaryColor : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: SvgPicture.asset(path, width: 44, height: 44),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.fredoka(color: primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('habits')
                  .add({
                'name': name,
                'iconPath': selectedIcon,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.fredoka(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogDialogForDate(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final habitsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .get();

    await _ensureZeroLogsForDate(habitsSnap.docs, day);

    final Map<String, double> values = {};
    for (final h in habitsSnap.docs) {
      values[h.id] = (await _getCompletionForDate(h.id, day)) ?? 0.0;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setD) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Log habits for ${DateFormat('MMM d, y').format(day)}',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: habitsSnap.docs.map((h) {
                    final icon = h['iconPath'] as String;
                    final name = h['name'] as String;
                    final val = values[h.id] ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          SvgPicture.asset(icon, width: 28, height: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.fredoka(fontSize: 15)),
                                Slider(
                                  value: val,
                                  onChanged: (v) => setD(() => values[h.id] = v),
                                  min: 0.0,
                                  max: 1.0,
                                ),
                              ],
                            ),
                          ),
                          Text('${(val * 100).round()}%',
                              style: GoogleFonts.fredoka(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.fredoka(color: primaryColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          setD(() => saving = true);
                          for (final entry in values.entries) {
                            await _saveCompletionForDate(entry.key, day, entry.value);
                          }
                          if (mounted) Navigator.pop(ctx);
                        },
                  child: Text('Save', style: GoogleFonts.fredoka(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- UI ----------
  Widget _addHabitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showAddHabitDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          "Add Habit",
          style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _gardenShelf({required DateTime day, required List<DocumentSnapshot> habits}) {
    return FutureBuilder<Map<String, double>>(
      future: () async {
        final map = <String, double>{};
        for (final h in habits) {
          final v = await _getCompletionForDate(h.id, day);
          map[h.id] = (v ?? 0.0);
        }
        return map;
      }(),
      builder: (context, snapshot) {
        final values = snapshot.data ?? {};
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color.fromARGB(114, 79, 100, 78), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('MMMM d, y').format(day),
                  style: GoogleFonts.fredoka(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: habits.map((h) {
                        final icon = h['iconPath'] as String;
                        final val = values[h.id] ?? 0.0;
                        final opacity = (0.1 + 0.9 * val).clamp(0.1, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Opacity(
                            opacity: opacity,
                            child: SvgPicture.asset(icon, width: 36, height: 36),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showLogDialogForDate(day),
                  child: Text(
                    'Log Habit',
                    style: GoogleFonts.fredoka(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dailyView(List<DocumentSnapshot> habits) {
    final today = DateTime.now();
    return _gardenShelf(day: DateTime(today.year, today.month, today.day), habits: habits);
  }

  Widget _weeklyView(List<DocumentSnapshot> habits) {
    final start = _startOfWeek(DateTime.now());
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    return Column(children: days.map((d) => _gardenShelf(day: d, habits: habits)).toList());
  }

  Widget _monthlyView(List<DocumentSnapshot> habits) {
    final now = DateTime.now();
    final firstWeekStart = _startOfWeek(DateTime(now.year, now.month, 1));
    final displayWeekStart = firstWeekStart.add(Duration(days: 7 * _weekOffset));
    final days = List.generate(7, (i) => displayWeekStart.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _weekOffset--),
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              color: primaryColor,
            ),
            Text(
              '${DateFormat('MMM d').format(days.first)} — ${DateFormat('MMM d, y').format(days.last)}',
              style: GoogleFonts.fredoka(
                  fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => setState(() => _weekOffset++),
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              color: primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...days.map((d) => _gardenShelf(day: d, habits: habits)),
      ],
    );
  }

  // ---------- BUILD ----------
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
                      Text("  Habit Garden",
                          style: GoogleFonts.fredoka(
                              color: accentColor,
                              fontSize: 40,
                              fontWeight: FontWeight.w700)),
                      Text("    Build your garden, one habit at a time",
                          style: GoogleFonts.fredoka(
                              color: accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w100)),
                    ],
                  ),
                  Positioned(
                    top: -15,
                    left: 0,
                    child: SvgPicture.asset('assets/images/star.svg',
                        color: const Color.fromARGB(255, 236, 165, 84),
                        width: 30,
                        height: 30),
                  ),
                  Positioned(
                    top: 12,
                    right: 17,
                    child: SvgPicture.asset('assets/images/star.svg',
                        color: const Color.fromARGB(255, 236, 165, 84),
                        width: 20,
                        height: 20),
                  ),
                  Positioned(
                    top: 32,
                    right: 10,
                    child: SvgPicture.asset('assets/images/star.svg',
                        color: const Color.fromARGB(255, 236, 165, 84),
                        width: 15,
                        height: 15),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Toggle bar
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
                        onTap: () => setState(() => selectedView = option),
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _habitsStream(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final habits = snap.data!.docs;

                    if (habits.isEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            "You’re not tracking any habits yet.",
                            style: GoogleFonts.fredoka(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          _addHabitButton(),
                        ],
                      );
                    }

                    return ListView(
                      children: [
                        if (selectedView == 'Daily') _dailyView(habits),
                      
                        if (selectedView == 'Weekly') _weeklyView(habits),
                        if (selectedView == 'Monthly') _monthlyView(habits),
                        const SizedBox(height: 8),
                        _addHabitButton(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
