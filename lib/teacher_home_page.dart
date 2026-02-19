import 'package:flutter/material.dart';
import 'package:teachmap/today_schedule_page.dart';
import 'package:teachmap/upload_routine_page.dart';
import 'package:teachmap/weekly_timetable_page.dart';
import 'attendance_list_page.dart';
import 'profile_update_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:badges/badges.dart' as badges;
import 'profile_page.dart';



class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}


class _TeacherHomePageState extends State<TeacherHomePage> {
  String currentStatus = "Available";
  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: badges.Badge(
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



      backgroundColor: const Color(0xffF7F8FA), // soft background
      appBar: AppBar(
        title: const Text("👨‍🏫 Teacher Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF027a9c),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false, // removes all previous routes
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 👋 Welcome Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.school, size: 34, color: Color(0xFF5B6CFF)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome Teacher 👩‍🏫",
                          style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text("Manage your classes and status",
                          style: TextStyle(color: Colors.black54, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔄 Current Status Card
          _buildStatusCard(),

          const SizedBox(height: 20),

          /// Features Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _featureCard(
                Icons.person,
                "Update Profile",
                const Color(0xFF4CAF50),
                "Edit name, department, info",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileUpdatePage(),
                    ),
                  );
                },
              ),

              _featureCard(
                Icons.schedule,
                "Today's Schedule",
                Color(0xFFFF9800),
                "View today’s classes",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TodaySchedulePage(),
                    ),
                  );
                },
              ),


              _featureCard(Icons.location_on, "Live Location", Color(0xFFF44336), "Auto-update your location", () {
                showSnackBar(context, "Location tracking coming soon 🚧");
              }),
              _featureCard(Icons.notifications, "Notifications", Color(0xFF9C27B0), "Class reminder alerts", () {
                showSnackBar(context, "Notifications coming soon 🚧");
              }),
              _featureCard(
                Icons.calendar_month,
                "Weekly Timetable",
                Color(0xFF009688),
                "View weekly schedule",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeeklyTimetablePage(),
                    ),
                  );
                },
              ),

              _featureCard(Icons.fact_check, "Take Attendance", Color(0xFF795548), "Mark student attendance", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceListPage()));
              }),
              _featureCard(
                Icons.upload,
                "Upload Routine",
                Colors.blueGrey,
                "Add new class routine",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadRoutinePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Status Card
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFF027a9c), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Current Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(currentStatus, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => currentStatus = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "In Class", child: Text("In Class")),
              PopupMenuItem(value: "On Break", child: Text("On Break")),
              PopupMenuItem(value: "Busy", child: Text("Busy")),
              PopupMenuItem(value: "Available", child: Text("Available")),
            ],
          ),
        ],
      ),
    );
  }

  /// Feature Card
  Widget _featureCard(IconData icon, String title, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(220),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
