import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/common/homepage/home_appbar.dart';
import 'package:my_soc/common/homepage/home_slider.dart';
import 'package:my_soc/common/homepage/home_bottom_nav.dart';
import 'package:my_soc/common/vehicles/vehicle_registry.dart';
import 'package:my_soc/common/penalties/view_pens.dart';
import 'package:my_soc/common/homepage/home_action_cards.dart';
import 'package:my_soc/common/homepage/home_features.dart';
import 'package:my_soc/common/homepage/home_building.dart';

// ---------------------------------------------------------
// UI Component: HomeScreen
// ---------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late QueryDocumentSnapshot userDetails;
  late DocumentSnapshot buildingDetails;
  bool isLoading = true;
  int _tabIndex = 0; // State: Active bottom tab index

  // Capitalize helper
  String capitalize(String s) {
    if (s.isEmpty) return '';
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // Backend: Load logged in user details and building records
  Future<void> _initializeUserData() async {
    logger.i('_initializeUserData started');
    try {
      final userAuth = FirebaseAuth.instance.currentUser!;
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userAuth.email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        logger.w('No user record found for email: ${userAuth.email}');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/choose', (route) => false);
        }
        return;
      }

      userDetails = userSnapshot.docs[0];
      final userData = userDetails.data() as Map<String, dynamic>?;
      final bId = userData?['buildingId']?.toString() ?? '';

      buildingDetails = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(bId)
          .get();

      final isVerified = userData?['isVerified'] as bool? ?? false;
      if (!isVerified) {
        logger.w('User not verified: ${userAuth.email}');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
        return;
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      logger.i('_initializeUserData completed successfully');
    } catch (e) {
      logger.e('Error during _initializeUserData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading user: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // UI: Dashboard view (Tab 0)
  Widget _buildDashboard(String fullName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeActionCards(
          userDetails: userDetails,
          buildingDetails: buildingDetails,
          userName: fullName,
        ),
        const SizedBox(height: 24),
        _buildFeatureGrid(fullName),
      ],
    );
  }

  // UI: Render Society Feature Grid items
  Widget _buildFeatureGrid(String fullName) {
    return HomeFeatures(
      userDetails: userDetails,
      buildingDetails: buildingDetails,
      userName: fullName,
    );
  }

  // UI: Profile view (Tab 1)
  Widget _buildProfile() {
    final userData = userDetails.data() as Map<String, dynamic>?;
    final email = userData?['email']?.toString() ?? 'N/A';
    final wing = userData?['wing']?.toString() ?? 'N/A';
    final flat = userData?['flatNumber']?.toString() ?? 'N/A';
    final phone = userData?['phoneNumber']?.toString() ?? 'N/A';
    final verified = userData?['isVerified'] ?? false;
    final fName = userData?['firstName']?.toString() ?? '';
    final lName = userData?['lastName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Profile",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1F000000), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.person_outline_rounded, "Name",
                    "$fName $lName".trim()),
                const Divider(height: 24),
                _buildProfileRow(Icons.email_outlined, "Email", email),
                const Divider(height: 24),
                _buildProfileRow(Icons.phone_outlined, "Phone", phone),
                const Divider(height: 24),
                _buildProfileRow(Icons.domain_outlined, "Apartment",
                    "Wing $wing - Flat $flat"),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 14),
                    const Text(
                      "Status",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: verified
                            ? const Color(0xFFD1E7DD)
                            : const Color(0xFFF8D7DA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        verified ? "VERIFIED" : "PENDING",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: verified
                              ? const Color(0xFF0F5132)
                              : const Color(0xFF842029),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222A54),
          ),
        ),
      ],
    );
  }

  // UI: Settings view (Tab 2)
  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Settings",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1F000000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(Icons.notifications_active_outlined,
                    "Notification Settings", () {
                  logger.i('Notification settings tapped');
                }),
                const Divider(height: 1),
                _buildSettingsTile(Icons.lock_outline_rounded, "Privacy Policy",
                    () {
                  logger.i('Privacy Policy tapped');
                }),
                const Divider(height: 1),
                _buildSettingsTile(Icons.info_outline_rounded, "About MySoc",
                    () {
                  logger.i('About tapped');
                }),
                const Divider(height: 1),
                _buildSettingsTile(
                  Icons.logout_rounded,
                  "Sign Out",
                  () async {
                    logger.i('Sign Out initiated');
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    }
                  },
                  textColor: Colors.red[700],
                  iconColor: Colors.red[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap,
      {Color? textColor, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF222A54)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: "Poppins",
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF222A54),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.d('HomeScreen build triggered. Loading state: $isLoading');

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF222A54),
          ),
        ),
      );
    }

    final userData = userDetails.data() as Map<String, dynamic>?;

    // Capitalize and format user name
    final fName = capitalize(userData?['firstName']?.toString().trim() ?? '');
    final displayName = 'Hi  $fName'.trim();
    final lName = capitalize(userData?['lastName']?.toString().trim() ?? '');
    final fullName = '$fName $lName'.trim();

    // Format wing and flat number combo
    final wing = userData?['wing']?.toString().trim() ?? '';
    final flatNumber = userData?['flatNumber']?.toString().trim() ?? '';
    final wingFlatCombo = (wing.isNotEmpty && flatNumber.isNotEmpty)
        ? '$wing - $flatNumber'
        : (wing.isNotEmpty ? wing : flatNumber);

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = screenHeight * 0.15;

    final isSecretary = userData?['designation']?.toString() == '4';

    // Body content dispatcher based on selected tab index
    Widget bodyWidget;
    if (_tabIndex == 0) {
      bodyWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const HomeSlider(),
          const SizedBox(height: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x26FFFFFF), // 15% opacity white
                    Color(0x80FFFFFF), // 50% opacity white
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    0.01,
                    0.02,
                    0.03,
                    0.92,
                    1.0
                  ], // Steeper top fade within the 3% height
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 80.0), // Reduced padding to eliminate empty bottom space
                child: _buildDashboard(fullName),
              ),
            ),
          ),
        ],
      );
    } else {
      Widget tabContent;
      if (isSecretary && _tabIndex == 1) {
        tabContent = HomeBuilding(
          userDetails: userDetails,
          buildingDetails: buildingDetails,
          userName: fullName,
        );
      } else if ((isSecretary && _tabIndex == 2) || (!isSecretary && _tabIndex == 1)) {
        tabContent = _buildProfile();
      } else {
        tabContent = _buildSettings();
      }

      bodyWidget = ShaderMask(
        shaderCallback: (Rect rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0x26FFFFFF),
              Color(0x80FFFFFF),
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [
              0.0,
              0.01,
              0.02,
              0.03,
              0.92,
              1.0
            ],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
              bottom:
                  80.0), // Reduced padding to eliminate empty bottom space
          child: tabContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: HomeAppBar(
        fullName: displayName,
        wingFlat: "Welcome Back",
        wingFlatCombo: wingFlatCombo,
        height: appBarHeight,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: bodyWidget,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16.0,
            child: HomeBottomNav(
              currentIndex: _tabIndex,
              isSecretary: isSecretary,
              onTap: (index) {
                setState(() {
                  _tabIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
