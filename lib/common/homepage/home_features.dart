import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/common/vehicles/vehicle_registry.dart';
import 'package:my_soc/common/penalties/view_pens.dart';

// ---------------------------------------------------------
// UI Component: HomeFeatures (Display features and services)
// ---------------------------------------------------------
class HomeFeatures extends StatelessWidget {
  final QueryDocumentSnapshot userDetails;
  final DocumentSnapshot buildingDetails;
  final String userName;

  const HomeFeatures({
    super.key,
    required this.userDetails,
    required this.buildingDetails,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // 6 services in specified order with generated descriptions
    final services = [
      _ServiceItem(
        title: "Pay Maintenance",
        description:
            "Pay your monthly society dues, view history, and download payment receipts.",
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF3F51B5), // Indigo
        iconBgColor: const Color(0x1F3F51B5),
        onTap: () {
          logger.i('Pay Maintenance tapped from Features');
          Navigator.pushNamed(context, '/maintain', arguments: {
            'userDetails': userDetails,
            'buildingDetails': buildingDetails,
          });
        },
      ),
      _ServiceItem(
        title: "View Penalties",
        description:
            "Check outstanding penalties, track rule violation logs, and resolve dues.",
        icon: Icons.gavel_rounded,
        iconColor: const Color(0xFFE91E63), // Pink/Red
        iconBgColor: const Color(0x1FE91E63),
        onTap: () {
          logger.i('View Penalties tapped from Features');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ViewPenaltiesPage(),
              settings: RouteSettings(
                arguments: {
                  'userId': userDetails.id,
                  'userName': userName,
                  'buildingId': buildingDetails.id,
                  'designation': userDetails['designation'],
                },
              ),
            ),
          );
        },
      ),
      _ServiceItem(
        title: "Your Packages",
        description:
            "Track incoming parcels, manage delivery status, and coordinate collections.",
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFFFF9800), // Amber
        iconBgColor: const Color(0x1FFF9800),
        onTap: () {
          logger.i('Your Packages tapped from Features');
          Navigator.pushNamed(context, '/viewPackages', arguments: {
            'userId': userDetails.id,
            'buildingId': buildingDetails.id,
            'wing': userDetails['wing'] ?? '',
            'flatNumber': userDetails['flatNumber'] ?? '',
          });
        },
      ),
      _ServiceItem(
        title: "Permissions",
        description:
            "Approve security gate passes, allow guest entries, and schedule visits.",
        icon: Icons.key_rounded,
        iconColor: const Color(0xFF4CAF50), // Green
        iconBgColor: const Color(0x1F4CAF50),
        onTap: () {
          logger.i('Permissions tapped from Features');
          Navigator.pushNamed(context, '/permissions', arguments: {
            'userDetails': userDetails,
            'buildingDetails': buildingDetails,
          });
        },
      ),
      _ServiceItem(
        title: "Vehicle Registry",
        description:
            "Manage your registered vehicles, assign parking spots, and update plate numbers.",
        icon: Icons.directions_car_rounded,
        iconColor: const Color(0xFF2196F3), // Blue
        iconBgColor: const Color(0x1F2196F3),
        onTap: () {
          logger.i('Vehicle Registry tapped from Features');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleRegistryPage(
                buildingId: buildingDetails.id,
              ),
            ),
          );
        },
      ),
      _ServiceItem(
        title: "About Your Society",
        description:
            "Learn about society management, contact office staff, and view bylaws.",
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF9C27B0), // Purple
        iconBgColor: const Color(0x1F9C27B0),
        onTap: () {
          logger.i('About Your Society tapped from Features');
          Navigator.pushNamed(context, '/kySociety', arguments: {
            'userId': userDetails.id,
            'userName': userName,
            'email': userDetails['email'] ?? '',
            'buildingId': buildingDetails.id,
            'designation': userDetails['designation'],
          });
        },
      ),
    ];

    final dividerColor = const Color(0x1F000000); // Shared divider line color

    // Build the grid list items separated by thin lines
    final List<Widget> listChildren = [];
    for (int i = 0; i < services.length; i++) {
      listChildren.add(_buildServiceTile(context, services[i]));
      if (i < services.length - 1) {
        listChildren.add(Container(height: 1.0, color: dividerColor));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        clipBehavior: Clip.antiAlias, // Clip items to wrapper rounded corners
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5), // Light gray base shade
          borderRadius: BorderRadius.circular(16), // Highly rounded corners
          border: Border.all(color: dividerColor, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000), // Clean light shadow
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: listChildren,
        ),
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, _ServiceItem service) {
    return SizedBox(
      height: 75,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: service.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Service Icon frame
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    service.icon,
                    color: service.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222A54),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.description,
                        maxLines: 1, // Single line layout fits flush cell
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Helper class: _ServiceItem
// ---------------------------------------------------------
class _ServiceItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}
