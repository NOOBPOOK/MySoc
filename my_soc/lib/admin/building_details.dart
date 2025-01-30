import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class BuildingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> buildingData;
  final String buildingId;
  final bool isVerified;
  final bool isRejected;
  final Map<String, bool> verifications;
  final Function(String, bool) onVerificationChanged;
  final Future<void> Function(String, Map<String, dynamic>) onVerifyBuilding;
  final Future<void> Function(String, Map<String, dynamic>) onRejectBuilding;

  const BuildingDetailsPage({
    required this.buildingData,
    required this.buildingId,
    required this.isVerified,
    this.isRejected = false,
    required this.verifications,
    required this.onVerificationChanged,
    required this.onVerifyBuilding,
    required this.onRejectBuilding,
    Key? key,
    required List<String> wings,
  }) : super(key: key);

  @override
  State<BuildingDetailsPage> createState() => _BuildingDetailsPageState();
}

// ... Rest of the BuildingDetailsPage implementation remains exactly the same ...
// (No changes needed in building_details.dart as all the email and verification
// logic is handled in the AdminDashboard class)

class _BuildingDetailsPageState extends State<BuildingDetailsPage> {
  Map<String, dynamic>? userData;
  final TextEditingController remarkController = TextEditingController();
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

  Future<void> _showRejectionDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Reject Building Application'),
            ],
          ),
          content: TextField(
            controller: remarkController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Rejection Remarks',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.comment),
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
                if (remarkController.text.isNotEmpty) {
                  await widget.onRejectBuilding(
                    widget.buildingId,
                    {
                      ...widget.buildingData,
                      'rejectionRemark': remarkController.text,
                    },
                  );
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (widget.isVerified || widget.isRejected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showRejectionDialog,
              icon: const Icon(Icons.cancel),
              label: const Text('Reject Building'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              Text('Verify Building'),
            ],
          ),
          content: const Text('Are you sure you want to verify this building?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await widget.onVerifyBuilding(
                  widget.buildingId,
                  widget.buildingData,
                );
                Navigator.pop(context);
                Navigator.pop(context, true);
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

    if (widget.isRejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'This building application was rejected',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildVerificationRow(String label, dynamic value, String field) {
    bool switchValue = widget.isVerified || widget.isRejected
        ? (widget.verifications[field] ?? false)
        : (widget.verifications[field] ?? false);

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
            value: switchValue,
            onChanged: (widget.isVerified || widget.isRejected)
                ? null
                : (value) {
                    widget.onVerificationChanged(field, value);
                    setState(() {});
                  },
            activeColor: (widget.isVerified || widget.isRejected)
                ? Colors.grey
                : Colors.green,
            activeTrackColor: (widget.isVerified || widget.isRejected)
                ? Colors.grey.shade300
                : Colors.green.shade100,
            inactiveThumbColor:
                (widget.isVerified || widget.isRejected) ? Colors.grey : null,
            inactiveTrackColor: (widget.isVerified || widget.isRejected)
                ? Colors.grey.shade300
                : null,
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
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, MySocRoutes.buildingMaps,
                      arguments: {
                        'current': widget.buildingData['location'],
                        'name': widget.buildingData['buildingName']
                      });
                },
                child: Text("See location on Map")),
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
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }
}
