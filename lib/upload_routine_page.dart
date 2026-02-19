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
      appBar: AppBar(
        title: const Text("Upload Routine",
            style:TextStyle(color:Colors.white, fontSize: 22)),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- this makes the back arrow white
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              TextFormField(
                controller: teacherController,
                decoration: const InputDecoration(labelText: "Teacher Short Name"),
                validator: (value) =>
                value!.isEmpty ? "Required field" : null,
              ),

              DropdownButtonFormField(
                value: selectedDay,
                items: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                    .map((day) => DropdownMenuItem(
                  value: day,
                  child: Text(day),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDay = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Select Day"),
              ),

              TextFormField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject"),
              ),

              TextFormField(
                controller: classController,
                decoration: const InputDecoration(labelText: "Course Code"),
              ),

              TextFormField(
                controller: roomController,
                decoration: const InputDecoration(labelText: "Room"),
              ),

              TextFormField(
                controller: startController,
                decoration: const InputDecoration(labelText: "Start Time (09:00)"),
              ),

              TextFormField(
                controller: endController,
                decoration: const InputDecoration(labelText: "End Time (10:00)"),
              ),

              // ✅ NEW LINK FIELD
              TextFormField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: "Routine Link (Google Drive / PDF URL)",
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

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: uploadRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text("Save",
                    style:TextStyle(color:Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
