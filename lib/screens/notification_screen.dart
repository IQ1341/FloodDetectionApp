import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil namaSungai dari arguments saat navigasi
    final namaSungai = ModalRoute.of(context)?.settings.arguments as String?;

    if (namaSungai == null) {
      return const Scaffold(
        body: Center(child: Text("Nama sungai tidak ditemukan.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Notifikasi ", style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(namaSungai)
            .doc("notifikasi")
            .collection("data")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tidak ada notifikasi."));
          }

          final notifications = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            return {
              'id': doc.id,
              'title': data['title'] ?? 'Tanpa Judul',
              'message': data['message'] ?? 'Pesan tidak tersedia.',
              'time': formatTimestamp(data['timestamp'] ?? Timestamp.now()),
              'level': data['level'] ?? 'AMAN',
              'color': getNotificationColor(data['level'] ?? 'AMAN'),
            };
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: Key(notif['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(namaSungai, notif['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${notif['title']} dihapus")),
                  );
                },
                background: Container(
                  color: Colors.red,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: notif['color'].withOpacity(0.25)),
                  ),
                  child: Row(
  crossAxisAlignment: CrossAxisAlignment.center,
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
    ),
  ],
),

                ),
              );
            },
          );
        },
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final monthNames = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];

    return "${date.day} ${monthNames[date.month - 1]}, ${date.year}, ${date.hour}:${date.minute}";
  }

  Color getNotificationColor(String level) {
    switch (level) {
      case "BAHAYA":
        return Colors.red;
      case "WASPADA":
        return Colors.orange;
      default:
        return const Color(0xFF00C2FF);
    }
  }

  Future<void> _deleteNotification(String namaSungai, String notifId) async {
    try {
      await FirebaseFirestore.instance
          .collection(namaSungai)
          .doc("notifikasi")
          .collection("data")
          .doc(notifId)
          .delete();
    } catch (e) {
      print("Gagal menghapus notifikasi: $e");
    }
  }
}
