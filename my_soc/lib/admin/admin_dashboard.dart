import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Map<String, Map<String, bool>> buildingVerifications = {};
  final TextEditingController adminNameController = TextEditingController();
  final Map<String, bool> expandedTiles = {};

  bool areAllFieldsVerified(String buildingId) {
    final verifications = buildingVerifications[buildingId];
    if (verifications == null) return false;
    print('Checking verifications for building $buildingId: $verifications');

    // Check all required fields
    final requiredFields = [
      'buildingName',
      'streetName',
      'landmark',
      'state',
      'city',
      'buildingArea',
      'constructionYear',
      'numberOfWings',
      'wings',
      'totalFlats',
      'images',
    ];

    bool allVerified = requiredFields.every((field) {
      final isVerified = verifications[field] ?? false;
      print('Field $field verification status: $isVerified');
      return isVerified;
    });

    print('Final verification status: $allVerified');
    return allVerified;
  }

  Widget _buildVerificationRow(
      String label, dynamic value, String buildingId, String field) {
    String displayValue = value?.toString() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: buildingVerifications[buildingId]?[field] == true
            ? Colors.green.withOpacity(0.05)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          RepaintBoundary(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setInnerState) {
                return Switch(
                  value: buildingVerifications[buildingId]?[field] ?? false,
                  onChanged: (bool value) {
                    setInnerState(() {
                      if (buildingVerifications[buildingId] == null) {
                        buildingVerifications[buildingId] = {};
                      }
                      buildingVerifications[buildingId]![field] = value;
                    });

                    // Delay the parent setState to prevent scroll jump
                    Future.delayed(Duration(milliseconds: 50), () {
                      setState(() {});
                    });
                  },
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.shade100,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Initialize verifications for a building
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
        'images': false,
      };
    }
  }

  Future<void> _showAdminNameDialog(
      BuildContext context, String buildingId) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green),
              SizedBox(width: 8),
              Text('Enter Admin Name'),
            ],
          ),
          content: TextField(
            controller: adminNameController,
            decoration: InputDecoration(
              labelText: 'Admin Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (adminNameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('buildings')
                      .doc(buildingId)
                      .update({
                    'verifiedBy': adminNameController.text,
                    'verificationDate': DateTime.now(),
                    'isVerified': true,
                  });
                  Navigator.pop(context);
                  adminNameController.clear();

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
              },
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buildings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No buildings found'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final building = snapshot.data!.docs[index];
              final data = building.data() as Map<String, dynamic>;
              final String buildingId = building.id;

              expandedTiles.putIfAbsent(buildingId, () => false);

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
                  'images': false,
                  'occupancyCertificatePath': false,
                };
              }

              List<String> imagePaths = [];
              if (data['buildingImagePaths'] != null) {
                if (data['buildingImagePaths'] is List) {
                  imagePaths = List<String>.from(data['buildingImagePaths']);
                } else if (data['buildingImagePaths'] is String) {
                  imagePaths = [data['buildingImagePaths']];
                }
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  initiallyExpanded: expandedTiles[buildingId] ?? false,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      expandedTiles[buildingId] = expanded;
                    });
                  },
                  leading: const Icon(
                    Icons.business,
                    color: Color(0xFF1565C0),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['buildingName'] ?? 'Unnamed Building',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVerificationRow('Building Name',
                              data['buildingName'], buildingId, 'buildingName'),
                          _buildVerificationRow('Street Name',
                              data['streetName'], buildingId, 'streetName'),
                          _buildVerificationRow('Landmark', data['landmark'],
                              buildingId, 'landmark'),
                          _buildVerificationRow(
                              'State', data['state'], buildingId, 'state'),
                          _buildVerificationRow(
                              'City', data['city'], buildingId, 'city'),
                          _buildVerificationRow('Total Area',
                              data['buildingArea'], buildingId, 'buildingArea'),
                          _buildVerificationRow(
                              'Construction Year',
                              data['constructionYear'],
                              buildingId,
                              'constructionYear'),
                          _buildVerificationRow(
                              'Number of Wings',
                              data['numberOfWings'],
                              buildingId,
                              'numberOfWings'),
                          _buildVerificationRow(
                              'Wings', data['wings'], buildingId, 'wings'),
                          _buildVerificationRow('Total Flats',
                              data['totalFlats'], buildingId, 'totalFlats'),
                          if (imagePaths.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Building Images',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setState) {
                                      return Row(
                                        children: [
                                          Text(
                                            '${imagePaths.length} images',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: buildingVerifications[
                                                    buildingId]?['images'] ??
                                                false,
                                            onChanged: (bool value) {
                                              setState(() {
                                                buildingVerifications[
                                                        buildingId]?['images'] =
                                                    value;
                                              });
                                            },
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 200,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imagePaths.length,
                                itemBuilder: (context, imageIndex) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              backgroundColor: Colors.black,
                                              leading: IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                            body: Container(
                                              color: Colors.black,
                                              child: Center(
                                                child: InteractiveViewer(
                                                  child: Image.network(
                                                    imagePaths[imageIndex],
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              imagePaths[imageIndex],
                                              height: 200,
                                              width: 300,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 200,
                                                  width: 300,
                                                  color: Colors.grey[300],
                                                  child: const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 48,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${imageIndex + 1}/${imagePaths.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: areAllFieldsVerified(buildingId)
                                  ? () =>
                                      _showAdminNameDialog(context, buildingId)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    areAllFieldsVerified(buildingId)
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation:
                                    areAllFieldsVerified(buildingId) ? 2 : 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    areAllFieldsVerified(buildingId)
                                        ? Icons.verified
                                        : Icons.pending,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    areAllFieldsVerified(buildingId)
                                        ? 'Verify Building'
                                        : 'Please Verify All Fields',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (data['verifiedBy'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Verified by: ${data['verifiedBy']} on ${(data['verificationDate'] as Timestamp).toDate().toString().split('.')[0]}',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    adminNameController.dispose();
    super.dispose();
  }
}
