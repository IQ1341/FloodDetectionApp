import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> notifications = const [
    {
      "title": "Peringatan Banjir",
      "message": "Ketinggian air melebihi ambang batas!",
      "time": "29 Apr 2025, 22:45",
      "level": "BAHAYA",
      "color": Colors.red
    },
    {
      "title": "Status WASPADA",
      "message": "Ketinggian air mendekati batas waspada.",
      "time": "29 Apr 2025, 20:15",
      "level": "WASPADA",
      "color": Colors.orange
    },
    {
      "title": "Status Normal",
      "message": "Ketinggian air dalam batas aman.",
      "time": "29 Apr 2025, 18:30",
      "level": "AMAN",
      "color": Color(0xFF00C2FF)
    },
    {
      "title": "Status Normal",
      "message": "Ketinggian air dalam batas aman.",
      "time": "29 Apr 2025, 18:30",
      "level": "AMAN",
      "color": Color(0xFF00C2FF)
    },
    {
      "title": "Status Normal",
      "message": "Ketinggian air dalam batas aman.",
      "time": "29 Apr 2025, 18:30",
      "level": "AMAN",
      "color": Color(0xFF00C2FF)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Notifikasi", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: notif['color'].withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notif['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications, color: notif['color'], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: notif['color'],
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            notif['time'],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['message'],
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
