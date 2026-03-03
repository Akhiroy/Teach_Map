import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SearchTeacherPage extends StatefulWidget {
  const SearchTeacherPage({super.key});

  @override
  State<SearchTeacherPage> createState() => _SearchTeacherPageState();
}

class _SearchTeacherPageState extends State<SearchTeacherPage> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, String>> allTeachers = [];
  List<Map<String, String>> filteredTeachers = [];

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
    fetchTeachers();
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
  Future<void> fetchTeachers() async {
    allTeachers.clear();
    final response = await http.get(Uri.parse(teacherSheet));
    final responseGED = await http.get(Uri.parse(teacherSheetGED));

    if (response.statusCode == 200) {
      List<String> rows = response.body.split("\n");
      for (int i = 1; i < rows.length; i++) {
        final columns = rows[i].split(",");
        if (columns.length > 3) {
          allTeachers.add({
            "acronym": columns[2].trim(),
            "fullName": columns[3].trim(),
          });
        }
      }

      List<String> rowsGED = responseGED.body.split("\n");
      for (int i = 1; i < rowsGED.length; i++) {
        final columns = rowsGED[i].split(",");
        if (columns.length > 4) {
          allTeachers.add({
            "acronym": columns[3].trim(),
            "fullName": columns[4].trim(),
          });
        }
      }

      setState(() {});
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
          if (cell.contains(selectedAcronym!)) {
            setState(() {
              resultText = cell;
              isCheckingRoutine = false;
            });
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
  /// ================= HIGHLIGHT CURRENT PERIOD =================
  Color getCellColor(String headerTime) {
    try {
      final now = DateTime.now();

      if (!headerTime.contains("-")) {
        return Colors.transparent;
      }

      final parts = headerTime.split("-");

      String startPart = parts[0].trim();
      String endPart = parts[1].trim();

      String period = endPart.contains("AM") ? "AM" : "PM";

      if (!startPart.contains("AM") && !startPart.contains("PM")) {
        startPart = "$startPart $period";
      }

      DateTime startTime = DateFormat("h:mm a").parse(startPart);
      DateTime endTime = DateFormat("h:mm a").parse(endPart);

      startTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      endTime = DateTime(
        now.year,
        now.month,
        now.day,
        endTime.hour,
        endTime.minute,
      );

      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return Colors.amber.shade300;
      }
    } catch (e) {
      return Colors.transparent;
    }

    return Colors.transparent;
  }

  /// ================= FILTER ONLY SELECTED TEACHER ROUTINE =================
  List<List<String>> getTeacherRoutine() {
    if (todayRoutine.isEmpty || selectedAcronym == null) return [];

    int headerIndex = todayRoutine.indexWhere(
          (row) => row.any((cell) => cell.toLowerCase().contains("batch")),
    );

    if (headerIndex == -1) return [];

    List<String> header = todayRoutine[headerIndex];
    List<List<String>> filtered = [header];

    for (int i = headerIndex + 1; i < todayRoutine.length; i++) {
      final row = todayRoutine[i];

      if (row.length < 2) continue;

      List<String> newRow = [];
      bool hasClass = false;

      for (int j = 0; j < header.length; j++) {
        String cell = j < row.length ? row[j] : "";

        if (j == 0 || j == 1) {
          newRow.add(cell);
        } else {
          if (cell
              .toLowerCase()
              .contains(selectedAcronym!.toLowerCase())) {
            newRow.add(cell);
            hasClass = true;
          } else {
            newRow.add("");
          }
        }
      }

      if (hasClass) {
        filtered.add(newRow);
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
        elevation: 0,
        backgroundColor: Color(0xFF027a9c),
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow color
        ),
        title: const Text(
          "Search Teacher",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchTeachers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔍 SEARCH FIELD
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name or acronym...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: searchTeacher,
                ),
              ),

              const SizedBox(height: 20),

              /// SEARCH RESULTS
              if (filteredTeachers.isNotEmpty)
                Container(
                  height: 220,
                  child: ListView.builder(
                    itemCount: filteredTeachers.length,
                    itemBuilder: (context, index) {
                      final teacher = filteredTeachers[index];

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                teacher['acronym']![0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              teacher['fullName']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                            Text("Acronym: ${teacher['acronym']}"),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 18),
                            onTap: () {
                              selectedAcronym = teacher['acronym'];
                              searchController.text =
                              teacher['fullName']!;
                              filteredTeachers = [];
                              setState(() {});
                              checkCurrentClass();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 25),

              /// LOADING
              if (isCheckingRoutine)
                const Center(child: CircularProgressIndicator()),

              /// RESULT CARD
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

              /// FULL DAY ROUTINE TABLE
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
                            headingRowColor:
                            MaterialStateProperty.all(Colors.blue.shade100),
                            border:
                            TableBorder.all(color: Colors.grey.shade300),

                            columns: teacherRoutine[0]
                                .map(
                                  (header) => DataColumn(
                                label: Text(
                                  header,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                                .toList(),

                            rows: teacherRoutine.length > 1
                                ? teacherRoutine
                                .skip(1)
                                .map(
                                  (row) => DataRow(
                                cells: List.generate(
                                  teacherRoutine[0].length,
                                      (index) {
                                    String cellText =
                                    index < row.length
                                        ? row[index]
                                        : "";

                                    return DataCell(
                                      Container(
                                        padding:
                                        const EdgeInsets.all(8),
                                        color: index >= 2
                                            ? getCellColor(
                                            teacherRoutine[0][index])
                                            : Colors.transparent,
                                        child: Text(cellText),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                                .toList()
                                : [],
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