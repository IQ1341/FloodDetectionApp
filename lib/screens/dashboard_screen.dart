import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';
// import '../screens/notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String namaSungai;

  const DashboardScreen({super.key, required this.namaSungai});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double maxWaterLevelRealtime = 300;
  double currentWaterLevel = 0;
  double maxWaterLevel = 200;
  double thresholdValue = 150;
  double cuacaValue = 0;
  String cuacaText = "Cerah";
  Color cuacaColor = Colors.orange;
  bool isRaining = false;
  List<Map<String, dynamic>> waterLevelHistory = [];

  String selectedFilter = "Hari Ini";

  @override
  void initState() {
    super.initState();
    fetchRealtimeData();
    listenToThresholdFromRealtimeDB();
    listenMaxYFromRealtimeDB();
    listenToFirestoreHistory();
  }

  void fetchRealtimeData() {
    final ref = FirebaseDatabase.instance
        .ref(widget.namaSungai.toLowerCase().replaceAll(" ", "_"));
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        currentWaterLevel = (data['ketinggian'] as num).toDouble();
        cuacaValue = (data['hujan'] as num).toDouble();

        if (cuacaValue >= 70) {
          cuacaText = "Hujan";
          cuacaColor = Colors.blueGrey;
        } else if (cuacaValue >= 30) {
          cuacaText = "Grimis";
          cuacaColor = Colors.lightBlue;
        } else {
          cuacaText = "Cerah";
          cuacaColor = Colors.orange;
        }

        isRaining = cuacaValue >= 70;
      });
    });
  }

  void listenToThresholdFromRealtimeDB() {
    final ref = FirebaseDatabase.instance.ref(
        "${widget.namaSungai.toLowerCase().replaceAll(" ", "_")}/threshold/nilai");
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          thresholdValue = (data as num).toDouble();
        });
      }
    });
  }

  void listenMaxYFromRealtimeDB() {
    final ref = FirebaseDatabase.instance.ref(
        "${widget.namaSungai.toLowerCase().replaceAll(" ", "_")}/kalibrasi/tinggiSensor");
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          maxWaterLevelRealtime = (data as num).toDouble();
        });
      }
    });
  }

  void listenToFirestoreHistory() {
    FirebaseFirestore.instance
        .collection(widget.namaSungai.toLowerCase().replaceAll(" ", "_"))
        .doc("riwayat")
        .collection("data")
        .orderBy("timestamp", descending: false)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "value": (data["value"] as num).toDouble(),
          "timestamp": (data["timestamp"] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        waterLevelHistory = docs;
      });
    });
  }

  String getStatus(double level) {
    if (level < thresholdValue * 0.66) return "Aman";
    if (level < thresholdValue) return "Waspada";
    return "Bahaya";
  }

  Color getStatusColor(double level) {
    if (level < thresholdValue * 0.66) return const Color(0xFF00C2FF);
    if (level < thresholdValue) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> getFilteredData() {
    final now = DateTime.now();
    late DateTime from;
    late DateTime Function(DateTime) groupBy;

    if (selectedFilter == "Hari Ini") {
      from = DateTime(now.year, now.month, now.day);
      groupBy = (dt) => DateTime(dt.year, dt.month, dt.day, dt.hour);
    } else if (selectedFilter == "Minggu") {
      from = now.subtract(const Duration(days: 7));
      groupBy = (dt) => DateTime(dt.year, dt.month, dt.day);
    } else {
      from = now.subtract(const Duration(days: 30));
      groupBy = (dt) => DateTime(dt.year, dt.month, dt.day);
    }

    final filtered = waterLevelHistory.where((e) => e['timestamp'].isAfter(from));
    final Map<DateTime, List<double>> grouped = {};

    for (var item in filtered) {
      final timeGroup = groupBy(item['timestamp']);
      grouped.putIfAbsent(timeGroup, () => []).add(item['value']);
    }

    final averaged = grouped.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return {
        "timestamp": entry.key,
        "value": avg,
      };
    }).toList();

    averaged.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
    return averaged;
  }

  @override
  Widget build(BuildContext context) {
    final status = getStatus(currentWaterLevel);
    final statusColor = getStatusColor(currentWaterLevel);
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(dateFormatted),
            _buildCurrentWaterLevelCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    icon: isRaining ? Icons.cloud : Icons.wb_sunny,
                    title: "Cuaca",
                    value: cuacaText,
                    color: cuacaColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    icon: Icons.warning,
                    title: "Status",
                    value: status,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildGraphCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dateFormatted) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.namaSungai,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(dateFormatted, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(widget.namaSungai.toLowerCase().replaceAll(" ", "_"))
                .doc("notifikasi")
                .collection("data")
                .snapshots(),
            builder: (context, snapshot) {
              int notifCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return GestureDetector(
                onTap: () {
  Navigator.pushNamed(
    context,
    '/notifikasi',
    arguments: widget.namaSungai,
  );
},
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none, size: 32, color: AppColors.primary),
                      if (notifCount > 0)
                        Positioned(
                          right: -2,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              notifCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWaterLevelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water, color: Colors.white, size: 48),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tinggi Air Sekarang",
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                Text("${currentWaterLevel.toStringAsFixed(1)} cm",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard() {
    final filters = ["Hari Ini", "Minggu", "Bulan"];
    final filteredData = getFilteredData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: filters.map((filter) {
            final isSelected = filter == selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w500,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Grafik Ketinggian Air",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: LineChart(
                  key: ValueKey(thresholdValue),
                  LineChartData(
                    minY: 0,
                    maxY: maxWaterLevelRealtime,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 50,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          reservedSize: 28,
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: thresholdValue,
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'Batas Aman',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    lineBarsData: [
                      LineChartBarData(
                        spots: filteredData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value["value"]))
                            .toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
