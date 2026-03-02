import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() =>
      _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState
    extends State<WeeklyTimetablePage> {

  String? selectedAcronym;
  bool isLoading = true;

  late String todayName;

  final ScrollController _scrollController =
  ScrollController();

  /// 🔗 ALL DAYS MAP
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
    loadTeacherAndFetchWeek();
  }

  /// ================= LOAD TEACHER =================
  Future<void> loadTeacherAndFetchWeek() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null &&
          data['shortName'] != null) {
        selectedAcronym = data['shortName'];
        await fetchWeeklyRoutine();
      }
    }
  }

  /// ================= FETCH WEEK FAST =================
  Future<void> fetchWeeklyRoutine() async {
    setState(() => isLoading = true);

    List<Future<void>> futures = [];

    daySheetMap.forEach((day, gid) {
      futures.add(fetchDayRoutine(day, gid));
    });

    await Future.wait(futures);

    setState(() => isLoading = false);

    /// Auto scroll to today
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

  /// ================= FILTER BY TEACHER =================
  List<List<String>> getFilteredRoutine(
      List<List<String>> table) {
    if (table.isEmpty ||
        selectedAcronym == null) return [];

    int headerIndex = table.indexWhere(
            (row) => row.any((cell) =>
            cell
                .toLowerCase()
                .contains("batch")));

    if (headerIndex == -1) return [];

    List<String> header = table[headerIndex];
    List<List<String>> filtered = [header];

    for (int i = headerIndex + 1;
    i < table.length;
    i++) {
      final row = table[i];

      List<String> newRow = [];
      bool hasClass = false;

      for (int j = 0;
      j < header.length;
      j++) {
        String cell =
        j < row.length ? row[j] : "";

        if (j == 0 || j == 1) {
          newRow.add(cell);
        } else {
          if (cell
              .toLowerCase()
              .contains(selectedAcronym!
              .toLowerCase())) {
            newRow.add(cell);
            hasClass = true;
          } else {
            newRow.add("");
          }
        }
      }

      if (hasClass) filtered.add(newRow);
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
          "Weekly Timetable",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        iconTheme:
        const IconThemeData(
            color: Colors.white),
      ),
      body: isLoading
          ? const Center(
          child:
          CircularProgressIndicator())
          : ListView.builder(
        controller: _scrollController,
        padding:
        const EdgeInsets.all(16),
        itemCount:
        daySheetMap.length,
        itemBuilder:
            (context, index) {
          String day =
          daySheetMap.keys
              .elementAt(index);

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

          return AnimatedContainer(
            duration:
            const Duration(
                milliseconds: 400),
            margin:
            const EdgeInsets.only(
                bottom: 18),
            child: Card(
              elevation: 8,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius
                    .circular(20),
              ),
              child: ExpansionTile(
                initiallyExpanded:
                isToday,
                title: Row(
                  children: [
                    Icon(
                      isToday
                          ? Icons.today
                          : Icons
                          .calendar_today,
                      color: isToday
                          ? Colors.teal
                          : Colors.grey,
                    ),
                    const SizedBox(
                        width: 10),
                    Text(
                      day,
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        fontSize: 16,
                        color: isToday
                            ? Colors
                            .teal
                            : Colors
                            .black,
                      ),
                    ),
                  ],
                ),
                childrenPadding:
                const EdgeInsets
                    .all(15),
                children: [
                  SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                      MaterialStateProperty.all(
                          Colors.blue
                              .shade100),
                      border: TableBorder.all(
                          color: Colors
                              .grey
                              .shade300),
                      columns: List<DataColumn>.generate(
                        filtered[0].length,
                            (index) => DataColumn(
                          label: Text(
                            filtered[0][index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      rows: List<DataRow>.generate(
                        filtered.length - 1,
                            (rowIndex) {
                          final row = filtered[rowIndex + 1];

                          return DataRow(
                            cells: List<DataCell>.generate(
                              filtered[0].length,
                                  (cellIndex) {
                                String cell = cellIndex < row.length
                                    ? row[cellIndex]
                                    : "";

                                return DataCell(
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: cellIndex >= 2
                                        ? getCellColor(filtered[0][cellIndex])
                                        : Colors.transparent,
                                    child: Text(cell),
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
            ),
          );
        },
      ),
    );
  }
}