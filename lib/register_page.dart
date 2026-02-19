import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final deptController = TextEditingController();
  final shortNameController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  String role = "Student";
  String selectedDept = "CSE";

  // 👁️ show / hide
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Regex
  final RegExp emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  final RegExp passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$');

  // ID: starts with 018, max 16 digits
  final RegExp idRegex = RegExp(r'^018\d{0,13}$');

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF027a9c),
              Color(0xFF6EC6DC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),


                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          /// Role
                          DropdownButtonFormField<String>(
                            value: role,
                            decoration:
                            inputStyle("Role", Icons.person_outline),
                            items: const [
                              DropdownMenuItem(
                                  value: "Student", child: Text("Student")),
                              DropdownMenuItem(
                                  value: "Teacher", child: Text("Teacher")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                role = value!;
                                if (role == "Teacher") {
                                  idController.clear();
                                } else {
                                  shortNameController.clear();
                                }
                              });
                            },

                          ),
                          const SizedBox(height: 14),

                          /// ID (Only for Student)
                          if (role == "Student") ...[
                            TextFormField(
                              controller: idController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                              ],
                              decoration: inputStyle("ID", Icons.badge),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Enter ID";
                                }
                                if (!idRegex.hasMatch(v)) {
                                  return "ID must start with 018 and max 16 digits";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],


                          /// Name
                          TextFormField(
                            controller: nameController,
                            decoration: inputStyle("Name", Icons.person),
                            validator: (v) =>
                            v == null || v.length < 3
                                ? "Enter valid name"
                                : null,
                          ),
                          const SizedBox(height: 14),

                          /// Short Name (Only for Teacher)
                          if (role == "Teacher") ...[
                            TextFormField(
                              controller: shortNameController,
                              decoration: inputStyle("Short Name", Icons.short_text),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Enter short name";
                                }
                                if (v.length < 2) {
                                  return "Short name too short";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],



                          /// Department
                          DropdownButtonFormField<String>(
                            value: selectedDept,
                            decoration:
                            inputStyle("Department", Icons.apartment),
                            items: const [
                              DropdownMenuItem(
                                  value: "CSE", child: Text("CSE")),
                              DropdownMenuItem(
                                  value: "EEE", child: Text("EEE")),
                              DropdownMenuItem(
                                  value: "LAW", child: Text("LAW")),
                              DropdownMenuItem(
                                  value: "CIVIL", child: Text("CIVIL")),
                              DropdownMenuItem(
                                  value: "ENGLISH", child: Text("ENGLISH")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedDept = value!;
                                deptController.text = value;
                              });
                            },
                            validator: (v) =>
                            v == null || v.isEmpty
                                ? "Select department"
                                : null,
                          ),
                          const SizedBox(height: 14),

                          /// Email
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: inputStyle("Email", Icons.email),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Enter email";
                              }
                              if (!emailRegex.hasMatch(v)) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          /// Password
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration:
                            inputStyle("Password", Icons.lock).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Enter password";
                              }
                              if (!passwordRegex.hasMatch(v)) {
                                return "Min 8 chars, upper, lower & number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          /// Confirm Password
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: inputStyle(
                                "Confirm Password", Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v != passwordController.text) {
                                return "Password not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          /// Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF027a9c),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .createUserWithEmailAndPassword(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );

                                    User? user = userCredential.user;

                                    await user!.sendEmailVerification();

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .set({
                                      'email': emailController.text.trim(),
                                      'name': nameController.text.trim(),
                                      'department': selectedDept,
                                      'role': role.toLowerCase(),
                                      'id': role == "Student"
                                          ? idController.text.trim()
                                          : null,
                                      'shortName': role == "Teacher"
                                          ? shortNameController.text.trim()
                                          : null,
                                      'createdAt': Timestamp.now(),
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Registration successful! Verify your email.")),
                                    );

                                    await FirebaseAuth.instance.signOut();

                                    Navigator.pop(context);

                                  } on FirebaseAuthException catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message ?? "Registration failed")),
                                    );
                                  }
                                }
                              },

                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
