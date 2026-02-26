import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'attendance_page.dart';

class AttendanceListPage extends StatelessWidget {
  const AttendanceListPage({super.key});

  Future<void> _openAttendanceLink(
      BuildContext context, String link) async {
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No attendance link found")),
      );
      return;
    }

    final Uri uri = Uri.parse(link);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  void _showEditDialog(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      ) {
    final courseController =
    TextEditingController(text: data['courseName']);
    final batchController =
    TextEditingController(text: data['batch']);
    final sectionController =
    TextEditingController(text: data['section']);
    final linkController =
    TextEditingController(text: data['attendanceLink']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text("Edit Attendance Session"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _styledField(courseController, "Course Name"),
              _styledField(batchController, "Batch"),
              _styledField(sectionController, "Section"),
              _styledField(linkController, "Attendance Sheet Link"),
            ],
          ),
        ),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: const Text("Cancel"),
          // ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFf45648),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 7,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFf45648),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('attendance_sessions')
                  .doc(docId)
                  .update({
                'courseName': courseController.text,
                'batch': batchController.text,
                'section': sectionController.text,
                'attendanceLink': linkController.text,
              });
              Navigator.pop(context);
            },
            child: const Text("Save",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _styledField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Take Attendance",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),),
        backgroundColor: Color(0xFFf45648),
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 Back arrow color
        ),
        centerTitle: true,
        elevation: 3,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance_sessions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No attendance sessions found"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 6,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          data['courseName'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Batch: ${data['batch'] ?? ''}",
                                style: const TextStyle(
                                    color: Colors.black87),
                              ),
                              Text(
                                "Section: ${data['section'] ?? ''}",
                                style: const TextStyle(
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFFf45648)),
                            onPressed: () {
                              _showEditDialog(
                                context,
                                docs[index].id,
                                data,
                              );
                            },
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendancePage(
                                courseName:
                                data['courseName'] ?? '',
                                batch: data['batch'] ?? '',
                                section:
                                data['section'] ?? '',
                                attendanceLink:
                                data['attendanceLink'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(thickness: 1.2),
          const _AddAttendanceSection(),
        ],
      ),
    );
  }
}

class _AddAttendanceSection extends StatefulWidget {
  const _AddAttendanceSection();

  @override
  State<_AddAttendanceSection> createState() =>
      _AddAttendanceSectionState();
}

class _AddAttendanceSectionState
    extends State<_AddAttendanceSection> {
  final courseController = TextEditingController();
  final batchController = TextEditingController();
  final sectionController = TextEditingController();
  final linkController = TextEditingController();

  Widget _styledField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
          )
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Add Attendance Session",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFFf45648),
            ),
          ),
          const SizedBox(height: 10),
          _styledField(courseController, "Course Name"),
          _styledField(batchController, "Batch"),
          _styledField(sectionController, "Section"),
          _styledField(linkController, "Attendance Sheet Link"),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Color(0xFFf45648),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('attendance_sessions')
                    .add({
                  'courseName': courseController.text,
                  'batch': batchController.text,
                  'section': sectionController.text,
                  'attendanceLink': linkController.text,
                });

                courseController.clear();
                batchController.clear();
                sectionController.clear();
                linkController.clear();
              },
              child: const Text(
                "Add Session",
                style: TextStyle(fontSize: 16,color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}