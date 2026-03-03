import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class StudentWeeklyTimetablePage extends StatefulWidget {
  const StudentWeeklyTimetablePage({super.key});

  @override
  State<StudentWeeklyTimetablePage> createState() =>
      _StudentWeeklyTimetablePageState();
}

class _StudentWeeklyTimetablePageState
    extends State<StudentWeeklyTimetablePage> {

  final TextEditingController batchController =
  TextEditingController();
  final TextEditingController sectionController =
  TextEditingController();

  bool isLoading = false;
  bool hasSearched = false;

  late String todayName;

  final ScrollController _scrollController =
  ScrollController();

  /// ALL DAYS MAP
  final Map<String, String> daySheetMap = {
    "Saturday": "997090556",
    "Sunday": "255270977",
    "Monday": "447521283",
    "Tuesday": "1496246527",
    "Wednesday": "1383433023",
    "Thursday": "739024824",
    "Friday": "307287901",
  };

  Map<String, List<List<String>>> weeklyRoutine =
  {};

  @override
  void initState() {
    super.initState();
    todayName =
        DateFormat('EEEE').format(DateTime.now());
  }

  /// ================= FETCH WEEK =================
  Future<void> fetchWeeklyRoutine() async {
    if (batchController.text.isEmpty ||
        sectionController.text.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    weeklyRoutine.clear();

    List<Future<void>> futures = [];

    daySheetMap.forEach((day, gid) {
      futures.add(fetchDayRoutine(day, gid));
    });

    await Future.wait(futures);

    setState(() => isLoading = false);

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      int index = daySheetMap.keys
          .toList()
          .indexOf(todayName);
      if (index != -1) {
        _scrollController.animateTo(
          index * 220.0,
          duration:
          const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchDayRoutine(
      String day, String gid) async {
    final url =
        "https://docs.google.com/spreadsheets/d/1jjOmSUg3U_uyzM0mtaj1FldEOD1nNeMCAhybEiQTW3M/export?format=csv&gid=$gid";

    final response =
    await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<List<String>> table = response.body
          .split("\n")
          .map((row) => row.split(","))
          .toList();

      weeklyRoutine[day] =
          normalizeTable(table);
    }
  }

  /// ================= NORMALIZE =================
  List<List<String>> normalizeTable(
      List<List<String>> table) {
    int maxLength = 0;
    for (var row in table) {
      if (row.length > maxLength)
        maxLength = row.length;
    }
    for (var row in table) {
      while (row.length < maxLength) {
        row.add("");
      }
    }
    return table;
  }

  /// ================= FILTER BY BATCH + SECTION =================
  List<List<String>> getFilteredRoutine(
      List<List<String>> table) {

    if (table.isEmpty) return [];

    String batch =
    batchController.text.trim().toLowerCase();
    String section =
    sectionController.text.trim().toLowerCase();

    int headerIndex = table.indexWhere(
            (row) => row.any((cell) =>
            cell.toLowerCase().contains("batch")));

    if (headerIndex == -1) return [];

    List<String> originalHeader = table[headerIndex];

    //  REMOVE DAY COLUMN (index 0)
    List<String> header =
    originalHeader.sublist(1);

    List<List<String>> filtered = [header];

    for (int i = headerIndex + 1;
    i < table.length;
    i++) {

      final row = table[i];

      if (row.length < 3) continue;

      String rowBatch =
      row[1].trim().toLowerCase();
      String rowSection =
      row[2].trim().toLowerCase();

      if (rowBatch == batch &&
          rowSection == section) {

        // REMOVE DAY COLUMN
        filtered.add(row.sublist(1));
        break;
      }
    }

    return filtered;
  }

  /// ================= TIME HIGHLIGHT =================
  Color getCellColor(String headerTime) {
    try {
      final now = DateTime.now();

      if (!headerTime.contains("-"))
        return Colors.transparent;

      final parts = headerTime.split("-");

      DateTime start =
      DateFormat("h:mm a")
          .parse(parts[0].trim());
      DateTime end =
      DateFormat("h:mm a")
          .parse(parts[1].trim());

      start = DateTime(now.year, now.month,
          now.day, start.hour, start.minute);
      end = DateTime(now.year, now.month,
          now.day, end.hour, end.minute);

      if (now.isAfter(start) &&
          now.isBefore(end)) {
        return Colors.amber.shade200;
      }
    } catch (_) {}

    return Colors.transparent;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "Student Weekly Timetable",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(
          color: Colors.white, //Back arrow color
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SEARCH CARD
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(18),
              ),
              elevation: 6,
              child: Padding(
                padding:
                const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller:
                      batchController,
                      decoration:
                      const InputDecoration(
                        labelText: "Enter Batch",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller:
                      sectionController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        "Enter Section",
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                      fetchWeeklyRoutine,
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:Colors.deepPurple,
                      ),
                      child: const Text(
                        "Search Routine",
                        style: TextStyle(
                            color:
                            Colors.white,fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (hasSearched && !isLoading)
              ...daySheetMap.keys.map((day) {

                final table =
                weeklyRoutine[day];
                final filtered =
                table != null
                    ? getFilteredRoutine(
                    table)
                    : [];

                if (filtered.isEmpty)
                  return const SizedBox();

                bool isToday =
                    day == todayName;

                return Card(
                  margin:
                  const EdgeInsets.only(
                      bottom: 16),
                  elevation: 6,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(18),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded:
                    isToday,
                    title: Text(
                      day,
                      style: const TextStyle(
                          fontWeight:
                          FontWeight.bold),
                    ),
                    children: [
                      SingleChildScrollView(
                        scrollDirection:
                        Axis.horizontal,
                        child: DataTable(
                          columns:
                          List<DataColumn>.generate(
                            filtered[0].length,
                                (index) =>
                                DataColumn(
                                  label: Text(
                                    filtered[0]
                                    [index],
                                    style:
                                    const TextStyle(
                                        fontWeight:
                                        FontWeight.bold),
                                  ),
                                ),
                          ),
                          rows:
                          List<DataRow>.generate(
                            filtered.length -
                                1,
                                (rowIndex) {
                              final row =
                              filtered[
                              rowIndex +
                                  1];

                              return DataRow(
                                cells: List<DataCell>.generate(
                                  filtered[0]
                                      .length,
                                      (cellIndex) {
                                    String cell =
                                    cellIndex <
                                        row.length
                                        ? row[
                                    cellIndex]
                                        : "";

                                    return DataCell(
                                      Container(
                                        padding:
                                        const EdgeInsets.all(8),
                                        color: cellIndex >=
                                            2
                                            ? getCellColor(filtered[0][cellIndex])
                                            : Colors.transparent,
                                        child:
                                        Text(cell),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}