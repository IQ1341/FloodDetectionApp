import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> checkLogin(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2)); // Delay Splash 2 detik

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Sudah login, ambil data sungai dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('nama_sungai')) {
        final namaSungai = userDoc['nama_sungai'];
        Navigator.pushReplacementNamed(context, '/dashboard',
            arguments: namaSungai);
      } else {
        // User tidak valid, logout dan kembali ke login
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
    // Jalankan pengecekan setelah build
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
