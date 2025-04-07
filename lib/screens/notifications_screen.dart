import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Blood Donation Camp',
      'message': 'A blood donation camp will be held in your area next week.',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'title': 'Blood Request',
      'message': 'Urgent need for B+ blood type in City Hospital.',
      'time': '1 day ago',
      'isRead': true,
    },
    {
      'title': 'Donation Reminder',
      'message': 'You are eligible to donate blood again.',
      'time': '3 days ago',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[900]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: Colors.red[900],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['isRead']
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['message'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: notification['isRead']
                        ? null
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red[900],
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      setState(() {
                        notification['isRead'] = true;
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
} 