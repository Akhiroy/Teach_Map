import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadRoutinePage extends StatefulWidget {
  const UploadRoutinePage({super.key});

  @override
  State<UploadRoutinePage> createState() => _UploadRoutinePageState();
}

class _UploadRoutinePageState extends State<UploadRoutinePage> {

  final _formKey = GlobalKey<FormState>();

  final teacherController = TextEditingController();
  final subjectController = TextEditingController();
  final classController = TextEditingController();
  final roomController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();
  final linkController = TextEditingController();   // ✅ NEW

  String selectedDay = "Sunday";

  Future<void> uploadRoutine() async {

    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('class_routine').add({
      "teacherShortName": teacherController.text.trim(),
      "day": selectedDay,
      "subject": subjectController.text.trim(),
      "className": classController.text.trim(),
      "room": roomController.text.trim(),
      "startTime": startController.text.trim(),
      "endTime": endController.text.trim(),
      "routineLink": linkController.text.trim(),  // ✅ SAVE LINK
      "createdAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Routine Uploaded Successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Upload Routine",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              /// SECTION TITLE
              const Text(
                "Class Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// CARD CONTAINER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [

                    /// Teacher
                    TextFormField(
                      controller: teacherController,
                      decoration: const InputDecoration(
                        labelText: "Teacher Short Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Required field" : null,
                    ),
                    const SizedBox(height: 18),

                    /// Day Dropdown
                    DropdownButtonFormField(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        labelText: "Select Day",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        "Sunday","Monday","Tuesday",
                        "Wednesday","Thursday","Friday","Saturday"
                      ]
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
                    ),
                    const SizedBox(height: 18),

                    /// Subject
                    TextFormField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// Course Code
                    TextFormField(
                      controller: classController,
                      decoration: const InputDecoration(
                        labelText: "Course Code",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// Room
                    TextFormField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: "Room",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// Start Time
                    TextFormField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: "Start Time (09:00)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// End Time
                    TextFormField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: "End Time (10:00)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// Routine Link
                    TextFormField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: "Routine Link (Google Drive / PDF URL)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final urlPattern =
                              r'^(http|https):\/\/([\w.]+\/?)\S*';
                          if (!RegExp(urlPattern).hasMatch(value)) {
                            return "Enter valid URL";
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: uploadRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Save Routine",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
