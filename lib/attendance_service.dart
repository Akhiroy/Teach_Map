import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 CREATE / WRITE
  Future<void> createAttendance({
    required String docId,
    required String courseName,
    required String courseCode,
    required String teacherEmail,
    required String date,
  }) async {
    await _firestore.collection("attendance").doc(docId).set({
      "courseName": courseName,
      "courseCode": courseCode,
      "teacherEmail": teacherEmail,
      "date": date,
    });
  }

  /// 🔹 CREATE / UPDATE student attendance
  Future<void> markStudentAttendance({
    required String docId,
    required String studentId,
    required String studentName,
    required bool present,
  }) async {
    await _firestore
        .collection("attendance")
        .doc(docId)
        .collection("students")
        .doc(studentId)
        .set({
      "name": studentName,
      "present": present,
    });
  }

  /// 🔹 READ (single attendance)
  Future<DocumentSnapshot> getAttendance(String docId) async {
    return await _firestore.collection("attendance").doc(docId).get();
  }

  /// 🔹 READ students list
  Stream<QuerySnapshot> getStudents(String docId) {
    return _firestore
        .collection("attendance")
        .doc(docId)
        .collection("students")
        .snapshots();
  }

  /// 🔹 UPDATE attendance header
  Future<void> updateAttendance({
    required String docId,
    required String courseName,
  }) async {
    await _firestore.collection("attendance").doc(docId).update({
      "courseName": courseName,
    });
  }

  /// 🔹 DELETE student
  Future<void> deleteStudent({
    required String docId,
    required String studentId,
  }) async {
    await _firestore
        .collection("attendance")
        .doc(docId)
        .collection("students")
        .doc(studentId)
        .delete();
  }

  /// 🔹 DELETE full attendance
  Future<void> deleteAttendance(String docId) async {
    await _firestore.collection("attendance").doc(docId).delete();
  }
}
