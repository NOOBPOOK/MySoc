import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/routes.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/admin_provider.dart';

// ---------------------------------------------------------
// UI Component: AdminDashboardView
// ---------------------------------------------------------
class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  // Backend: Handle logout functionality
  void _handleLogout(BuildContext context) {
    logger.i('_handleLogout starting');
    Navigator.pushReplacementNamed(context, MySocRoutes.loginRoute);
    logger.i('_handleLogout completed successfully');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the loaded data synchronously since AdminHome guarantees it's loaded
    final adminUsersData = ref.watch(allUsersProvider).value;
    final String totalUsers = adminUsersData?.users.length.toString() ?? "0";
    final String totalBuildings =
        adminUsersData?.buildingUserCounts.length.toString() ?? "0";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCounterCard(
                  context: context,
                  title: "Total Buildings",
                  count: totalBuildings,
                  color: const Color(0xFF222A54),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCounterCard(
                  context: context,
                  title: "Total Users",
                  count: totalUsers,
                  color: const Color(0xFF222A54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              logger.i('Map widget clicked, navigating to admin maps');
              Navigator.pushNamed(context, MySocRoutes.adminMaps);
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'lib/images/adminButton.png',
                      fit: BoxFit.cover,
                    ),
                    // Positioned Text
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        child: const Text(
                          "See here on map ....",
                          style: TextStyle(
                            fontFamily: "cursive",
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTopLocations(context),
          const Spacer(),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildCounterCard({
    required BuildContext context,
    required String title,
    required String count,
    required Color color,
    double titleFontSize = 12,
    double countFontSize = 48,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // Backend: Fetch top locations data (dummy for now)
  List<Map<String, dynamic>> _getTopLocations() {
    return [
      {"name": "Sector 43, Gurugram", "count": 150},
      {"name": "HSR Layout, Bengaluru", "count": 120},
      {"name": "Powai, Mumbai", "count": 95},
    ];
  }

  // UI: Build the Top Locations widget
  Widget _buildTopLocations(BuildContext context) {
    final topLocations = _getTopLocations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top Locations",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: "Poppins",
            color: Color(0xFF222A54),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: topLocations.asMap().entries.map((entry) {
              final index = entry.key;
              final loc = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == topLocations.length - 1 ? 0 : 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222A54).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "#${index + 1}",
                        style: const TextStyle(
                          color: Color(0xFF222A54),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc["name"] as String,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222A54),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${loc["count"]} Users",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // UI: Build the logout button
  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleLogout(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        "Sign Out",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: "Poppins",
        ),
      ),
    );
  }
}
