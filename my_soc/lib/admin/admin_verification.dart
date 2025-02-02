import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:my_soc/admin/building_details.dart';
import 'package:my_soc/routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, Map<String, bool>> buildingVerifications = {};
  bool showBuildings = true;
  bool showUnverifiedOnly = false;

  late Stream<QuerySnapshot> buildingsStream;
  late Stream<QuerySnapshot> usersStream;

  @override
  void initState() {
    super.initState();
    buildingsStream = _firestore.collection('buildings').snapshots();
    usersStream = _firestore.collection('users').snapshots();
  }

  void initializeBuildingVerificationsDuplicate(String buildingId) {
    if (!buildingVerifications.containsKey(buildingId)) {
      buildingVerifications[buildingId] = {
        'buildingName': false,
        'streetName': false,
        'landmark': false,
        'state': false,
        'city': false,
        'buildingArea': false,
        'constructionYear': false,
        'numberOfWings': false,
        'wings': false,
        'totalFlats': false,
      };
    }
  }

  Future<String> fetchAdminUsername(String adminEmail) async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .where('email', isEqualTo: adminEmail)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        return adminDoc.docs.first.data()['username'] ?? 'Admin';
      }
      return 'Admin';
    } catch (e) {
      print('Error fetching admin username: $e');
      return 'Admin';
    }
  }

  Future<void> sendVerificationEmailDuplicate(String buildingName,
      Map<String, dynamic> buildingData, String buildingId) async {
    String? ownerEmail = buildingData['email'];
    String adminEmail = _auth.currentUser?.email ?? 'Admin';
    String adminUsername = await fetchAdminUsername(adminEmail);

    if (ownerEmail == null || ownerEmail.isEmpty) {
      print('Error: Building owner email not found');
      return;
    }

    String username = 'rtk2825@gmail.com';
    String password = 'pbkx eupc qwnq qrka';

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username)
      ..recipients.add(ownerEmail)
      ..subject = 'Building Verification Notification'
      ..text = '''
Dear Building Owner,

We are pleased to inform you that your building "$buildingName" (Building ID: $buildingId) has been verified by our admin: $adminUsername
Verification Date: ${DateTime.now()}

Thank you for your cooperation.

Best regards,
Admin Team
''';

    try {
      await send(message, smtpServer);
      print('Verification email sent successfully');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<void> sendRejectionEmailDuplicate(String buildingName, String rejectionRemark,
      Map<String, dynamic> buildingData, String buildingId) async {
    String? ownerEmail = buildingData['email'];
    String adminEmail = _auth.currentUser?.email ?? 'Admin';
    String adminUsername = await getAdminUsername(adminEmail);

    if (ownerEmail == null || ownerEmail.isEmpty) {
      print('Error: Building owner email not found');
      return;
    }

    String username = 'rtk2825@gmail.com';
    String password = 'pbkx eupc qwnq qrka';

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username)
      ..recipients.add(ownerEmail)
      ..subject = 'Building Application Rejection Notice'
      ..text = '''
Dear Building Owner,

We regret to inform you that your building application for "$buildingName" (Building ID: $buildingId) has been rejected.

Rejection Details:
- Reviewed by: $adminUsername
- Date: ${DateTime.now()}
- Reason for Rejection: $rejectionRemark

If you would like to appeal this decision or submit a new application with the necessary corrections, please contact our support team.

Best regards,
Admin Team
''';

    try {
      await send(message, smtpServer);
      print('Rejection email sent successfully');
    } catch (e) {
      print('Error sending rejection email: $e');
    }
  }

  Future<void> verifyBuilding(
      String buildingId, Map<String, dynamic> buildingData) async {
    try {
      String adminEmail = _auth.currentUser?.email ?? 'Admin';
      String adminUsername = await getAdminUsername(adminEmail);

      await _firestore.collection('buildings').doc(buildingId).update({
        'verifiedBy': adminUsername,
        'verificationDate': DateTime.now(),
        'isVerified': true,
      });

      await sendVerificationEmail(
        buildingData['buildingName'] ?? 'Unnamed Building',
        buildingData,
        buildingId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Building successfully verified'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error verifying building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying building: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  String extractWingName(dynamic wingsField) {
    if (wingsField is String) {
      // If it's a single string like "A"
      return wingsField;
    } else if (wingsField is List) {
      // If it's a list, extract the first wing
      return wingsField.isNotEmpty ? wingsField.first.toString() : 'Unknown';
    } else if (wingsField is Map<String, dynamic>) {
      // If it's a map, extract a value (assuming it contains a key-value pair with the wing name)
      return wingsField.values.isNotEmpty
          ? wingsField.values.first.toString()
          : 'Unknown';
    }
    // Fallback if the field is none of the above
    return 'Unknown';
  }

  Widget _buildBuildingCard(DocumentSnapshot document) {
    final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    final String buildingId = document.id;

    initializeBuildingVerifications(buildingId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            List<String> extractedWings = [];
            if (data['wings'] is List) {
              final List<dynamic> wingsList = data['wings'];
              extractedWings = wingsList
                  .map((wing) => wing['wingName'].toString())
                  .toList();
            }

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingDetailsPage(
                  buildingData: data,
                  buildingId: buildingId,
                  isVerified: data['isVerified'] ?? false,
                  isRejected: data['isRejected'] ?? false,
                  verifications: buildingVerifications[buildingId] ?? {},
                  onVerificationChanged: (String field, bool value) {
                    setState(() {
                      buildingVerifications[buildingId]?[field] = value;
                    });
                  },
                  onVerifyBuilding: verifyBuilding,
                  onRejectBuilding: rejectBuilding,
                  wings: extractedWings,
                ),
              ),
            );

            if (result == true) {
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE94560).withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xFFE94560),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['buildingName'] ?? 'Unnamed Building',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['streetName'] ?? 'No address',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data['isVerified'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE94560).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Color(0xFFE94560),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Color(0xFFE94560),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => showBuildings = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showBuildings
                              ? const Color(0xFFE94560)
                              : Colors.white.withOpacity(0.1),
                          foregroundColor:
                              showBuildings ? Colors.white : Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(12)),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business),
                            SizedBox(width: 8),
                            Text('Buildings'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => showBuildings = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !showBuildings
                              ? const Color(0xFFE94560)
                              : Colors.white.withOpacity(0.1),
                          foregroundColor:
                              !showBuildings ? Colors.white : Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(12)),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people),
                            SizedBox(width: 8),
                            Text('Users'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showBuildings)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: SwitchListTile(
                    title: const Text(
                      'Show Unverified Only',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: showUnverifiedOnly,
                    onChanged: (value) {
                      setState(() {
                        showUnverifiedOnly = value;
                      });
                    },
                    activeColor: const Color(0xFFE94560),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE94560),
            ),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE94560),
                          child: Icon(
                            userData['isVerified'] == true
                                ? Icons.verified_user
                                : Icons.person_outline,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          userData['email'] ?? 'No email',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE94560).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            userData['isVerified'] == true
                                ? 'Verified'
                                : 'Not Verified',
                            style: const TextStyle(
                              color: Color(0xFFE94560),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBuildingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: buildingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE94560),
            ),
          );
        }

        final buildings = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !showUnverifiedOnly || !(data['isVerified'] ?? false);
            }).toList() ??
            [];

        if (buildings.isEmpty) {
          return Center(
            child: Text(
              showUnverifiedOnly
                  ? 'No unverified buildings found'
                  : 'No buildings found',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildBuildingCard(buildings[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFFE94560),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, MySocRoutes.adminLogin);
                    },
                  ),
                ],
              ),
              _buildToggleButtons(),
              Expanded(
                child: showBuildings ? _buildBuildingsList() : _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initializeBuildingVerifications(String buildingId) {
    if (!buildingVerifications.containsKey(buildingId)) {
      buildingVerifications[buildingId] = {
        'buildingName': false,
        'streetName': false,
        'landmark': false,
        'state': false,
        'city': false,
        'buildingArea': false,
        'constructionYear': false,
        'numberOfWings': false,
        'wings': false,
        'totalFlats': false,
      };
    }
  }

  Future<String> getAdminUsername(String adminEmail) async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .where('email', isEqualTo: adminEmail)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        return adminDoc.docs.first.data()['username'] ?? 'Admin';
      }
      return 'Admin';
    } catch (e) {
      print('Error fetching admin username: $e');
      return 'Admin';
    }
  }

  Future<void> sendVerificationEmail(String buildingName,
      Map<String, dynamic> buildingData, String buildingId) async {
    String? ownerEmail = buildingData['email'];
    String adminEmail = _auth.currentUser?.email ?? 'Admin';
    String adminUsername = await getAdminUsername(adminEmail);

    if (ownerEmail == null || ownerEmail.isEmpty) {
      print('Error: Building owner email not found');
      return;
    }

    String username = 'rtk2825@gmail.com';
    String password = 'pbkx eupc qwnq qrka';

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username)
      ..recipients.add(ownerEmail)
      ..subject = 'Building Verification Notification'
      ..text = '''
Dear Building Owner,

We are pleased to inform you that your building "$buildingName" (Building ID: $buildingId) has been verified by our admin: $adminUsername.
Verification Date: ${DateTime.now()}

Thank you for your cooperation.

Best regards,
Admin Team
''';

    try {
      await send(message, smtpServer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent successfully'),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> sendRejectionEmail(String buildingName, String rejectionRemark,
      Map<String, dynamic> buildingData, String buildingId) async {
    String? ownerEmail = buildingData['email'];
    String adminEmail = _auth.currentUser?.email ?? 'Admin';
    String adminUsername = await getAdminUsername(adminEmail);

    if (ownerEmail == null || ownerEmail.isEmpty) {
      print('Error: Building owner email not found');
      return;
    }

    String username = 'rtk2825@gmail.com';
    String password = 'pbkx eupc qwnq qrka';

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username)
      ..recipients.add(ownerEmail)
      ..subject = 'Building Application Rejection Notice'
      ..text = '''
Dear Building Owner,

We regret to inform you that your building application for "$buildingName" (Building ID: $buildingId) has been rejected.

Rejection Details:
- Reviewed by: $adminUsername
- Date: ${DateTime.now()}
- Reason for Rejection: $rejectionRemark

If you would like to appeal this decision or submit a new application with the necessary corrections, please contact our support team.

Best regards,
Admin Team
''';

    try {
      await send(message, smtpServer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rejection email sent successfully'),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sending rejection email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending rejection email: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> verifyBuildingDuplicate(
      String buildingId, Map<String, dynamic> buildingData) async {
    try {
      String adminEmail = _auth.currentUser?.email ?? 'Admin';
      String adminUsername = await getAdminUsername(adminEmail);

      await _firestore.collection('buildings').doc(buildingId).update({
        'verifiedBy': adminUsername,
        'verificationDate': DateTime.now(),
        'isVerified': true,
      });

      await sendVerificationEmail(
        buildingData['buildingName'] ?? 'Unnamed Building',
        buildingData,
        buildingId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Building successfully verified'),
              ],
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error verifying building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying building: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> rejectBuilding(
      String buildingId, Map<String, dynamic> buildingData) async {
    try {
      String adminEmail = _auth.currentUser?.email ?? 'Admin';
      String adminUsername = await getAdminUsername(adminEmail);

      await _firestore.collection('buildings').doc(buildingId).update({
        'rejectedBy': adminUsername,
        'rejectionDate': DateTime.now(),
        'isRejected': true,
        'rejectionRemark': buildingData['rejectionRemark'],
      });

      await sendRejectionEmail(
        buildingData['buildingName'] ?? 'Unnamed Building',
        buildingData['rejectionRemark'],
        buildingData,
        buildingId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Building application rejected'),
              ],
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting building: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting building: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}