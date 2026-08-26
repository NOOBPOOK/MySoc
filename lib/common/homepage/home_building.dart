import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: HomeBuilding (Building Administration Tab)
// ---------------------------------------------------------
class HomeBuilding extends StatelessWidget {
  final QueryDocumentSnapshot userDetails;
  final DocumentSnapshot buildingDetails;
  final String userName;

  const HomeBuilding({
    super.key,
    required this.userDetails,
    required this.buildingDetails,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Extract user designation code
    final rawDesig = userDetails['designation'];
    final desigCode = int.tryParse(rawDesig?.toString() ?? '0') ?? 0;

    // Designations metadata: name, icon, and gradient colors
    final designationName = _getDesignationName(desigCode);
    final designationGradient = _getDesignationGradient(desigCode);
    final designationIcon = _getDesignationIcon(desigCode);

    // Admin/Secretary services for building management sorted by administrative priority
    final adminServices = [
      // Priority 1: User Directory & Approvals
      _BuildingAdminItem(
        title: "Resident Verification",
        description: "Approve signup requests, view details, and manage active residents.",
        icon: Icons.supervised_user_circle_rounded,
        iconColor: const Color(0xFF1E90FF), // Dodger Blue
        iconBgColor: const Color(0x1F1E90FF),
        onTap: () {
          logger.i('Resident Verification tapped from Building Admin');
          Navigator.pushNamed(context, '/manageUsers', arguments: {
            'userId': userDetails.id,
            'userName': userName,
            'buildingId': buildingDetails.id,
            'designation': userDetails['designation'],
          });
        },
      ),
      // Priority 2: Delegation of access & authorization roles
      _BuildingAdminItem(
        title: "Assign Roles",
        description: "Update designations, assign security roles, and delegate rights.",
        icon: Icons.assignment_ind_rounded,
        iconColor: const Color(0xFF32CD32), // Lime Green
        iconBgColor: const Color(0x1F32CD32),
        onTap: () {
          logger.i('Assign Roles tapped from Building Admin');
          Navigator.pushNamed(context, '/secRoleBasedAccess', arguments: {
            'userDetails': userDetails,
            'buildingDetails': buildingDetails,
          });
        },
      ),
      // Priority 3: Review Permissions / Approvals (Actionable visitors / passes)
      _BuildingAdminItem(
        title: "Review Permissions",
        description: "Approve security gate passes, visitor requests, and amenity bookings.",
        icon: Icons.fact_check_rounded,
        iconColor: const Color(0xFF008080), // Teal
        iconBgColor: const Color(0x1F008080),
        onTap: () {
          logger.i('Review Permissions tapped from Building Admin');
          Navigator.pushNamed(context, '/viewPermissions', arguments: {
            'userDetails': userDetails,
            'buildingDetails': buildingDetails,
          });
        },
      ),
      // Priority 4: Direct Notices & Broadcast communications
      _BuildingAdminItem(
        title: "Create Announcements",
        description: "Broadcast important updates, alerts, and circulars to all flats.",
        icon: Icons.add_alert_rounded,
        iconColor: const Color(0xFFFF5722), // Deep Orange
        iconBgColor: const Color(0x1FFF5722),
        onTap: () {
          logger.i('Create Announcements tapped from Building Admin');
          Navigator.pushNamed(context, '/createAnnouncements', arguments: {
            'userId': userDetails.id,
            'userName': userName,
            'buildingId': buildingDetails.id,
            'designation': desigCode,
          });
        },
      ),
      // Priority 5: Collective surveys / voter polls
      _BuildingAdminItem(
        title: "Create Polls",
        description: "Launch building-wide community surveys and track voter feedback.",
        icon: Icons.poll_rounded,
        iconColor: const Color(0xFFFFB300), // Amber
        iconBgColor: const Color(0x1FFFB300),
        onTap: () {
          logger.i('Create Polls tapped from Building Admin');
          Navigator.pushNamed(context, '/userCreatePolls', arguments: {
            'userId': userDetails.id,
            'firstName': userDetails['firstName'] ?? '',
            'lastName': userDetails['lastName'] ?? '',
            'buildingId': buildingDetails.id,
            'designation': desigCode,
          });
        },
      ),
      // Priority 6: Penalty infractions log & warnings
      _BuildingAdminItem(
        title: "Issue Penalties",
        description: "Fine residents for rule violations, late payments, or building misuse.",
        icon: Icons.gavel_rounded,
        iconColor: const Color(0xFFD32F2F), // Red
        iconBgColor: const Color(0x1FD32F2F),
        onTap: () {
          logger.i('Issue Penalties tapped from Building Admin');
          Navigator.pushNamed(context, '/penalties', arguments: {
            'userDetails': userDetails,
            'buildingDetails': buildingDetails,
          });
        },
      ),
      // Priority 7: Society Accounts & Maintenance invoices
      _BuildingAdminItem(
        title: "Maintenance Dash",
        description: "Track monthly payments, generate reports, and update bill rates.",
        icon: Icons.dashboard_customize_rounded,
        iconColor: const Color(0xFF222A54), // Deep Navy
        iconBgColor: const Color(0x1F222A54),
        onTap: () {
          logger.i('Maintenance Dash tapped from Building Admin');
          Navigator.pushNamed(context, '/maintainDash', arguments: {
            'userId': userDetails.id,
            'userEmail': userDetails['email'] ?? '',
            'designation': userDetails['designation'],
            'buildingId': buildingDetails.id,
          });
        },
      ),
      // Priority 8: Security controls & physical guards setting
      _BuildingAdminItem(
        title: "Security Controls",
        description: "Configure watchman accounts, monitor gates, and view emergency contacts.",
        icon: Icons.security_rounded,
        iconColor: const Color(0xFF4682B4), // Steel Blue
        iconBgColor: const Color(0x1F4682B4),
        onTap: () {
          logger.i('Security Controls tapped from Building Admin');
          Navigator.pushNamed(context, '/securitySettings', arguments: {
            'userId': userDetails.id,
            'userEmail': userDetails['email'] ?? '',
            'buildingId': buildingDetails.id,
            'designation': userDetails['designation'],
          });
        },
      ),
    ];

    final dividerColor = const Color(0x1F000000);

    // Build the grid list items separated by thin lines
    final List<Widget> listChildren = [];
    for (int i = 0; i < adminServices.length; i++) {
      listChildren.add(_buildServiceTile(context, adminServices[i]));
      if (i < adminServices.length - 1) {
        listChildren.add(Container(height: 1.0, color: dividerColor));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dynamic Designation Card Widget (Liquid Glass Smart Badge with flush left icon)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Container(
            height: 103,
            clipBehavior: Clip.antiAlias, // Clip background circles and flush elements
            decoration: BoxDecoration(
              gradient: designationGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Back Decoration Circle 1 (Bottom Right)
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1FFFFFFF), // 12% white
                    ),
                  ),
                ),
                // 2. Back Decoration Circle 2 (Top Center)
                Positioned(
                  left: screenWidth * 0.35,
                  top: -20,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x0AFFFFFF), // 4% white
                    ),
                  ),
                ),
                // 3. Diagonal reflection highlight (Liquid glass shine)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x33FFFFFF), // 20% white gloss
                          Color(0x00FFFFFF), // transparent
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // 4. Frosted border highlight
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0x4DFFFFFF), // 30% white border
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // 5. Content Layout (Row with flush left item)
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left: Flush glowing frosted icon block
                      Container(
                        width: 76,
                        decoration: const BoxDecoration(
                          color: Color(0x2BFFFFFF), // Frosted fill
                        ),
                        child: Icon(
                          designationIcon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      // Shared vertical divider line
                      Container(
                        width: 1.0,
                        color: const Color(0x33FFFFFF), // Frosted glass separator line
                      ),
                      // Right: Text details & verified check
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Role pill tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0x26FFFFFF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "OFFICIAL ROLE",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Designation Title with drop shadow
                                    Text(
                                      designationName,
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x40000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // User Name
                                    Text(
                                      userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 12,
                                        color: Color(0xB3FFFFFF), // 70% opacity white
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Trailing verified circular seal badge
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0x26FFFFFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 20,
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
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
          child: Container(
            clipBehavior: Clip.antiAlias, // Clip items to rounded corners
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5), // Light gray base shade
              borderRadius: BorderRadius.circular(16), // Rounded corners
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
        ),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, _BuildingAdminItem service) {
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
                // Icon frame
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

  // ---------------------------------------------------------
  // Helper: Retrieve designation name mapping
  // ---------------------------------------------------------
  String _getDesignationName(int code) {
    switch (code) {
      case 4:
        return 'Secretary';
      case 3:
        return 'Chairman';
      case 2:
        return 'Treasurer';
      case 1:
        return 'Committee Member';
      case 0:
      default:
        return 'Resident';
    }
  }

  // ---------------------------------------------------------
  // Helper: Choose suitable background color/gradient
  // ---------------------------------------------------------
  LinearGradient _getDesignationGradient(int code) {
    switch (code) {
      case 4:
        // Secretary: Deep Royal Indigo to Purple
        return const LinearGradient(
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        // Chairman: Warm Orange to Red
        return const LinearGradient(
          colors: [Color(0xFFF5AF19), Color(0xFFF12711)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        // Treasurer: Emerald Green to Dark Green (representing money/accounts)
        return const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        // Committee Member: Bright Electric Blue to Teal
        return const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 0:
      default:
        // Resident: Slate Gray to Dark Slate
        return const LinearGradient(
          colors: [Color(0xFF708090), Color(0xFF4F5D6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // ---------------------------------------------------------
  // Helper: Retrieve matching designation icon
  // ---------------------------------------------------------
  IconData _getDesignationIcon(int code) {
    switch (code) {
      case 4:
        return Icons.admin_panel_settings_rounded; // Secretary
      case 3:
        return Icons.gavel_rounded; // Chairman
      case 2:
        return Icons.payments_rounded; // Treasurer
      case 1:
        return Icons.people_alt_rounded; // Committee Member
      case 0:
      default:
        return Icons.person_rounded; // Resident
    }
  }
}

// ---------------------------------------------------------
// Helper class: _BuildingAdminItem
// ---------------------------------------------------------
class _BuildingAdminItem {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _BuildingAdminItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}
