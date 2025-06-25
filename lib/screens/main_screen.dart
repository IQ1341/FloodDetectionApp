import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'location_screen.dart';
import 'settings_screen.dart';
import '../widgets/bottom_navbar.dart';

class MainScreen extends StatefulWidget {
  final String namaSungai;

  const MainScreen({super.key, required this.namaSungai});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Dashboard (Monitoring) di tengah

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LocationScreen(namaSungai: widget.namaSungai),
      DashboardScreen(namaSungai: widget.namaSungai),
      SettingsScreen(namaSungai: widget.namaSungai),
    ];
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}
