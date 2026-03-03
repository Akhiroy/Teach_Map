import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'attendance_summary_page.dart';

class AttendancePage extends StatefulWidget {
  final String courseName;
  final String batch;
  final String section;
  final String attendanceLink;

  const AttendancePage({
    super.key,
    required this.courseName,
    required this.batch,
    required this.section,
    required this.attendanceLink,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  int currentIndex = 0;
  List<int> historyStack = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentsFromLink();
  }

  Future<void> _fetchStudentsFromLink() async {
    try {
      if (widget.attendanceLink.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(Uri.parse(widget.attendanceLink));

      if (response.statusCode == 200) {
        final csvData = CsvCodec().decoder.convert(response.body);

        if (csvData.length <= 1) {
          setState(() {
            students = [];
            isLoading = false;
          });
          return;
        }

        final parsedStudents = csvData.skip(1).map((row) {
          return {
            "id": row[0].toString(),
            "name": row.length > 1 ? row[1].toString() : "Unknown",
            "present": false,
          };
        }).toList();

        setState(() {
          students = parsedStudents;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load students");
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _markAttendance(bool present) async {
    setState(() {
      students[currentIndex]['present'] = present;
      historyStack.add(currentIndex);
    });

    await _saveToGoogleSheet(students[currentIndex]);

    if (currentIndex < students.length - 1) {
      setState(() => currentIndex++);
    } else {
      _goToSummaryPage();
    }
  }

  void _goToSummaryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AttendanceSummaryPage(students: students),
      ),
    );
  }
  Future<void> _saveToGoogleSheet(Map student) async {
    const scriptUrl = "https://script.google.com/home/projects/1jiYX3Q7wITo6tqa-p59Am0h2pJfFiRw9elIR9ZGeqPwd-iB6vTnQV8Y9/edit";
    final now = DateTime.now();

    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final dayName = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][now.weekday - 1];

    await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "date": formattedDate,
        "day": dayName,
        "course": widget.courseName,
        "batch": widget.batch,
        "section": widget.section,
        "studentId": student['id'],
        "studentName": student['name'],
        "status": student['present'] ? "Present" : "Absent",
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (students.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("${widget.courseName} - ${widget.batch}",
          style: TextStyle(color: Colors.white),),
          backgroundColor: const Color(0xFF027a9c),
          iconTheme: const IconThemeData(
            color: Colors.white, // 👈 Back arrow color
          ),
        ),
        body: const Center(
          child: Text(
            "No students found!",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final student = students[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(
              "Batch ${widget.batch} | Section ${widget.section}",
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF027a9c),
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow color
        ),
        elevation: 4,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigate to summary page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceSummaryPage(students: students),
                ),
              );
            },
            icon: const Icon(Icons.list, color: Colors.white),
            label: const Text(
              "Summary",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 0) {
            // Swipe Right → Absent
            _markAttendance(false);
          } else if (details.velocity.pixelsPerSecond.dx < 0) {
            // Swipe Left → Present
            _markAttendance(true);
          }
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF027a9c), Color(0xFF04a5c9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              height: 320,
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    student['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Swipe Left → Present\nSwipe Right → Absent",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Student ${currentIndex + 1} of ${students.length}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}