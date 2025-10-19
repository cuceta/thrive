import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodModel {
  final String id;
  final String name;
  final String iconPath;

  MoodModel({required this.id, required this.name, required this.iconPath});

  factory MoodModel.fromMap(String id, Map<String, dynamic> data) {
    return MoodModel(id: id, name: data['name'], iconPath: data['iconPath']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'iconPath': iconPath};
  }
}

class MoodLog {
  final String moodId;
  final DateTime date;
  final int level;

  MoodLog({required this.moodId, required this.date, required this.level});

  factory MoodLog.fromMap(Map<String, dynamic> data) {
    return MoodLog(
      moodId: data['moodId'],
      date: (data['date'] as Timestamp).toDate(),
      level: data['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'moodId': moodId, 'date': date, 'level': level};
  }
}

class AddMoodDialog extends StatefulWidget {
  final Function(MoodModel) onAdd;

  const AddMoodDialog({super.key, required this.onAdd});

  @override
  State<AddMoodDialog> createState() => _AddMoodDialogState();
}

class _AddMoodDialogState extends State<AddMoodDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Mood"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Mood Name"),
          ),
          TextField(
            controller: _iconController,
            decoration: const InputDecoration(labelText: "Icon Path (SVG)"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final mood = MoodModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              iconPath: _iconController.text,
            );
            widget.onAdd(mood);
            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}

class Mood extends StatefulWidget {
  const Mood({super.key});

  @override
  State<Mood> createState() => _MoodState();
}

class _MoodState extends State<Mood> {
  List<MoodModel> moods = [];
  List<MoodLog> logs = [];
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchMoodsAndLogs();
  }

  Future<void> fetchMoodsAndLogs() async {
    if (userId == null) return;

    final moodSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("moods")
        .get();

    final logSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("logs")
        .get();

    setState(() {
      moods = moodSnap.docs
          .map((d) => MoodModel.fromMap(d.id, d.data()))
          .toList();
      logs = logSnap.docs.map((d) => MoodLog.fromMap(d.data())).toList();
    });
  }

  Future<void> logMood(MoodModel mood) async {
    if (userId == null) return;

    final level = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempLevel = 5;
        return AlertDialog(
          title: Text("Log ${mood.name}"),
          content: StatefulBuilder(
            builder: (context, setState) => Slider(
              min: 1,
              max: 10,
              divisions: 9,
              label: tempLevel.toString(),
              value: tempLevel.toDouble(),
              onChanged: (v) => setState(() => tempLevel = v.toInt()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempLevel),
              child: const Text("Log"),
            ),
          ],
        );
      },
    );

    if (level != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("logs")
          .add(
            MoodLog(
              moodId: mood.id,
              date: DateTime.now(),
              level: level,
            ).toMap(),
          );
      fetchMoodsAndLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AddMoodDialog(
              onAdd: (mood) async {
                if (userId == null) return;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("moods")
                    .doc(mood.id)
                    .set(mood.toMap());
                fetchMoodsAndLogs();
              },
            ),
          ),
          child: const Text("Add Mood"),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: moods
                .map(
                  (mood) => ListTile(
                    leading: SvgPicture.asset(mood.iconPath, width: 32),
                    title: Text(mood.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => logMood(mood),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: moods.isEmpty || logs.isEmpty
                ? const Center(child: Text("Add and log moods to see graph"))
                : LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = [
                                "Mon",
                                "Tue",
                                "Wed",
                                "Thu",
                                "Fri",
                                "Sat",
                                "Sun",
                              ];
                              return Text(days[value.toInt() % 7]);
                            },
                          ),
                        ),
                      ),
                      lineBarsData: moods.map((mood) {
                        final data = logs
                            .where((log) => log.moodId == mood.id)
                            .map(
                              (log) => FlSpot(
                                log.date.weekday.toDouble(),
                                log.level.toDouble(),
                              ),
                            )
                            .toList();
                        return LineChartBarData(
                          spots: data,
                          isCurved: true,
                          color: Colors
                              .orange, // <-- use `color` instead of `colors`
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 8,
                                color: Colors.orange,
                                strokeWidth: 0,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
