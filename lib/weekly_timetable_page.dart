// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class WeeklyTimetablePage extends StatefulWidget {
//   const WeeklyTimetablePage({super.key});
//
//   @override
//   State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
// }
//
// class _WeeklyTimetablePageState extends State<WeeklyTimetablePage> {
//   Timer? _timer;
//   DateTime now = DateTime.now();
//
//   final List<String> days = ["Sunday","Monday","Tuesday","Wednesday","Thursday"];
//
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 30), (_) {
//       setState(() {
//         now = DateTime.now();
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   Future<String?> getTeacherShortName() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if(user == null) return null;
//
//     final doc = await FirebaseFirestore.instance
//         .collection('teachers')
//         .doc(user.uid)
//         .get();
//
//     if(!doc.exists) return null;
//     return doc.data()?['shortName'];
//   }
//
//   DateTime parseTime(String time) {
//     final parts = time.trim().split(":");
//     return DateTime(now.year, now.month, now.day,
//         int.parse(parts[0].trim()), int.parse(parts[1].trim()));
//   }
//
//   bool isRunning(String startTime, String endTime){
//     try {
//       DateTime start = parseTime(startTime);
//       DateTime end = parseTime(endTime);
//       return now.isAfter(start) && now.isBefore(end);
//     } catch (e){
//       return false;
//     }
//   }
//
//   Future<void> openLink(String url) async {
//     final Uri uri = Uri.parse(url.trim());
//     if(!await launchUrl(uri, mode: LaunchMode.externalApplication)){
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Could not open file"))
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Weekly Timetable"),
//         backgroundColor: const Color(0xFF009688),
//         centerTitle: true,
//       ),
//       body: FutureBuilder<String?>(
//         future: getTeacherShortName(),
//         builder: (context,snapshot){
//           if(!snapshot.hasData){
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           String shortName = snapshot.data!;
//
//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('class_routine')
//                   .where('teacherShortName',isEqualTo: shortName)
//                   .snapshots(),
//               builder: (context,routineSnapshot){
//                 if(!routineSnapshot.hasData){
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 var docs = routineSnapshot.data!.docs;
//
//                 if(docs.isEmpty){
//                   return const Center(child: Text("No classes found."));
//                 }
//
//                 // Build weekly table
//                 return DataTable(
//                   headingRowColor: MaterialStateProperty.all(Colors.teal.shade100),
//                   columnSpacing: 20,
//                   columns: [
//                     const DataColumn(label: Text("Day")),
//                     const DataColumn(label: Text("Time")),
//                     const DataColumn(label: Text("Subject")),
//                     const DataColumn(label: Text("Course Code")),
//                     const DataColumn(label: Text("Room")),
//                     const DataColumn(label: Text("PDF")),
//                   ],
//                   rows: docs.map((doc){
//                     bool running = isRunning(doc['startTime'], doc['endTime']);
//                     String link = doc['routineLink'] ?? "";
//
//                     return DataRow(
//                         color: MaterialStateProperty.resolveWith<Color?>(
//                                 (Set<MaterialState> states){
//                               if(running) return Colors.green.shade100;
//                               return null;
//                             }),
//                         cells: [
//                           DataCell(Text(doc['day'] ?? "-")),
//                           DataCell(Text("${doc['startTime']} - ${doc['endTime']}")),
//                           DataCell(Text(doc['subject'] ?? "-")),
//                           DataCell(Text(doc['className'] ?? "-")),
//                           DataCell(Text(doc['room'] ?? "-")),
//                           DataCell(
//                             link.isNotEmpty
//                                 ? InkWell(
//                               child: const Text("Open PDF",
//                                   style: TextStyle(
//                                       color: Colors.blue,
//                                       decoration: TextDecoration.underline)),
//                               onTap: (){ openLink(link); },
//                             )
//                                 : const Text("-"),
//                           ),
//                         ]
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// final table = CsvCodec().decoder.convert(response.body);



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() => _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState extends State<WeeklyTimetablePage> {
  Timer? _timer;
  DateTime now = DateTime.now();

  String? teacherShortName; // 🔥 From Firestore

  final Map<String, String> daySheetMap = {
    "Sunday": "255270977",
    "Monday": "1496246527",
    "Tuesday": "1383433023",
    "Wednesday": "739024824",
    "Thursday": "307287901",
    "Friday": "997090556",
  };

  Map<String, List<Map<String, String>>> weeklyRoutine = {};

  @override
  void initState() {
    super.initState();
    fetchTeacherShortName(); // 🔥 First get shortName

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

  // ================= GET SHORTNAME FROM FIRESTORE =================

  Future<void> fetchTeacherShortName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      teacherShortName =
          doc.data()?['shortName']?.toString().trim().toUpperCase();

      await fetchWeeklyRoutine(); // 🔥 Fetch routine after getting shortName
    }
  }

  // ================= FETCH FROM GOOGLE SHEET =================

  Future<void> fetchWeeklyRoutine() async {
    if (teacherShortName == null) return;

    Map<String, List<Map<String, String>>> tempData = {};
    String teacher = teacherShortName!.trim().toUpperCase();

    for (var entry in daySheetMap.entries) {
      final day = entry.key;
      final gid = entry.value;

      final url =
          "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=$gid";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) continue;

      final table = CsvCodec().decoder.convert(response.body);

      if (table.length <= 4) continue;

      List<String> timeRow =
      table[3].map((e) => e.toString().trim()).toList();

      List<Map<String, String>> dayRoutine = [];

      for (int row = 4; row < table.length; row++) {
        for (int col = 2; col < table[row].length; col++) {

          String time = timeRow[col].trim();

          // Skip break column
          if (!time.contains("-")) continue;

          String cell = table[row][col].toString().trim();
          if (cell.isEmpty) continue;

          String upperCell = cell
              .toUpperCase()
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // 🔥 SAFE MATCH (search whole cell)
          if (upperCell.contains(" $teacher ") ||
              upperCell.endsWith(" $teacher") ||
              upperCell.startsWith("$teacher ")) {

            dayRoutine.add({
              "time": time,
              "details": cell,
            });
          }
        }
      }

      if (dayRoutine.isNotEmpty) {
        tempData[day] = dayRoutine;
      }
    }

    setState(() {
      weeklyRoutine = tempData;
    });
  }

  // ================= TIME CHECK =================

  DateTime parseTime(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();

    if (timeStr.contains("AM") || timeStr.contains("PM")) {
      return DateFormat("h:mm a").parse(timeStr);
    }

    return DateFormat("h:mm").parse(timeStr);
  }

  bool isRunning(String day, String range) {
    final today = DateFormat('EEEE').format(now);
    if (today != day) return false;

    try {
      List<String> parts = range.split("-");
      if (parts.length != 2) return false;

      DateTime start = parseTime(parts[0]);
      DateTime end = parseTime(parts[1]);

      start = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      end = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Timetable"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: teacherShortName == null
          ? const Center(child: CircularProgressIndicator())
          : weeklyRoutine.isEmpty
          ? const Center(child: Text("No routine found"))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
          MaterialStateProperty.all(Colors.teal.shade100),
          columns: const [
            DataColumn(label: Text("Day")),
            DataColumn(label: Text("Time")),
            DataColumn(label: Text("Details")),
          ],
          rows: weeklyRoutine.entries.expand((entry) {
            final day = entry.key;
            final routines = entry.value;

            return routines.map((routine) {
              bool running =
              isRunning(day, routine['time']!);

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (running) return Colors.green.shade100;
                      return null;
                    }),
                cells: [
                  DataCell(Text(day)),
                  DataCell(Text(routine['time']!)),
                  DataCell(Text(routine['details']!)),
                ],
              );
            });
          }).toList(),
        ),
      ),
    );
  }
}