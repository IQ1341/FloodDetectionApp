import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../utils/constants.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? namaSungai;
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, dynamic>> history = [];

  LatLng? location;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (namaSungai == null) {
      namaSungai = ModalRoute.of(context)?.settings.arguments as String?;
      if (namaSungai != null) {
        fetchHistory();
        fetchLocation();
      }
    }
  }

  void fetchHistory() {
    final sungaiKey = namaSungai!.toLowerCase().replaceAll(" ", "_");
    FirebaseFirestore.instance
        .collection(sungaiKey)
        .doc('riwayat')
        .collection('data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> docs = snapshot.docs.map((doc) {
        final data = doc.data();
        final date = (data['timestamp'] as Timestamp).toDate();
        final value = (data['value'] as num).toDouble();
        final status = value >= 150
            ? "BAHAYA"
            : value >= 100
                ? "WASPADA"
                : "AMAN";
        final color = status == "BAHAYA"
            ? Colors.red
            : status == "WASPADA"
                ? Colors.orange
                : AppColors.primary;
        return {
          "waktu": date,
          "level": "${value.toStringAsFixed(1)} cm",
          "status": status,
          "color": color,
        };
      }).toList();

      setState(() {
        history = docs;
      });
    });
  }

  void fetchLocation() async {
    final sungaiKey = namaSungai!.toLowerCase().replaceAll(" ", "_");
    final snapshot = await FirebaseFirestore.instance
        .collection(sungaiKey)
        .doc('lokasi')
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      final lat = (data?['latitude'] as num?)?.toDouble();
      final lng = (data?['longitude'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        setState(() {
          location = LatLng(lat, lng);
        });
      }
    }
  }

  // Fungsi untuk mengekspor data yang sudah difilter ke CSV
  Future<void> exportCSV() async {
    final List<List<dynamic>> csvData = [
      ['Waktu', 'Ketinggian (cm)', 'Status'],
      // Menggunakan filteredHistory yang sudah difilter berdasarkan tanggal
      ...history.where((item) {
        final itemDate = item['waktu'] as DateTime;
        if (startDate != null && itemDate.isBefore(startDate!)) return false;
        if (endDate != null && itemDate.isAfter(endDate!)) return false;
        return true;
      }).map((item) => [
            DateFormat('yyyy-MM-dd HH:mm').format(item['waktu']),
            item['level'],
            item['status'],
          ])
    ];

    final String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getExternalStorageDirectory();
    final path = "${dir!.path}/${namaSungai}_riwayat.csv";

    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Berhasil diekspor ke: $path")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = history.where((item) {
      final itemDate = item['waktu'] as DateTime;
      if (startDate != null && itemDate.isBefore(startDate!)) return false;
      if (endDate != null && itemDate.isAfter(endDate!)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Lokasi & Riwayat", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // PETA LOKASI
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: location != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: location!,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("lokasi"),
                            position: location!,
                            infoWindow: InfoWindow(title: namaSungai),
                          )
                        },
                      )
                    : const Center(child: Text("Memuat peta lokasi...", style: TextStyle(fontSize: 16))),
              ),
            ),
          ),

          // FILTER TANGGAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildDatePicker("Dari", startDate, (date) => setState(() => startDate = date))),
                const SizedBox(width: 12),
                Expanded(child: _buildDatePicker("Sampai", endDate, (date) => setState(() => endDate = date))),
                IconButton(
                  icon: const Icon(Icons.download, color: AppColors.primary),
                  tooltip: "Export CSV",
                  onPressed: exportCSV,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Riwayat Ketinggian Air", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          // LIST RIWAYAT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: item['color'].withOpacity(0.15),
                        child: Icon(Icons.water_drop, color: item['color']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('yyyy-MM-dd HH:mm').format(item['waktu']),
                                style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(item['level'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(item['status'], style: TextStyle(color: item['color'], fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, Function(DateTime) onSelected) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2100),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? DateFormat('dd MMM yyyy').format(value) : label,
                style: TextStyle(fontSize: 13, color: value != null ? Colors.black87 : Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
