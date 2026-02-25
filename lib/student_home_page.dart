import 'package:flutter/material.dart' hide Badge;
import 'package:teachmap/profile_page.dart';
import 'package:teachmap/student_routine_page.dart';
import 'package:teachmap/widget/smart_tile.dart';
import '_batch_routine_page.dart';
import 'class_routine_upload _student.dart';
import 'search_teacher_page.dart';
import 'package:badges/badges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F4F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF027a9c),
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 Back arrow color
        ),
        title: const Text(
          "Student Dashboard 🧑‍🎓",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),

      body: _dashboardContent(), // moved body to separate method

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF027a9c),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            showSnackBar(context, "Notifications coming soon 🚧");
          }
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Badge(
              badgeContent: const Text(
                '3',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications),
            ),
            label: "Notifications",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  /// Dashboard Page (Original Student Home Content)
  Widget _dashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        /// 🔹 Welcome Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF027a9c), Color(0xFF027a9c)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, size: 34, color: Color(0xFF027a9c)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome back 👋",
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 6),
                    Text("Student",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text("Track your teachers & classes easily",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),
        const Text("Features",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        /// 🔍 Search Teacher
        SmartTile(
          context,
          icon: Icons.search,
          color: Colors.blue,
          title: "Search Teacher",
          subtitle: "Find teacher by name or department",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchTeacherPage(),
              ),
            );
          },
        ),

        SmartTile(
          context,
          icon: Icons.location_on,
          color: Colors.red,
          title: "Room Search",
          subtitle: "View which rooms are free now",
        ),

        SmartTile(
          context,
          icon: Icons.class_,
          color: Colors.green,
          title: "Current Class",
          subtitle: "See which class running now",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BatchRoutinePage(),
              ),
            );
          },
        ),


        SmartTile(
          context,
          icon: Icons.calendar_month,
          color: Colors.purple,
          title: "Weekly Timetable",
          subtitle: "View Batch wise weekly class schedule",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentRoutinePage(),
              ),
            );
          },
        ),


        SmartTile(
          context,
          icon: Icons.calendar_month,
          color: Colors.blueGrey,
          title: "Upload Class Routine",
          subtitle: "Schedule",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClassRoutineUploadPage(),
              ),
            );
          },
        ),
      ],
    );
  }


  /// Teacher Profile Page
  Widget _teacherProfilePage() {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://example.com/teacher.jpg'),
            ),
            title: const Text('Akhi Roy'),
            subtitle: const Text('Math Teacher'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Small Info Card
  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.12 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  /// Snackbar
  void showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
