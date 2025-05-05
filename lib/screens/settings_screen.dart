import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double threshold = 150;
  bool isLoading = true;
  String? namaSungai;

  @override
  void initState() {
    super.initState();
    getUserSungai();
  }

  Future<void> getUserSungai() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (doc.exists && doc.data()!.containsKey("nama_sungai")) {
      namaSungai = doc["nama_sungai"];
      fetchThreshold();
    }
  }

  void fetchThreshold() async {
    final docRef = FirebaseFirestore.instance
        .collection(namaSungai!.toLowerCase().replaceAll(" ", "_"))
        .doc("threshold");

    final doc = await docRef.get();

    if (doc.exists && doc.data()!.containsKey("nilai")) {
      setState(() {
        threshold = (doc["nilai"] as num).toDouble();
      });
    } else {
      // Jika belum ada, simpan nilai default
      await docRef.set({"nilai": threshold});
    }

    if (mounted) setState(() => isLoading = false);
  }

  void saveThreshold() async {
    if (namaSungai == null) return;

    await FirebaseFirestore.instance
        .collection(namaSungai!.toLowerCase().replaceAll(" ", "_"))
        .doc("threshold")
        .set({"nilai": threshold});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ambang batas berhasil disimpan!")),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Pengaturan", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildSectionTitle("Ambang Batas"),
          _buildThresholdCard(),
          const SizedBox(height: 32),
          _buildSectionTitle("Tentang Aplikasi"),
          _buildAboutCard(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThresholdCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ambang Batas Ketinggian Air", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text("${threshold.toInt()} cm", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: threshold,
            min: 50,
            max: 300,
            divisions: 25,
            label: "${threshold.toInt()} cm",
            onChanged: (value) {
              setState(() {
                threshold = value;
              });
            },
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: saveThreshold,
              icon: const Icon(Icons.save, size: 18),
              label: const Text("Simpan", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Versi Aplikasi", style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text("1.0.0", style: TextStyle(color: Colors.black54)),
          SizedBox(height: 12),
          Text("Pengembang", style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text("Tim Sungai Bedadung", style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: logout,
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text("Keluar", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
