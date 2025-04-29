import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String selectedFilter = "Semua";
  final List<String> filters = ["Semua", "AMAN", "WASPADA", "BAHAYA"];

  final List<Map<String, dynamic>> history = [
    {"waktu": "29 Apr 2025, 22:45", "level": "200 cm", "status": "BAHAYA", "color": Colors.red},
    {"waktu": "29 Apr 2025, 21:45", "level": "180 cm", "status": "WASPADA", "color": Colors.orange},
    {"waktu": "29 Apr 2025, 20:45", "level": "120 cm", "status": "AMAN", "color": AppColors.primary},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHistory = selectedFilter == "Semua"
        ? history
        : history.where((item) => item['status'] == selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // CONTAINER MAP DUMMY
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 16),
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Center(
                child: Text(
                  "Peta Lokasi Alat",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          ),

          // FILTER
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final isSelected = selectedFilter == filters[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = filters[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Ketinggian Air",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // RIWAYAT DUMMY
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
                  Text(item['waktu'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
              child: Text(
                item['status'],
                style: TextStyle(color: item['color'], fontWeight: FontWeight.bold),
              ),
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
}