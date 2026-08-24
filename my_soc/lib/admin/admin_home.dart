import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';
import 'package:my_soc/providers/admin_provider.dart';
import 'admin_buildings_view.dart';
import 'admin_users_view.dart';
import 'admin_payments_view.dart';
import 'admin_dashboard.dart';

class AdminHome extends ConsumerStatefulWidget {
  const AdminHome({super.key});

  @override
  ConsumerState<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<AdminHome> {
  int _currentIndex = 0;

  // UI: Build the main content based on selected tab
  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboardView();
      case 1:
        return const AdminBuildingsView();
      case 2:
        return const AdminUsersView();
      case 3:
        return const AdminPaymentsView();
      default:
        return const AdminDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return allUsersAsync.when(
      data: (_) {
        return Scaffold(
          appBar: const AdminHeader(title: "Admin Dashboard"),
          backgroundColor: Colors.white,
          bottomNavigationBar: AdminFooter(
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
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF222A54),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Error loading dashboard:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------
// UI Component: AdminHeader
// ---------------------------------------------------------
class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AdminHeader({super.key, required this.title});

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
        title,
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
// UI Component: AdminFooter
// ---------------------------------------------------------
class AdminFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AdminFooter({
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
            _buildNavItem(index: 0, icon: Icons.home_rounded, label: "Home"),
            _buildNavItem(
                index: 1, icon: Icons.domain_rounded, label: "Buildings"),
            _buildNavItem(index: 2, icon: Icons.people_rounded, label: "Users"),
            _buildNavItem(
                index: 3, icon: Icons.payment_rounded, label: "Payments"),
          ],
        ),
      ),
    );
  }
}
