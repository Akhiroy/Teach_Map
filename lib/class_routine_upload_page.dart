import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassRoutineUploadPage extends StatefulWidget {
  const ClassRoutineUploadPage({Key? key}) : super(key: key);

  @override
  State<ClassRoutineUploadPage> createState() => _ClassRoutineUploadPageState();
}

class _ClassRoutineUploadPageState extends State<ClassRoutineUploadPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveLink() async {
    final link = _controller.text.trim();

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Google Sheet link")),
      );
      return;
    }

    if (!link.contains("docs.google.com/spreadsheets")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Google Sheet link")),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _firestore.collection("sheet_links").add({
        "url": link,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving link: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Google Sheet"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header Section
            const Text(
              "Connect Your Google Sheet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Paste your public Google Sheet link below to store and manage it securely using Firebase Firestore.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// Input Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "https://docs.google.com/spreadsheets/...",
                        labelText: "Google Sheet Link",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveLink,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Save to Firestore",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // const SizedBox(height: 40),

            // /// Extra Content to Make Page Awesome

            // const Text(
            //   "Why Use Google Sheets?",
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),

            // const SizedBox(height: 12),

            // _infoTile(
            //   icon: Icons.cloud_done,
            //   title: "Real-time Collaboration",
            //   description:
            //       "Multiple users can edit simultaneously and changes reflect instantly.",
            // ),
            // _infoTile(
            //   icon: Icons.security,
            //   title: "Secure & Reliable",
            //   description:
            //       "Your data is stored safely in the cloud and backed by Google infrastructure.",
            // ),
            // _infoTile(
            //   icon: Icons.auto_graph,
            //   title: "Powerful Data Handling",
            //   description:
            //       "Supports charts, formulas, automation, and large datasets efficiently.",
            // ),

            // const SizedBox(height: 30),

            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.blue.shade50,
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: const Row(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Icon(Icons.info_outline, color: Colors.blue),
            //       SizedBox(width: 12),
            //       Expanded(
            //         child: Text(
            //           "Tip: Make sure your Google Sheet is set to 'Anyone with the link can view' before saving it here.",
            //           style: TextStyle(fontSize: 14),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget _infoTile({
  //   required IconData icon,
  //   required String title,
  //   required String description,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(icon, color: Colors.blue, size: 28),
  //         const SizedBox(width: 14),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                     fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 description,
  //                 style: const TextStyle(color: Colors.grey),
  //               ),
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
}
