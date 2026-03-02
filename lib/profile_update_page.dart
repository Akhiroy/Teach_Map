import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController shortNameController = TextEditingController();
  final TextEditingController infoController = TextEditingController();

  String userRole = "";
  String selectedDept = "CSE";
  bool isLoading = false;

  final RegExp nameRegex = RegExp(r'^[a-zA-Z ]{3,}$');
  final RegExp phoneRegex = RegExp(r'^(?:\+8801|01)[3-9]\d{8}$');
  final RegExp studentIdRegex = RegExp(r'^018\d{0,13}$');

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    studentIdController.dispose();
    shortNameController.dispose();
    infoController.dispose();
    super.dispose();
  }

  /// Load existing user data from Firestore
  Future<void> loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      userRole = data['role'] ?? "";
      nameController.text = data['name'] ?? "";
      phoneController.text = data['phone'] ?? "";
      studentIdController.text = data['studentId'] ?? "";
      shortNameController.text = data['shortName'] ?? "";
      infoController.text = data['info'] ?? "";
      selectedDept = data['department'] ?? "CSE";
    });
  }

  /// Update profile in Firestore
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    if (user == null) return;

    final updatedData = {
      'name': nameController.text.trim(),
      'department': selectedDept,
      'info': infoController.text.trim(),
      'phone': phoneController.text.trim(),
      'imageUrl': 'img/profileIcon.png', // fixed image
    };

    if (userRole.toLowerCase() == 'student') {
      updatedData['studentId'] = studentIdController.text.trim();
    }
    if (userRole.toLowerCase() == 'teacher') {
      updatedData['shortName'] = shortNameController.text.trim();
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(updatedData);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully ✅")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        title: const Text(
          "Update Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF027a9c),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// Fixed Profile Image
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: const AssetImage('img/profileIcon.png'),
              ),
              const SizedBox(height: 25),

              /// Name
              _profileInputTile("Name", nameController, Icons.person,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter name";
                    if (!nameRegex.hasMatch(v)) return "Enter valid name";
                    return null;
                  }),
              const SizedBox(height: 15),

              /// Student ID
              if (userRole.toLowerCase() == 'student')
                _profileInputTile("Student ID", studentIdController, Icons.badge,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter ID";
                      if (!studentIdRegex.hasMatch(v)) return "ID must start with 018";
                      return null;
                    }),
              if (userRole.toLowerCase() == 'student') const SizedBox(height: 15),

              /// Short Name
              if (userRole.toLowerCase() == 'teacher')
                _profileInputTile("Short Name", shortNameController, Icons.short_text,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter short name";
                      if (v.length < 2) return "Too short";
                      return null;
                    }),
              if (userRole.toLowerCase() == 'teacher') const SizedBox(height: 15),

              /// Department Dropdown
              _departmentTile(),
              const SizedBox(height: 15),

              /// Phone
              _profileInputTile("Phone", phoneController, Icons.phone,
                  keyboardType: TextInputType.phone, validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!phoneRegex.hasMatch(v)) return "Enter valid phone";
                    return null;
                  }),
              const SizedBox(height: 25),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF027a9c),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Department dropdown styled like _profileInputTile
  Widget _departmentTile() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Department",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: selectedDept,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: const [
              DropdownMenuItem(value: "CSE", child: Text("CSE")),
              DropdownMenuItem(value: "EEE", child: Text("EEE")),
              DropdownMenuItem(value: "LAW", child: Text("LAW")),
              DropdownMenuItem(value: "CIVIL", child: Text("CIVIL")),
              DropdownMenuItem(value: "ENGLISH", child: Text("ENGLISH")),
            ],
            onChanged: (value) => setState(() => selectedDept = value!),
          ),
        ],
      ),
    );
  }

  /// Input field tile
  Widget _profileInputTile(String title, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: _inputDecoration(icon), // only icon, no labelText
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}