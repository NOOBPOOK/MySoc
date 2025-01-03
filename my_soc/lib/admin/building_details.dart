// building_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> buildingData;
  final String buildingId;
  final bool isVerified;
  final Map<String, bool> verifications;
  final Function(String, bool) onVerificationChanged;
  final Function(String, String, Map<String, dynamic>) onVerifyBuilding;

  const BuildingDetailsPage({
    required this.buildingData,
    required this.buildingId,
    required this.isVerified,
    required this.verifications,
    required this.onVerificationChanged,
    required this.onVerifyBuilding,
    Key? key,
  }) : super(key: key);

  @override
  State<BuildingDetailsPage> createState() => _BuildingDetailsPageState();
}

class _BuildingDetailsPageState extends State<BuildingDetailsPage> {
  Map<String, dynamic>? userData;
  final TextEditingController adminNameController = TextEditingController();
  bool get allFieldsVerified =>
      widget.verifications.values.every((value) => value);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.buildingData['userId'])
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _showVerificationDialog() async {
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
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (adminNameController.text.isNotEmpty) {
                  // Call the verification callback from parent
                  await widget.onVerifyBuilding(
                    widget.buildingId,
                    adminNameController.text,
                    widget.buildingData,
                  );
                  Navigator.pop(context);
                  Navigator.pop(context, true); // Return true to refresh parent
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Verify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationStatus() {
    if (widget.isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'This building is verified',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVerificationButton() {
    if (widget.isVerified) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: allFieldsVerified ? _showVerificationDialog : null,
        icon: const Icon(Icons.verified_user),
        label: const Text('Verify Building'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationRow(String label, dynamic value, String field) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: widget.verifications[field] == true
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
                Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.verifications[field] ?? false,
            onChanged: widget.isVerified
                ? null
                : (value) {
                    widget.onVerificationChanged(field, value);
                    setState(() {});
                  },
            activeColor: Colors.green,
            activeTrackColor: Colors.green.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                userData?['email'] ?? 'No email available',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                userData?['isVerified'] == true
                    ? Icons.verified
                    : Icons.pending,
                color: userData?['isVerified'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                userData?['isVerified'] == true
                    ? 'Verified User'
                    : 'Not Verified',
                style: TextStyle(
                  fontSize: 16,
                  color: userData?['isVerified'] == true
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    List<String> imagePaths = [];
    if (widget.buildingData['buildingImagePaths'] != null) {
      if (widget.buildingData['buildingImagePaths'] is List) {
        imagePaths =
            List<String>.from(widget.buildingData['buildingImagePaths']);
      } else if (widget.buildingData['buildingImagePaths'] is String) {
        imagePaths = [widget.buildingData['buildingImagePaths']];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Building Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text(
                '${imagePaths.length} images',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (imagePaths.isNotEmpty)
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imagePaths[index],
                      height: 200,
                      width: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingData['buildingName'] ?? 'Building Details'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserSection(),
            _buildVerificationStatus(),
            _buildVerificationRow('Building Name',
                widget.buildingData['buildingName'], 'buildingName'),
            _buildVerificationRow(
                'Street Name', widget.buildingData['streetName'], 'streetName'),
            _buildVerificationRow(
                'Landmark', widget.buildingData['landmark'], 'landmark'),
            _buildVerificationRow(
                'State', widget.buildingData['state'], 'state'),
            _buildVerificationRow('City', widget.buildingData['city'], 'city'),
            _buildVerificationRow('Building Area',
                widget.buildingData['buildingArea'], 'buildingArea'),
            _buildVerificationRow('Construction Year',
                widget.buildingData['constructionYear'], 'constructionYear'),
            _buildVerificationRow('Number of Wings',
                widget.buildingData['numberOfWings'], 'numberOfWings'),
            _buildVerificationRow(
                'Wings', widget.buildingData['wings'], 'wings'),
            _buildVerificationRow(
                'Total Flats', widget.buildingData['totalFlats'], 'totalFlats'),
            _buildImageGallery(),
            _buildVerificationButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    adminNameController.dispose();
    super.dispose();
  }
}
