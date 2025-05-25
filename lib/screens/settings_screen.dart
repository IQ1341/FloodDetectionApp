import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import 'package:awesome_dialog/awesome_dialog.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double threshold = 150;
  double kalibrasi = 0;
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
      await fetchThreshold();
      await fetchKalibrasi();
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchKalibrasi() async {
    final db = FirebaseDatabase.instance.ref();
    final path = '${namaSungai!.toLowerCase().replaceAll(" ", "_")}/kalibrasi/tinggiSensor';

    final snapshot = await db.child(path).get();
    if (snapshot.exists) {
      kalibrasi = (snapshot.value as num).toDouble();
    } else {
      await db.child(path).set(kalibrasi);
    }
  }

  Future<void> fetchThreshold() async {
    final db = FirebaseDatabase.instance.ref();
    final path = '${namaSungai!.toLowerCase().replaceAll(" ", "_")}/threshold/nilai';

    final snapshot = await db.child(path).get();
    if (snapshot.exists) {
      threshold = (snapshot.value as num).toDouble();
    } else {
      await db.child(path).set(threshold);
    }
  }

Future<void> saveKalibrasi() async {
  if (namaSungai == null) return;

  final db = FirebaseDatabase.instance.ref();
  final path = '${namaSungai!.toLowerCase().replaceAll(" ", "_")}/kalibrasi/tinggiSensor';
  await db.child(path).set(kalibrasi);

  AwesomeDialog(
    context: context,
    dialogType: DialogType.success,
    animType: AnimType.bottomSlide,
    title: 'Kalibrasi Tersimpan',
    desc: 'Kalibrasi berhasil disimpan!',
    btnOkOnPress: () {},
    btnOkColor: Colors.teal,
  ).show();
}


Future<void> saveThreshold() async {
  if (namaSungai == null) return;

  final db = FirebaseDatabase.instance.ref();
  final path = '${namaSungai!.toLowerCase().replaceAll(" ", "_")}/threshold/nilai';
  await db.child(path).set(threshold);

  AwesomeDialog(
    context: context,
    dialogType: DialogType.success,
    animType: AnimType.rightSlide,
    title: 'Threshold Disimpan',
    desc: 'Ambang batas berhasil disimpan!',
    btnOkOnPress: () {},
    btnOkColor: AppColors.primary,
  ).show();
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
          _buildSectionTitle("Kalibrasi"),
          _buildKalibrasiCard(),
          const SizedBox(height: 32),
          _buildSectionTitle("Threshold"),
          _buildThresholdCard(),
          const SizedBox(height: 24),
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

  Widget _buildKalibrasiCard() {
    return _styledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kalibrasi ketinggian Air", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text("${kalibrasi.toInt()} cm", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: kalibrasi,
            min: 0,
            max: 1000,
            divisions: 1000,
            label: "${kalibrasi.toInt()} cm",
            onChanged: (value) => setState(() => kalibrasi = value),
            activeColor: Colors.teal,
            inactiveColor: Colors.teal.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: saveKalibrasi,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text("Simpan", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard() {
    return _styledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Threshold Ketinggian Air", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text("${threshold.toInt()} cm", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: threshold,
            min: 50,
            max: 1000,
            divisions: 1000,
            label: "${threshold.toInt()} cm",
            onChanged: (value) => setState(() => threshold = value),
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

  Widget _styledCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
