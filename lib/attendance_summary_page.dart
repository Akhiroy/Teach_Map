import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AttendanceSummaryPage extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const AttendanceSummaryPage({
    super.key,
    required this.students,
  });

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  bool _isLoading = false;

  void _toggleAttendance(int index) {
    setState(() {
      widget.students[index]['present'] = !widget.students[index]['present'];
    });
  }

  Future<void> _submitAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final presentCount =
          widget.students.where((s) => s['present'] == true).length;

      final absentCount =
          widget.students.where((s) => s['present'] == false).length;


      // SAVE TO FIRESTORE

      final attendanceData = {
        "teacherId": user?.uid,
        "date": Timestamp.now(),
        "presentCount": presentCount,
        "absentCount": absentCount,
        "students": widget.students.map((s) {
          return {
            "id": s['id'],
            "name": s['name'],
            "present": s['present'],
          };
        }).toList(),
      };

      await FirebaseFirestore.instance
          .collection("attendancelink")
          .add(attendanceData);


      // SAVE TO GOOGLE SHEET

      const String sheetUrl =
          'https://script.google.com/macros/s/AKfycbz0VwsVCWLCDECt468TjZAVda4uJ72itqpIk7zkcVGDayTG4Lz1Q3lYrKWYaOCI01ns/exec';

      final sheetData = widget.students.map((s) {
        return {
          "id": s['id'],
          "name": s['name'],
          "status": s['present'] ? "Present" : "Absent",
          "date": DateTime.now().toString(),
        };
      }).toList();

      await http.post(
        Uri.parse(sheetUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(sheetData),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance saved to Firestore & Google Sheet!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount =
        widget.students.where((s) => s['present'] == true).length;
    final absentCount =
        widget.students.where((s) => s['present'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Summary"),
        backgroundColor: const Color(0xFF027a9c),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text("Present: $presentCount",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Absent: $absentCount",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Student List
            Expanded(
              child: ListView.builder(
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  return Card(
                    child: ListTile(
                      title: Text(student['name']),
                      trailing: Icon(
                        student['present']
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                        student['present'] ? Colors.green : Colors.red,
                      ),
                      onTap: () => _toggleAttendance(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF027a9c),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                ),
                onPressed: _isLoading ? null : _submitAttendance,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Confirm & Finish",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}