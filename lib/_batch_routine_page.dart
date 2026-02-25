import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BatchRoutinePage extends StatefulWidget {
  const BatchRoutinePage({super.key});

  @override
  State<BatchRoutinePage> createState() => _BatchRoutinePageState();
}

class _BatchRoutinePageState extends State<BatchRoutinePage> {
  final TextEditingController batchController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();

  TimeOfDay? selectedTime;
  bool useCurrentTime = true;

  String? resultText;
  bool isLoading = false;

  final Map<String, String> daySheetMap = {
    "saturday": "997090556",
    "sunday": "255270977",
    "monday": "447521283",
    "tuesday": "1496246527",
    "wednesday": "1383433023",
    "thursday": "739024824",
    "friday": "307287901",
  };

  final String baseSheetUrl =
      "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=";

  /// ================= NORMALIZE TABLE =================
  List<List<String>> normalizeTable(List<List<String>> table) {
    int maxLength = 0;
    for (var row in table) {
      if (row.length > maxLength) maxLength = row.length;
    }

    for (var row in table) {
      while (row.length < maxLength) row.add("");
    }
    return table;
  }

  /// ================= CHECK ROUTINE =================
  Future<void> checkBatchRoutine() async {
    if (batchController.text.isEmpty || sectionController.text.isEmpty) return;

    setState(() {
      isLoading = true;
      resultText = null;
    });

    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now).toLowerCase();
      final gid = daySheetMap[currentDay];

      if (gid == null) {
        setState(() {
          resultText = "No routine found today";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse(baseSheetUrl + gid));
      if (response.statusCode != 200) throw Exception("Failed to load sheet");

      List<List<String>> table = response.body
          .split("\n")
          .map((row) => row.split(","))
          .toList();

      table = normalizeTable(table);

      DateTime checkTime = useCurrentTime
          ? DateTime.now()
          : DateTime(
              now.year,
              now.month,
              now.day,
              selectedTime?.hour ?? 0,
              selectedTime?.minute ?? 0,
            );

      int matchedColumnIndex = -1;
      List<String> header = table[3]; // time header row

      for (int i = 0; i < header.length; i++) {
        if (header[i].contains("-") &&
            isTimeInRange(header[i], checkTime)) {
          matchedColumnIndex = i;
          break;
        }
      }

      if (matchedColumnIndex == -1) {
        setState(() {
          resultText = "No class running";
          isLoading = false;
        });
        return;
      }

      String batch = batchController.text.trim();
      String section = sectionController.text.trim();

      for (int i = 2; i < table.length; i++) {
        // batch = column 2, section = column 3
        if (table[i].length > 2 &&
            table[i][1].trim() == batch &&
            table[i][2].trim() == section) {
          String cell = table[i][matchedColumnIndex];
          setState(() {
            resultText = cell.isEmpty ? "Free" : cell;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        resultText = "Batch or Section not found";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        resultText = "Something went wrong";
        isLoading = false;
      });
    }
  }

  bool isTimeInRange(String range, DateTime checkTime) {
    try {
      final parts = range.split("-");
      if (parts.length != 2) return false;

      DateTime start = parseTime(parts[0]);
      DateTime end = parseTime(parts[1]);

      start = DateTime(checkTime.year, checkTime.month, checkTime.day, start.hour, start.minute);
      end = DateTime(checkTime.year, checkTime.month, checkTime.day, end.hour, end.minute);

      return checkTime.isAfter(start) && checkTime.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  DateTime parseTime(String timeStr) {
    timeStr = timeStr.trim().toUpperCase().replaceAll(".", ":").replaceAll("\"", "");
    if (timeStr.contains("AM") || timeStr.contains("PM")) return DateFormat("h:mm a").parse(timeStr);
    return DateFormat("H:mm").parse(timeStr);
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Batch Running class",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Title Section
            Text(
              "Enter batch and section to see current class status:",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            /// Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                children: [

                  /// Batch Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Batch",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: batchController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Enter batch number",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  /// Section Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Section",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sectionController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Enter section (e.g. A, B)",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Use Current Time
                  Row(
                    children: [
                      Checkbox(
                        value: useCurrentTime,
                        onChanged: (value) {
                          setState(() {
                            useCurrentTime = value!;
                          });
                        },
                      ),
                      const Text(
                        "Use Current Time",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Time Picker
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: useCurrentTime
                          ? null
                          : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Text(
                        selectedTime == null
                            ? "Select Time"
                            : selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// Check Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: checkBatchRoutine,
                child: const Text(
                  "Check current Class",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// Loading
            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            /// Result
            if (resultText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: resultText!.toLowerCase().contains("free")
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: resultText!.toLowerCase().contains("free")
                        ? Colors.blue
                        : Colors.green,
                    width: 1,
                  ),
                ),
                child: Text(
                  resultText!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: resultText!.toLowerCase().contains("free")
                        ? Colors.blue.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}