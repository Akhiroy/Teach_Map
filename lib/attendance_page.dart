// import 'dart:io';
// import 'package:flutter/material.dart';
// // import 'package:file_picker/file_picker.dart';
// // import 'package:excel/excel.dart';
// import 'attendance_service.dart';

// class AttendancePage extends StatefulWidget {
//   const AttendancePage({super.key});

//   @override
//   State<AttendancePage> createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage> {
//   final AttendanceService _attendanceService = AttendanceService();
//   final String docId = "attendance_today";

//   final courseNameController = TextEditingController();
//   final courseCodeController = TextEditingController();
//   final sectionController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Take Attendance"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [

//             /// COURSE INFO
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: courseNameController,
//                       decoration: const InputDecoration(
//                         labelText: "Course Name",
//                       ),
//                     ),
//                     TextField(
//                       controller: courseCodeController,
//                       decoration: const InputDecoration(
//                         labelText: "Course Code",
//                       ),
//                     ),
//                     TextField(
//                       controller: sectionController,
//                       decoration: const InputDecoration(
//                         labelText: "Section",
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     ElevatedButton(
//                       onPressed: () async {
//                         await _attendanceService.createAttendance(
//                           docId: docId,
//                           courseName: courseNameController.text,
//                           courseCode: courseCodeController.text,
//                           teacherEmail: "teacher@gmail.com",
//                           date: DateTime.now().toString(),
//                         );
//                       },
//                       child: const Text("Start Attendance"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 10),

//             /// 📂 EXCEL UPLOAD BUTTON
//             ElevatedButton.icon(
//               icon: const Icon(Icons.upload_file),
//               label: const Text("Upload Excel File"),
//               onPressed: _pickExcelFile,
//             ),

//             const SizedBox(height: 10),

//             /// STUDENT LIST
//             Expanded(
//               child: StreamBuilder(
//                 stream: _attendanceService.getStudents(docId),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(
//                       child: CircularProgressIndicator(),
//                     );
//                   }

//                   final students = snapshot.data!.docs;

//                   if (students.isEmpty) {
//                     return const Center(
//                       child: Text("No students found"),
//                     );
//                   }

//                   return ListView.builder(
//                     itemCount: students.length,
//                     itemBuilder: (context, index) {
//                       final student = students[index];

//                       return ListTile(
//                         title: Text(student['name']),
//                         subtitle: Text("ID: ${student.id}"),
//                         trailing: Switch(
//                           value: student['present'],
//                           onChanged: (value) async {
//                             await _attendanceService
//                                 .markStudentAttendance(
//                               docId: docId,
//                               studentId: student.id,
//                               studentName: student['name'],
//                               present: value,
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// 📄 PICK & READ EXCEL
//   // Future<void> _pickExcelFile() async {
//   //   final result = await FilePicker.platform.pickFiles(
//   //     type: FileType.custom,
//   //     allowedExtensions: ['xlsx'],
//   //   );

//   //   if (result == null) return;

//   //   final file = File(result.files.single.path!);
//   //   final bytes = file.readAsBytesSync();
//   //   final excel = Excel.decodeBytes(bytes);

//   //   for (var table in excel.tables.keys) {
//   //     for (var row in excel.tables[table]!.rows.skip(1)) {
//   //       final id = row[0]?.value.toString();
//   //       final name = row[1]?.value.toString();

//   //       if (id != null && name != null) {
//   //         await _attendanceService.markStudentAttendance(
//   //           docId: docId,
//   //           studentId: id,
//   //           studentName: name,
//   //           present: false,
//   //         );
//   //       }
//   //     }
//   //   }

//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     const SnackBar(
//   //       content: Text("Excel students imported successfully"),
//   //     ),
//   //   );
//   // }
// }
