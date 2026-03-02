import 'package:flutter/material.dart';
import 'package:teachmap/class_routine_upload%20_student.dart';
import 'package:teachmap/today_schedule_page.dart';
import 'package:teachmap/weekly_timetable_page.dart';
import 'attendance_list_page.dart';
import 'notification_model.dart';
import 'notification_page.dart';
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
  int notificationCount = 0;
  List<AppNotification> notifications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF027a9c),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            setState(() => _currentIndex = index);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationPage(
                  notifications: notifications,
                ),
              ),
            );
          } else if (index == 2) {
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
              showBadge: notificationCount > 0,
              badgeContent: Text(
                notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
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

      appBar: AppBar(
        title: const Text(
          "👨‍🏫 Teacher Dashboard",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF027a9c),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [

          /// Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'img/teacherhome.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// Main Content
          ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// Welcome Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
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
                      child: Icon(Icons.school,
                          size: 34,
                          color: Color(0xFF027a9c)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Welcome Teacher 👩‍🏫",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text("Manage your classes and status",
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildStatusCard(),

              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [

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

                  _featureCard(
                    Icons.schedule,
                    "Today's Schedule",
                    const Color(0xFFFF9800),
                    "View today’s classes",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const TodaySchedulePage(),
                        ),
                      );
                    },
                  ),

                  _featureCard(
                    Icons.fact_check,
                    "Take Attendance",
                    const Color(0xFFf45648),
                    "Mark student attendance",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const AttendanceListPage(),
                        ),
                      );
                    },
                  ),

                  _featureCard(
                    Icons.upload,
                    "Upload Routine",
                    Colors.blueGrey,
                    "Add new class routine",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ClassRoutineUploadPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info,
              color: Color(0xFF027a9c), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text("Current Status",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currentStatus,
                    style: const TextStyle(
                        color: Colors.black54)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) =>
                setState(() => currentStatus = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: "In Class",
                  child: Text("In Class")),
              PopupMenuItem(
                  value: "On Break",
                  child: Text("On Break")),
              PopupMenuItem(
                  value: "Busy",
                  child: Text("Busy")),
              PopupMenuItem(
                  value: "Available",
                  child: Text("Available")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title,
      Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:
        (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(220),
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: Colors.white, size: 32),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


