import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // Extracting wings when navigating to the details page
          List<String> extractedWings = [];
          if (data['wings'] is List) {
            final List<dynamic> wingsList = data['wings'];
            extractedWings = wingsList
                .map((wing) => wing['wingName'].toString())
                .toList(); // Extract only wingName
          }

          // Pass the extracted wings data to the details page
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
                wings: extractedWings, // Pass extracted wings
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
                  const Icon(
                    Icons.business,
                    color: Color(0xFF1565C0),
                    size: 32,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['streetName'] ?? 'No address',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (data['isVerified'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
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
    );
  }

  Widget _buildToggleButtons() {
    return Column(
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
                        ? const Color(0xFF1565C0)
                        : Colors.grey[300],
                    foregroundColor:
                        showBuildings ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(8)),
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
                        ? const Color(0xFF1565C0)
                        : Colors.grey[300],
                    foregroundColor:
                        !showBuildings ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(8)),
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
            child: SwitchListTile(
              title: const Text('Show Unverified Only'),
              value: showUnverifiedOnly,
              onChanged: (value) {
                setState(() {
                  showUnverifiedOnly = value;
                });
              },
              activeColor: const Color(0xFF1565C0),
            ),
          ),
      ],
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0),
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
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: userData['isVerified'] == true
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: userData['isVerified'] == true
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    userData['isVerified'] == true
                        ? 'Verified'
                        : 'Not Verified',
                    style: TextStyle(
                      color: userData['isVerified'] == true
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBuildingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: buildingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buildings = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !showUnverifiedOnly || !(data['isVerified'] ?? false);
            }).toList() ??
            [];

        if (buildings.isEmpty) {
          return Center(
            child: Text(showUnverifiedOnly
                ? 'No unverified buildings found'
                : 'No buildings found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            return _buildBuildingCard(buildings[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, MySocRoutes.adminLogin);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToggleButtons(),
          Expanded(
            child: showBuildings ? _buildBuildingsList() : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
