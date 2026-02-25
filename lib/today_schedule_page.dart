import 'dart:async';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:teachmap/profile_page.dart';
import 'package:teachmap/profile_update_page.dart';
import 'package:teachmap/upload_routine_page.dart';
import 'package:teachmap/weekly_timetable_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'attendance_list_page.dart';
import 'login_page.dart';
import 'notification_model.dart';
import 'notification_page.dart';
import 'notification_service.dart';

class TodaySchedulePage extends StatefulWidget {
  const TodaySchedulePage({super.key});

  @override
  State<TodaySchedulePage> createState() => _TodaySchedulePageState();
}

class _TodaySchedulePageState extends State<TodaySchedulePage> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, String>> allTeachers = [];
  List<Map<String, String>> filteredTeachers = [];
  List<AppNotification> notificationList = [];

  String? selectedAcronym;
  String? resultText;
  String? errorMessage;

  bool isCheckingRoutine = false;
  List<List<String>> todayRoutine = [];

  final String teacherSheet =
      "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=2120560749";

  final String teacherSheetGED =
      "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=639086230";

  final Map<String, String> daySheetMap = {
    "saturday": "997090556",
    "sunday": "255270977",
    "monday": "447521283",
    "tuesday": "1496246527",
    "wednesday": "1383433023",
    "thursday": "739024824",
    "friday": "307287901",
  };

  @override
  void initState() {
    super.initState();
    loadTeacherFromFirestore();
  }

  /// ================= NORMALIZE TABLE =================
  List<List<String>> normalizeTable(List<List<String>> table) {
    int maxLength = 0;

    for (var row in table) {
      if (row.length > maxLength) {
        maxLength = row.length;
      }
    }

    for (var row in table) {
      while (row.length < maxLength) {
        row.add("");
      }
    }

    return table;
  }

  /// ================= FETCH TEACHERS =================
  Future<void> loadTeacherFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null && data['shortName'] != null) {
          setState(() {
            selectedAcronym = data['shortName'];
            searchController.text = data['shortName'];
          });

          print("Loaded teacher: $selectedAcronym");

          await checkCurrentClass(); // await is important
        }
      }
    } catch (e) {
      print("Error loading teacher: $e");
    }
  }


  /// ================= SEARCH =================
  void searchTeacher(String query) {
    if (query.isEmpty) {
      setState(() => filteredTeachers = []);
      return;
    }

    final results = allTeachers.where((teacher) {
      final name = teacher["fullName"]!.toLowerCase();
      final acronym = teacher["acronym"]!.toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input) || acronym.contains(input);
    }).toList();

    setState(() {
      filteredTeachers = results;
    });
  }

  /// ================= CHECK CURRENT CLASS =================
  Future<void> checkCurrentClass() async {
    if (selectedAcronym == null) return;

    setState(() {
      isCheckingRoutine = true;
      resultText = null;
      errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final currentDay =
      DateFormat('EEEE').format(now).toLowerCase();

      final gid = daySheetMap[currentDay];
      if (gid == null) {
        setState(() {
          resultText = "No routine for today";
          isCheckingRoutine = false;
        });
        return;
      }

      final routineUrl =
          "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=$gid";

      final response = await http.get(Uri.parse(routineUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to load routine");
      }

      List<List<String>> table = response.body
          .split("\n")
          .map((row) => row.split(","))
          .toList();

      todayRoutine = normalizeTable(table);

      if (todayRoutine.length <= 3) {
        setState(() {
          resultText = "Routine format error";
          isCheckingRoutine = false;
        });
        return;
      }

      List<String> header = todayRoutine[3];
      int matchedColumnIndex = -1;

      for (int i = 0; i < header.length; i++) {
        if (header[i].contains("-") &&
            isTimeInRange(header[i])) {
          matchedColumnIndex = i;
          break;
        }
      }

      if (matchedColumnIndex == -1) {
        setState(() {
          resultText = "Free right now";
          isCheckingRoutine = false;
        });
        return;
      }

      for (int i = 2; i < todayRoutine.length; i++) {
        if (todayRoutine[i].length >
            matchedColumnIndex) {
          String cell =
          todayRoutine[i][matchedColumnIndex];
          if (cell.toLowerCase().contains(selectedAcronym!.toLowerCase())){
            setState(() {
              resultText = cell;
              isCheckingRoutine = false;

              // ✅ Store in app notification list
              notificationList.add(
                AppNotification(
                  title: "Class Ongoing",
                  body: cell,
                  time: DateTime.now(),
                ),
              );
            });

            // 🔔 Show device notification
            await NotificationService.showNotification(
              title: "Class Ongoing",
              body: cell,
            );

            return;
          }
        }
      }

      setState(() {
        resultText = "Free right now";
        isCheckingRoutine = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong";
        isCheckingRoutine = false;
      });
    }
  }

  bool isTimeInRange(String range) {
    try {
      final now = DateTime.now();
      final parts = range.split("-");
      if (parts.length != 2) return false;

      DateTime start = parseSheetTime(parts[0]);
      DateTime end = parseSheetTime(parts[1]);

      start = DateTime(now.year, now.month, now.day,
          start.hour, start.minute);
      end = DateTime(now.year, now.month, now.day,
          end.hour, end.minute);

      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  DateTime parseSheetTime(String timeStr) {
    timeStr = timeStr
        .trim()
        .toUpperCase()
        .replaceAll(".", ":")
        .replaceAll("\"", "")
        .replaceAll(RegExp(r'\s+'), " ");

    if (timeStr.contains("AM") ||
        timeStr.contains("PM")) {
      return DateFormat("h:mm a").parse(timeStr);
    }

    DateTime temp =
    DateFormat("h:mm").parse(timeStr);
    String period =
    (temp.hour >= 9 && temp.hour <= 11)
        ? " AM"
        : " PM";
    return DateFormat("h:mm a")
        .parse(timeStr + period);
  }

  /// ================= FILTER FULL DAY ROUTINE =================
  List<List<String>> getTeacherRoutine() {
    if (todayRoutine.isEmpty || selectedAcronym == null) return [];

    // Real header is row index 3
    List<String> header = todayRoutine[3];

    List<List<String>> filtered = [header];

    for (int i = 4; i < todayRoutine.length; i++) {
      final row = todayRoutine[i];
      // Only include row if any cell contains teacher acronym
      if (row.any((cell) =>
          cell.toLowerCase().contains(selectedAcronym!.toLowerCase()))) {
        filtered.add(row);
      }
    }

    return filtered;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final teacherRoutine = getTeacherRoutine();
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationPage(
                    notifications: notificationList,
                  ),
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Color(0xFF027a9c),
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 Back arrow color
        ),
        title: const Text(
          "Show Today's Routine",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadTeacherFromFirestore,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              const SizedBox(height: 25),

              /// ⏳ LOADING
              if (isCheckingRoutine)
                const Center(child: CircularProgressIndicator()),

              /// 📌 RESULT CARD
              if (resultText != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: resultText!
                        .toLowerCase()
                        .contains("free")
                        ? LinearGradient(
                      colors: [
                        Colors.blue.shade300,
                        Colors.blue.shade500
                      ],
                    )
                        : LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        resultText!
                            .toLowerCase()
                            .contains("free")
                            ? Icons.event_available
                            : Icons.class_,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        resultText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resultText!
                            .toLowerCase()
                            .contains("free")
                            ? "Status: Free"
                            : "Status: In Class",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              /// 📅 FULL DAY ROUTINE TABLE

              if (teacherRoutine.isNotEmpty)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ExpansionTile(
                    title: const Text(
                      "View Full Day Routine",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    childrenPadding: const EdgeInsets.all(15),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                            border: TableBorder.all(color: Colors.grey.shade300),
                            columns: teacherRoutine[0]
                                .map((header) => DataColumn(
                              label: Text(
                                header,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ))
                                .toList(),
                            rows: teacherRoutine
                                .sublist(1)
                                .map(
                                  (row) => DataRow(
                                cells: row.map((cell) => DataCell(Text(cell))).toList(),
                              ),
                            )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
