import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchTeacherPage extends StatefulWidget {
  const SearchTeacherPage({super.key});

  @override
  State<SearchTeacherPage> createState() => _SearchTeacherPageState();
}

class _SearchTeacherPageState extends State<SearchTeacherPage> {
  final TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot> teachers = [];

  Future<void> searchTeacher(String query) async {
    if (query.isEmpty) {
      setState(() => teachers = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      teachers = snapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Teacher")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔍 Search box
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by teacher name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: searchTeacher,
            ),

            const SizedBox(height: 20),

            /// 📋 Result list
            Expanded(
              child: teachers.isEmpty
                  ? const Center(
                      child: Text("No teachers found"),
                    )
                  : ListView.builder(
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        final data =
                            teachers[index].data() as Map<String, dynamic>;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(data['name']),
                            subtitle: Text(data['department']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
