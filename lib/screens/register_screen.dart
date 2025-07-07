import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final wilayahController = TextEditingController();
  final sungaiController = TextEditingController();

  List<String> sungaiList = [];
  bool isLoading = false;

  void addSungai() {
    final name = sungaiController.text.trim();
    if (name.isNotEmpty && !sungaiList.contains(name)) {
      setState(() {
        sungaiList.add(name);
        sungaiController.clear();
      });
    }
  }

  void removeSungai(String sungai) {
    setState(() => sungaiList.remove(sungai));
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (sungaiList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal 1 sungai harus ditambahkan")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final wilayah = wilayahController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Simpan ke users
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'wilayah': wilayah,
        'allowed_sungai': sungaiList,
      });

      // Buat koleksi untuk setiap sungai (jika belum ada)
      for (String sungai in sungaiList) {
        final ref = FirebaseFirestore.instance.collection(sungai);
        final notifikasiRef = ref.doc('notifikasi');
        final snapshot = await notifikasiRef.get();
        if (!snapshot.exists) {
          await notifikasiRef.set({'created_at': FieldValue.serverTimestamp()});
        }

        final dataRef = notifikasiRef.collection('data');
        final existing = await dataRef.limit(1).get();
        if (existing.docs.isEmpty) {
          await dataRef.add({
            'title': 'Sistem Aktif',
            'message': 'Monitoring sungai telah dimulai.',
            'level': 'AMAN',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal registrasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Registrasi", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Buat Akun Baru",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C2FF),
                ),
              ),
              const SizedBox(height: 24),

              // Email
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration("Email"),
                validator: (value) =>
                    value!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration("Password"),
                validator: (value) =>
                    value!.length < 6 ? "Minimal 6 karakter" : null,
              ),
              const SizedBox(height: 16),

              // Wilayah
              TextFormField(
                controller: wilayahController,
                decoration: _inputDecoration("Wilayah"),
                validator: (value) =>
                    value!.isEmpty ? "Wilayah tidak boleh kosong" : null,
              ),
              const SizedBox(height: 24),

              const Text(
                "Tambah sungai",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sungaiController,
                      decoration: const InputDecoration(
                        hintText: "Contoh: sungai_bedadung",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: addSungai,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C2FF),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: sungaiList
                    .map((s) => Chip(
                          label: Text(s),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => removeSungai(s),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF00C2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Daftar",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
