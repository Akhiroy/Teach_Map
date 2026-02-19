import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text("Edit Attendance Info"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: courseController,
                decoration:
                    const InputDecoration(labelText: "Course Name"),
              ),
              TextField(
                controller: batchController,
                decoration:
                    const InputDecoration(labelText: "Batch"),
              ),
              TextField(
                controller: sectionController,
                decoration:
                    const InputDecoration(labelText: "Section"),
              ),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: "Attendance Sheet Link",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Take Attendance"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          data['courseName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text("Batch: ${data['batch']}"),
                            Text("Section: ${data['section']}"),
                          ],
                        ),
                        onTap: () {
                          _openAttendanceLink(
                            context,
                            data['attendanceLink'],
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog(
                              context,
                              docs[index].id,
                              data,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          _AddAttendanceSection(),
        ],
      ),
    );
  }
}

class _AddAttendanceSection extends StatefulWidget {

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text(
            "Add Attendance Session",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          TextField(
            controller: courseController,
            decoration:
                const InputDecoration(labelText: "Course Name"),
          ),
          TextField(
            controller: batchController,
            decoration:
                const InputDecoration(labelText: "Batch"),
          ),
          TextField(
            controller: sectionController,
            decoration:
                const InputDecoration(labelText: "Section"),
          ),
          TextField(
            controller: linkController,
            decoration: const InputDecoration(
              labelText: "Attendance Sheet Link",
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
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
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
