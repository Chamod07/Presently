import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key, required this.selectedIndex}) : super(key: key);

  final int selectedIndex;

  // Define constants for better maintainability
  static const Color primaryColor = Color(0xFF340052);
  static const Color accentColor = Color(0xFF7400B8);
  static const Color selectedIconColor = Color(0xFF7400B8);
  static const Color unselectedIconColor = Colors.white70;
  static const double iconSize = 24.0;
  static const double selectedIconSize = 26.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF340052), Color(0xFF4A0072)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          items: <BottomNavigationBarItem>[
            _buildNavigationItem(Icons.home_outlined, Icons.home, 'Home'),
            _buildNavigationItem(Icons.add_outlined, Icons.add, 'Session'),
            _buildNavigationItem(
                Icons.checklist_outlined, Icons.checklist, 'Tasks'),
            _buildNavigationItem(
                Icons.settings_outlined, Icons.settings, 'Settings'),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: unselectedIconColor,
          showSelectedLabels: true, // Show labels for better UX
          showUnselectedLabels: false,
          onTap: (index) => _onItemTapped(context, index),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationItem(
      IconData inactiveIcon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(
        inactiveIcon,
        size: iconSize,
        color: unselectedIconColor,
      ),
      activeIcon: _animatedCircularIcon(activeIcon),
      label: label,
      tooltip: label,
    );
  }

  Widget _animatedCircularIcon(IconData icon) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Icon(
              icon,
              color: selectedIconColor,
              size: selectedIconSize,
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Navigation routes mapping
    final routes = {
      0: '/home',
      1: '/scenario_sel',
      2: '/task_group_page',
      3: '/settings',
    };

    if (routes.containsKey(index)) {
      Navigator.pushReplacementNamed(context, routes[index]!,
          arguments: {'selectedIndex': index});
    }
  }
}
