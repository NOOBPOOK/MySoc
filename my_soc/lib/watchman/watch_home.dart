import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/watchman/watchman_dashboard_view.dart';
import 'package:my_soc/watchman/watchman_logs_view.dart';
import 'package:my_soc/watchman/watchman_profile_view.dart';

class WatchmanHome extends ConsumerStatefulWidget {
  const WatchmanHome({super.key});

  @override
  ConsumerState<WatchmanHome> createState() => _WatchmanHomeState();
}

class _WatchmanHomeState extends ConsumerState<WatchmanHome> {
  int _currentIndex = 0;

  // UI: Build the main content based on selected tab
  Widget _buildBodyContent() {
    if (_currentIndex == 0) {
      return const WatchmanDashboardView();
    } else if (_currentIndex == 1) {
      return const WatchmanLogsView();
    } else {
      return const WatchmanProfileView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchmanState = ref.watch(watchmanProvider);
    if (watchmanState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: WatchmanHeader(buildName: watchmanState.buildName),
      bottomNavigationBar: WatchmanFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanHeader
// ---------------------------------------------------------
class WatchmanHeader extends StatelessWidget implements PreferredSizeWidget {
  final String buildName;

  const WatchmanHeader({super.key, required this.buildName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 62.0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(
          color: Color(0xFF222A54), // Dark border
          width: 2.0,
        ),
      ),
      title: Text(
        buildName,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 25,
          color: Color(0xFF222A54),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(62.0);
}

// ---------------------------------------------------------
// UI Component: WatchmanFooter
// ---------------------------------------------------------
class WatchmanFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const WatchmanFooter({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  // UI: Build individual icon item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(
                index: 0, icon: Icons.dashboard_rounded, label: "Dashboard"),
            _buildNavItem(
                index: 1, icon: Icons.list_alt_rounded, label: "Logs"),
            _buildNavItem(
                index: 2, icon: Icons.person_rounded, label: "Profile"),
          ],
        ),
      ),
    );
  }
}
