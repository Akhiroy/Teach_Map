import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomSearchPage extends StatefulWidget {
  const RoomSearchPage({super.key});

  @override
  State<RoomSearchPage> createState() => _RoomSearchPageState();
}

class _RoomSearchPageState extends State<RoomSearchPage> {

  final TextEditingController roomController = TextEditingController();
  String selectedDay = "Saturday";
  TimeOfDay? selectedTime;

  bool isChecking = false;
  String resultMessage = "";

  final List<String> days = [
    "Saturday",
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday"
  ];

  Future<void> checkRoomAvailability() async {
    FocusScope.of(context).unfocus();

    if (roomController.text.isEmpty || selectedTime == null) {
      setState(() {
        resultMessage = "Please enter room and time";
      });
      return;
    }

    setState(() {
      isChecking = true;
      resultMessage = "";
    });

    final int selectedMinutes = selectedTime!.hour * 60 + selectedTime!.minute;
    final String roomInput = roomController.text.trim().toLowerCase();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("routines")
          .where("day", isEqualTo: selectedDay)
          .get();

      bool isOccupied = false;
      String subject = "";
      String batch = "";
      String section = "";
      String timeRange = "";

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // --- ROOM CHECK ---
        final roomField = data['room'];
        String docRoom = '';
        if (roomField != null) docRoom = roomField.toString().trim().toLowerCase();
        if (docRoom != roomInput) continue;

        // --- TIME CHECK ---
        int startMinutes = -1;
        int endMinutes = -1;

        final startRaw = data['startTime'];
        final endRaw = data['endTime'];

        // parse start
        if (startRaw != null) {
          if (startRaw is int) {
            startMinutes = (startRaw ~/ 100) * 60 + (startRaw % 100);
          } else if (startRaw is String) {
            final parts = startRaw.split(':');
            startMinutes = int.parse(parts[0]) * 60 + (parts.length > 1 ? int.parse(parts[1]) : 0);
          }
        }

        // parse end
        if (endRaw != null) {
          if (endRaw is int) {
            endMinutes = (endRaw ~/ 100) * 60 + (endRaw % 100);
          } else if (endRaw is String) {
            final parts = endRaw.split(':');
            endMinutes = int.parse(parts[0]) * 60 + (parts.length > 1 ? int.parse(parts[1]) : 0);
          }
        }

        if (startMinutes < 0 || endMinutes < 0) continue;

        if (selectedMinutes >= startMinutes && selectedMinutes < endMinutes) {
          isOccupied = true;
          subject = data['subject']?.toString() ?? '';
          batch = data['batch']?.toString() ?? '';
          section = data['section']?.toString() ?? '';
          timeRange = '$startRaw - $endRaw';
          break;
        }
      }

      setState(() {
        isChecking = false;
        resultMessage = isOccupied
            ? "❌ Room is Occupied\n\n📚 $subject\n👥 Batch: $batch  Section: $section\n⏰ $timeRange"
            : "✅ Room is Available";
      });
    } catch (e) {
      setState(() {
        isChecking = false;
        resultMessage = "Error: $e";
      });
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Availability"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: "Enter Room Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedDay,
              items: days
                  .map((day) => DropdownMenuItem(
                value: day,
                child: Text(day),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Day",
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: pickTime,
              child: Text(
                selectedTime == null
                    ? "Select Time"
                    : "Time: ${selectedTime!.format(context)}",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isChecking ? null : checkRoomAvailability,
              child: isChecking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Check Availability"),
            ),

            const SizedBox(height: 30),

            if (resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: resultMessage.contains("Available")
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resultMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}