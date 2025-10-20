import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

/// Predefined mood icons (stored in your assets)
const List<String> availableMoodIcons = [
  'assets/moods/star_1',
  'assets/moods/star_2',
  'assets/moods/star_3',
  'assets/moods/star_4',
  'assets/moods/star_5',
];

class Mood extends StatefulWidget {
  const Mood({super.key});

  @override
  State<Mood> createState() => _MoodState();
}

class _MoodState extends State<Mood> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _showAddMoodDialog() async {
    final nameController = TextEditingController();
    String? selectedIcon;

    // Fetch used icons
    final usedIcons = (await FirebaseFirestore.instance
            .collection('moods')
            .where('userId', isEqualTo: user!.uid)
            .get())
        .docs
        .map((doc) => doc['iconPath'] as String)
        .toSet();

    final unusedIcons =
        availableMoodIcons.where((icon) => !usedIcons.contains(icon)).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Add Mood"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Mood name"),
                ),
                const SizedBox(height: 16),
                const Text("Choose an icon:"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: unusedIcons.map((icon) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedIcon == icon
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(icon, width: 40, height: 40),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && selectedIcon != null) {
                  await FirebaseFirestore.instance.collection('moods').add({
                    'userId': user!.uid,
                    'name': nameController.text.trim(),
                    'iconPath': selectedIcon,
                  });
                  Navigator.pop(context);
                  setState(() {}); // refresh
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showLogMoodDialog(String moodId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Mood Level (1-10)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Mood level"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 10) {
                await FirebaseFirestore.instance
                    .collection('moods')
                    .doc(moodId)
                    .collection('logs')
                    .add({
                  'level': value,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(DocumentSnapshot mood) {
    final moodId = mood.id;
    final moodName = mood['name'];
    final iconPath = mood['iconPath'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color.fromARGB(255, 238, 250, 238),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: SvgPicture.asset(iconPath, width: 36, height: 36),
        title: Text(
          moodName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moods')
                .doc(moodId)
                .collection('logs')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No logs yet. Add one below!"),
                );
              }

              final spots = docs
                  .asMap()
                  .entries
                  .map((e) => FlSpot(
                        e.key.toDouble(),
                        (e.value['level'] as num).toDouble(),
                      ))
                  .toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: () => _showLogMoodDialog(moodId),
            icon: const Icon(Icons.add),
            label: const Text("Log Mood Level"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 249, 230),
      appBar: AppBar(
        title: const Text("Mood Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMoodDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moods')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final moods = snapshot.data!.docs;
          if (moods.isEmpty) {
            return const Center(child: Text("No moods yet. Add one!"));
          }

          return ListView(
            children: moods.map(_buildMoodCard).toList(),
          );
        },
      ),
    );
  }
}
