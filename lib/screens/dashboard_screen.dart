import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double currentWaterLevel = 0;
  double maxWaterLevel = 200;
  bool isRaining = false;
  List<double> waterLevelHistory = [];
  final String namaSungai = "Sungai Bedadung";

  final DateTime lastUpdateTime = DateTime.now();

  String getStatus(double level) {
    if (level < 100) return "AMAN";
    if (level < 150) return "WASPADA";
    return "BAHAYA";
  }

  Color getStatusColor(double level) {
    if (level < 100) return const Color(0xFF00C2FF);
    if (level < 150) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

void fetchData() {
  final ref = FirebaseDatabase.instance.ref("sungai_bedadung");
  ref.onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>;

    setState(() {
      currentWaterLevel = (data['ketinggian'] as num).toDouble();
      maxWaterLevel = (data['maksimal'] as num).toDouble();

      // Tambahkan ini
      isRaining = data['cuaca'] == "hujan";

      if (data['riwayat'] is List) {
        waterLevelHistory = List.from(data['riwayat']).map((e) => (e as num).toDouble()).toList();
      } else if (data['riwayat'] is Map) {
        final map = Map<String, dynamic>.from(data['riwayat']);
        waterLevelHistory = map.values.map((e) => (e as num).toDouble()).toList();
      }
    });
  });
}


  @override
  Widget build(BuildContext context) {
    final status = getStatus(currentWaterLevel);
    final statusColor = getStatusColor(currentWaterLevel);
    final timeFormatted = DateFormat('HH:mm').format(lastUpdateTime);
    final dateFormatted = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(lastUpdateTime);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaSungai,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, size: 26, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            // Info Ketinggian Air
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.8), width: 1.5),
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
                        const Text("Tinggi Air Sekarang", style: TextStyle(fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          "${currentWaterLevel.toStringAsFixed(1)} cm",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text("Maksimal: ${maxWaterLevel.toInt()} cm", style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cuaca & Status
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    icon: isRaining ? Icons.cloud : Icons.wb_sunny,
                    title: "Cuaca",
                    value: isRaining ? "Hujan" : "Cerah",
                    color: isRaining ? Colors.blueGrey : Colors.orange,
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
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Diupdate: $timeFormatted",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
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
    final filters = ["Hari Ini", "7 Hari", "Bulan"];
    String selectedFilter = "Hari Ini";

    return StatefulBuilder(
      builder: (context, setState) {
        final data = waterLevelHistory;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: filters.map((filter) {
                final isSelected = filter == selectedFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Grafik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Grafik Ketinggian Air", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: data.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value);
                            }).toList(),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 4,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.primary,
                                  strokeWidth: 0,
                                );
                              },
                            ),
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
      },
    );
  }
}
