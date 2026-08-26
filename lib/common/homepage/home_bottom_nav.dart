import 'package:flutter/material.dart';

// ---------------------------------------------------------
// UI Component: HomeBottomNav
// ---------------------------------------------------------
class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isSecretary;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isSecretary = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Set a dynamic width: wider if we have 4 tabs instead of 3
    final navWidth = isSecretary ? screenWidth * 0.82 : screenWidth * 0.70;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: navWidth,
          height: 55, // Reduced vertical height from 65 to 55
          decoration: BoxDecoration(
            color: const Color(0xFF151B3D), // Deep navy
            borderRadius: BorderRadius.circular(27.5), // Perfectly rounded capsule edges (Height 55 / 2)
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000), // Clean shadow for floating effect
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Let items stretch vertically edge-to-edge
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, "Dashboard"),
              if (isSecretary)
                _buildNavItem(1, Icons.business_rounded, "Building"),
              _buildNavItem(isSecretary ? 2 : 1, Icons.person_rounded, "Profile"),
              _buildNavItem(isSecretary ? 3 : 2, Icons.settings_rounded, "Settings"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), // Reduced vertical margin for height 55
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x26FFFFFF) : Colors.transparent, // 15% opacity white glass background
            borderRadius: BorderRadius.circular(24), // Rounded capsule selector
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 18, // Reduced icon size slightly to match height 55
              ),
              const SizedBox(height: 1), // Reduced vertical gap
              Text(
                label,
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 9.5, // Reduced font size slightly
                  color: isSelected ? Colors.white : Colors.white54,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
