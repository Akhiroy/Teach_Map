import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    final data = widget.students
        .map((s) => {'name': s['name'], 'present': s['present']})
        .toList();

    // ✅ Your Google Apps Script Web App URL
    const String url = 'https://script.google.com/macros/s/AKfycbz0VwsVCWLCDECt468TjZAVda4uJ72itqpIk7zkcVGDayTG4Lz1Q3lYrKWYaOCI01ns/exec';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context); // Go back after submission
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