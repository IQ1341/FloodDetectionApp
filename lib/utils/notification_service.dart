import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Fungsi inisialisasi FCM & kirim token ke backend
  static Future<void> initializeFCM() async {
    // Minta izin notifikasi
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 Izin notifikasi diberikan');

      // Ambil token FCM
      String? token = await _messaging.getToken();
      print('📲 FCM Token: $token');

      if (token != null) {
        await _kirimTokenKeBackend(token);
      }

      // Listener saat app di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        if (notification != null) {
          print('📩 Foreground Notif: ${notification.title} - ${notification.body}');
          // Tambahkan logika tampilan di sini jika perlu
        }
      });
    } else {
      print('🚫 Izin notifikasi ditolak');
    }
  }

  /// Kirim token ke backend
  static Future<void> _kirimTokenKeBackend(String token) async {
    try {
      final url = Uri.parse("http://192.168.1.10:3000/api/save-token"); // Ganti sesuai server

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );

      if (response.statusCode == 200) {
        print("✅ Token berhasil dikirim ke backend");
      } else {
        print("❌ Gagal kirim token ke backend: ${response.body}");
      }
    } catch (e) {
      print("❌ Error saat kirim token ke backend: $e");
    }
  }

  /// Handler untuk background message (perlu dipanggil dari main.dart)
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('📥 Notif background: ${message.notification?.title} - ${message.notification?.body}');
  }
}
