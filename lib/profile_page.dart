import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teachmap/profile_update_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker picker = ImagePicker();
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _createTeacherIfNotExists();
  }

  /// ✅ Auto create teacher document if not exists
  Future<void> _createTeacherIfNotExists() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (!doc.exists) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .set({
        "name": "",
        "department": "",
        "phone": "",
        "imageUrl": "",
        "email": user!.email ?? "",
        "role": "",
        "id": "",
      });
    }
  }

  /// ✅ Pick & Upload Image
  Future<void> _pickAndUploadImage() async {
    if (user == null) return;

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => isUploading = true);

      File file = File(image.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child("teacher_profile_images")
          .child("${user!.uid}.jpg");

      await ref.putFile(file); // upload

      final imageUrl = await ref.getDownloadURL();

      // 🔹 Update Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({"imageUrl": imageUrl});

      setState(() => isUploading = false);
    } catch (e) {
      setState(() => isUploading = false);
      print("Error uploading image: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF027a9c),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- this makes the back arrow white
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid) // must match uploaded image doc
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          String name = data["name"] ?? "";
          String dept = data["department"] ?? "";
          String phone = data["phone"] ?? "";
          String imageUrl = data["imageUrl"] ?? "";
          String role = data["role"] ?? "";
          String studentId = data["id"] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                /// PROFILE IMAGE
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)               // uploaded image
                          : (user!.photoURL != null
                          ? NetworkImage(user!.photoURL!)   // Gmail profile
                          : null),
                      child: (imageUrl.isEmpty && user!.photoURL == null)
                          ? const Icon(Icons.person, size: 65, color: Colors.white)
                          : null,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF027a9c),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isUploading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),

                const SizedBox(height: 25),

                _profileTile("Name",
                    name.isEmpty ? "Not Added" : name),
                const SizedBox(height: 15),

                _profileTile("Department",
                    dept.isEmpty ? "Not Added" : dept),
                const SizedBox(height: 15),

                _profileTile("Phone",
                    phone.isEmpty ? "Not Added" : phone),
                const SizedBox(height: 15),

                _profileTile("Role",
                    role.isEmpty ? "Not Added" : role),
                if (role.toLowerCase() == "student") ...[
                  const SizedBox(height: 15),
                  _profileTile("Student ID",
                      studentId.isEmpty ? "Not Added" : studentId),
                ],
                const SizedBox(height: 15),

                _profileTile("Email", user!.email ?? ""),

                const SizedBox(height: 25),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF027a9c),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileUpdatePage(), // your page class
                      ),
                    );
                  },
                  child: const Text("Edit Profile",
                      style: TextStyle(
                        color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileTile(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
