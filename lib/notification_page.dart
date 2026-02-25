import 'package:flutter/material.dart';
import 'notification_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  final List<AppNotification> notifications;

  const NotificationPage({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        backgroundColor: Color(0xFF027a9c),
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 Back arrow color
        ),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text("No Notifications"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(item.title),
              subtitle: Text(item.body),
              trailing: Text(
                DateFormat('hh:mm a')
                    .format(item.time),
              ),
            ),
          );
        },
      ),
    );
  }
}