import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TodaySchedulePage extends StatefulWidget {
  const TodaySchedulePage({super.key});

  @override
  State<TodaySchedulePage> createState() => _TodaySchedulePageState();
}

class _TodaySchedulePageState extends State<TodaySchedulePage> {
  Timer? _timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update current time every second for running class highlight
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> getTeacherShortName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['shortName'];
  }

  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file")),
      );
    }
  }

  String getTodayName() => DateFormat('EEEE').format(DateTime.now());

  // Safe parse HH:mm 24-hour format to DateTime
  DateTime parseTime(String time) {
    final parts = time.trim().split(":");
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0].trim()),
      int.parse(parts[1].trim()),
    );
  }

  String formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    return "${d.inHours.toString().padLeft(2, '0')}:"
        "${(d.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    String today = getTodayName();

    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Schedule ($today)"),
        backgroundColor: const Color(0xFFFF9800),
        centerTitle: true,
      ),
      body: FutureBuilder<String?>(
        future: getTeacherShortName(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          String shortName = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('class_routine')
                .where('teacherShortName', isEqualTo: shortName)
                .where('day', isEqualTo: today)
                .snapshots(),
            builder: (context, routineSnapshot) {
              if (!routineSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = routineSnapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No Classes Today 🎉"));
              }

              // 🔹 Auto sort by startTime
              docs.sort((a, b) {
                try {
                  return parseTime(a['startTime'])
                      .compareTo(parseTime(b['startTime']));
                } catch (e) {
                  return 0;
                }
              });

              // 🔹 Next class countdown
              QueryDocumentSnapshot? nextClass;
              Duration? nextDuration;
              for (var doc in docs) {
                try {
                  DateTime start = parseTime(doc['startTime']);
                  if (start.isAfter(now)) {
                    nextClass = doc;
                    nextDuration = start.difference(now);
                    break;
                  }
                } catch (e) {
                  continue; // skip invalid time
                }
              }

              return Column(
                children: [
                  if (nextClass != null && nextDuration != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.shade50,
                      child: Column(
                        children: [
                          const Text(
                            "⏳ Next Class Starts In",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDuration(nextDuration),
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(nextClass['subject'] ?? "-"),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        String link = doc['routineLink'] ?? "-";

                        bool isRunning = false;
                        try {
                          DateTime start = parseTime(doc['startTime']);
                          DateTime end = parseTime(doc['endTime']);
                          isRunning =
                              now.isAfter(start) && now.isBefore(end);
                        } catch (e) {
                          isRunning = false;
                        }

                        return Card(
                          elevation: isRunning ? 8 : 3,
                          color: isRunning
                              ? Colors.green.shade100
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: ListTile(
                            leading: Icon(Icons.class_,
                                color: isRunning
                                    ? Colors.green
                                    : Colors.orange),
                            title: Text(
                              doc['subject'] ?? "-",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isRunning
                                    ? Colors.green
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              "${doc['startTime'] ?? "-"} - ${doc['endTime'] ?? "-"}\n"
                                  "Class: ${doc['className'] ?? "-"} | Room: ${doc['room'] ?? "-"}",
                            ),
                            isThreeLine: true,
                            trailing: link != "-"
                                ? IconButton(
                              icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.blue),
                              onPressed: () {
                                openLink(link);
                              },
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
