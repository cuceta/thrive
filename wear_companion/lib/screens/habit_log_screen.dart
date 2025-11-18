import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLogScreen extends StatefulWidget {
  final String habitId;
  final String habitName;
  final String iconPath;

  const HabitLogScreen({
    super.key,
    required this.habitId,
    required this.habitName,
    required this.iconPath,
  });

  @override
  State<HabitLogScreen> createState() => _HabitLogScreenState();
}

class _HabitLogScreenState extends State<HabitLogScreen> {
  final FirebaseService firebaseService = FirebaseService();

  double value = 0.0;
  final Color primaryColor = const Color.fromRGBO(47, 76, 45, 1);
  final Color accentColor = const Color.fromARGB(255, 235, 96, 57);

  Future<void> _loadExistingValue() async {
    final uid = firebaseService.currentUser!.uid;

    // same date logic as mobile
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    final local = now.toUtc().add(offset);
    final localDateOnly = DateTime(local.year, local.month, local.day);

    final todayId = DateFormat('yyyy-MM-dd').format(localDateOnly);

    final doc = await firebaseService.db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(widget.habitId)
        .collection('logs')
        .doc(todayId)
        .get();

    if (doc.exists) {
      setState(() {
        value = (doc.data()!['completion'] as num).toDouble();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingValue();
  }

  Future<void> _saveLog() async {
    final uid = firebaseService.currentUser!.uid;

    // correct date logic matching the mobile code
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    final local = now.toUtc().add(offset);
    final localDateOnly = DateTime(local.year, local.month, local.day);

    final todayId = DateFormat('yyyy-MM-dd').format(localDateOnly);
    final ref = firebaseService.db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(widget.habitId)
        .collection('logs')
        .doc(todayId);

    if (value <= 0.0) {
      final snap = await ref.get();
      if (snap.exists) {
        await ref.delete();
      }
    } else {
      await ref.set({
        'date': todayId,
        'completion': value.clamp(0.0, 1.0),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 217, 251, 229),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Row(
                children: [
                  const SizedBox(width: 20),
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
                  const SizedBox(width: 5),
                  Text(
                    widget.habitName,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Column(
                children: [
                  SvgPicture.asset(widget.iconPath, width: 40, height: 40),
                  Slider(
                    value: value,
                    onChanged: (v) => setState(() => value = v),
                    min: 0.0,
                    max: 1.0,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    thumbColor: primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 0),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ), // left + right padding
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveLog,
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
                        child: Text(
                          "Save Log",
                          style: GoogleFonts.fredoka(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ), // left + right padding
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
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
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.fredoka(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
