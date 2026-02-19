import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController infoController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();

  String userRole = '';
  String imageUrl = '';
  bool isLoading = false;
  bool isUploading = false;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// Load user data from Firestore
  Future<void> loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      departmentController.text = data['department'] ?? '';
      infoController.text = data['info'] ?? '';
      phoneController.text = data['phone'] ?? '';
      studentIdController.text = data['studentId'] ?? '';
      userRole = data['role'] ?? '';
      imageUrl = data['imageUrl'] ?? '';
      setState(() {});
    }
  }

  /// Pick image from gallery & upload to Firebase Storage
  Future<void> _pickAndUploadImage() async {
    if (user == null) return;

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => isUploading = true);

    try {
      File file = File(image.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("${user!.uid}.jpg");

      // Upload file
      await ref.putFile(file);

      // Get download URL
      final uploadedImageUrl = await ref.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({"imageUrl": uploadedImageUrl});

      // Update local state
      setState(() {
        imageUrl = uploadedImageUrl;
        isUploading = false;
      });
    } catch (e) {
      setState(() => isUploading = false);
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  /// Update all user profile fields
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    if (user == null) return;

    Map<String, dynamic> updatedData = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'department': departmentController.text.trim(),
      'info': infoController.text.trim(),
      'phone': phoneController.text.trim(),
      'imageUrl': imageUrl,
    };

    if (userRole.toLowerCase() == 'student') {
      updatedData['studentId'] = studentIdController.text.trim();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update(updatedData);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated Successfully ✅")),
    );

    Navigator.pop(context);
  }

  Widget _profileFieldTile({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 6),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
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
          "Edit Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// PROFILE IMAGE
              Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
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
                        child: isUploading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              /// NAME
              _profileFieldTile(
                title: "Full Name",
                child: TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Enter full name",
                    border: InputBorder.none,
                  ),
                  validator: (value) => value!.isEmpty ? "Enter name" : null,
                ),
              ),

              /// EMAIL
              _profileFieldTile(
                title: "Email",
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Enter email",
                    border: InputBorder.none,
                  ),
                  validator: (value) => value!.isEmpty ? "Enter email" : null,
                ),
              ),

              /// DEPARTMENT
              _profileFieldTile(
                title: "Department",
                child: TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    hintText: "Enter department",
                    border: InputBorder.none,
                  ),
                ),
              ),
              /// STUDENT ID (if student)
              if (userRole.toLowerCase() == 'student') ...[
                _profileFieldTile(
                  title: "Student ID",
                  child: TextFormField(
                    controller: studentIdController,
                    decoration: const InputDecoration(
                      hintText: "Enter student ID",
                      border: InputBorder.none,
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter student ID" : null,
                  ),
                ),
              ],

              /// PHONE
              _profileFieldTile(
                title: "Phone",
                child: TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Enter phone",
                    border: InputBorder.none,
                  ),
                ),
              ),

              /// ADDITIONAL INFO
              _profileFieldTile(
                title: "Additional Info",
                child: TextFormField(
                  controller: infoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter additional info",
                    border: InputBorder.none,
                  ),
                ),
              ),


              const SizedBox(height: 25),

              /// SAVE BUTTON
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xFF4CAF50),
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
