import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class StudentRoutinePage extends StatefulWidget {
  const StudentRoutinePage({super.key});

  @override
  State<StudentRoutinePage> createState() => _StudentRoutinePageState();
}

class _StudentRoutinePageState extends State<StudentRoutinePage> {
  final TextEditingController batchController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();

  String? resultText;
  bool isCheckingRoutine = false;
  List<List<String>> todayRoutine = [];

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

  /// ================= CHECK BATCH ROUTINE =================
  Future<void> checkBatchRoutine() async {
    if (batchController.text.isEmpty || sectionController.text.isEmpty) return;

    setState(() {
      isCheckingRoutine = true;
      resultText = null;
      todayRoutine = [];
    });

    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now).toLowerCase();
      final gid = daySheetMap[currentDay];

      if (gid == null) {
        setState(() {
          resultText = "No routine today";
          isCheckingRoutine = false;
        });
        return;
      }

      final response = await http.get(Uri.parse(baseSheetUrl + gid));
      if (response.statusCode != 200) throw Exception("Failed to load routine");

      List<List<String>> table = response.body
          .split("\n")
          .map((row) => row.split(","))
          .toList();

      todayRoutine = normalizeTable(table);

      // Batch = Column 1, Section = Column 2
      String batch = batchController.text.trim();
      String section = sectionController.text.trim();

      int matchedColumnIndex = -1;
      List<String> header = todayRoutine[3]; // time header

      for (int i = 0; i < header.length; i++) {
        if (header[i].contains("-") && isTimeInRange(header[i])) {
          matchedColumnIndex = i;
          break;
        }
      }

      if (matchedColumnIndex == -1) {
        setState(() {
          resultText = "No class running";
          isCheckingRoutine = false;
        });
        return;
      }

      bool found = false;
      for (int i = 2; i < todayRoutine.length; i++) {
        if (todayRoutine[i].length > 2 &&
            todayRoutine[i][1].trim() == batch &&
            todayRoutine[i][2].trim() == section) {
          String cell = todayRoutine[i][matchedColumnIndex];
          setState(() {
            resultText = cell.isEmpty ? "Free" : cell;
            isCheckingRoutine = false;
          });
          found = true;
          break;
        }
      }

      if (!found) {
        setState(() {
          resultText = "Batch or Section not found";
          isCheckingRoutine = false;
        });
      }
    } catch (e) {
      setState(() {
        resultText = "Something went wrong";
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

      start = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      end = DateTime(now.year, now.month, now.day, end.hour, end.minute);

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

    if (timeStr.contains("AM") || timeStr.contains("PM")) {
      return DateFormat("h:mm a").parse(timeStr);
    }

    DateTime temp = DateFormat("H:mm").parse(timeStr);
    String period = (temp.hour >= 9 && temp.hour <= 11) ? " AM" : " PM";
    return DateFormat("h:mm a").parse(timeStr + period);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF027a9c),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Student Routine",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔢 Batch
            TextField(
              controller: batchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Batch Number",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// 🅰 Section
            TextField(
              controller: sectionController,
              decoration: InputDecoration(
                labelText: "Section",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// ⏳ Check Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: checkBatchRoutine,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Check Routine"),
              ),
            ),

            const SizedBox(height: 25),

            /// ⏳ Loading
            if (isCheckingRoutine)
              const Center(child: CircularProgressIndicator()),

            /// 📌 Result Card
            if (resultText != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: resultText!.toLowerCase().contains("free")
                      ? LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade500],
                  )
                      : LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
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
                      resultText!.toLowerCase().contains("free")
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
                      resultText!.toLowerCase().contains("free")
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

            /// 📅 Full Day Routine Table
            if (todayRoutine.isNotEmpty)
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
                          columns: todayRoutine[0]
                              .map((header) => DataColumn(
                            label: Text(
                              header,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                              .toList(),
                          rows: todayRoutine
                              .sublist(1)
                              .map((row) => DataRow(
                            cells: row.map((cell) => DataCell(Text(cell))).toList(),
                          ))
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
    );
  }
}