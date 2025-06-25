import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> checkLogin(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2)); // Delay splash 2 detik

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Sudah login, ambil data user dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      if (userDoc.exists && data != null && data.containsKey('allowed_sungai')) {
        final wilayah = data['wilayah'] ?? 'Wilayah Tidak Diketahui';
        final List<dynamic> sungaiList = data['allowed_sungai'];

        Navigator.pushReplacementNamed(
          context,
          '/pilih-sungai',
          arguments: {
            'wilayah': wilayah,
            'sungaiList': sungaiList,
          },
        );
      } else {
        // Tidak valid, logout dan kembali ke login
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Belum login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => checkLogin(context));

    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Flood Detection",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
