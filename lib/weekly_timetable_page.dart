import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage> {
  Timer? _timer;
  DateTime now = DateTime.now();

  final List<String> days = ["Sunday","Monday","Tuesday","Wednesday","Thursday"];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    if(user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .get();

    if(!doc.exists) return null;
    return doc.data()?['shortName'];
  }

  DateTime parseTime(String time) {
    final parts = time.trim().split(":");
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0].trim()), int.parse(parts[1].trim()));
  }

  bool isRunning(String startTime, String endTime){
    try {
      DateTime start = parseTime(startTime);
      DateTime end = parseTime(endTime);
      return now.isAfter(start) && now.isBefore(end);
    } catch (e){
      return false;
    }
  }

  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url.trim());
    if(!await launchUrl(uri, mode: LaunchMode.externalApplication)){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open file"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Timetable"),
        backgroundColor: const Color(0xFF009688),
        centerTitle: true,
      ),
      body: FutureBuilder<String?>(
        future: getTeacherShortName(),
        builder: (context,snapshot){
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          String shortName = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('class_routine')
                  .where('teacherShortName',isEqualTo: shortName)
                  .snapshots(),
              builder: (context,routineSnapshot){
                if(!routineSnapshot.hasData){
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = routineSnapshot.data!.docs;

                if(docs.isEmpty){
                  return const Center(child: Text("No classes found."));
                }

                // Build weekly table
                return DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.teal.shade100),
                  columnSpacing: 20,
                  columns: [
                    const DataColumn(label: Text("Day")),
                    const DataColumn(label: Text("Time")),
                    const DataColumn(label: Text("Subject")),
                    const DataColumn(label: Text("Course Code")),
                    const DataColumn(label: Text("Room")),
                    const DataColumn(label: Text("PDF")),
                  ],
                  rows: docs.map((doc){
                    bool running = isRunning(doc['startTime'], doc['endTime']);
                    String link = doc['routineLink'] ?? "";

                    return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states){
                              if(running) return Colors.green.shade100;
                              return null;
                            }),
                        cells: [
                          DataCell(Text(doc['day'] ?? "-")),
                          DataCell(Text("${doc['startTime']} - ${doc['endTime']}")),
                          DataCell(Text(doc['subject'] ?? "-")),
                          DataCell(Text(doc['className'] ?? "-")),
                          DataCell(Text(doc['room'] ?? "-")),
                          DataCell(
                            link.isNotEmpty
                                ? InkWell(
                              child: const Text("Open PDF",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline)),
                              onTap: (){ openLink(link); },
                            )
                                : const Text("-"),
                          ),
                        ]
                    );
                  }).toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

