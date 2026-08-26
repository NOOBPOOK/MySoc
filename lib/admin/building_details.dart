import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/admin_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/email_service.dart';
import 'package:my_soc/admin/admin_maps_view.dart';

class BuildingDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? buildingData;
  final String buildingId;

  const BuildingDetailsPage({
    this.buildingData,
    required this.buildingId,
    super.key,
  });

  @override
  ConsumerState<BuildingDetailsPage> createState() =>
      _BuildingDetailsPageState();
}

class _BuildingDetailsPageState extends ConsumerState<BuildingDetailsPage> {
  final TextEditingController remarkController = TextEditingController();

  bool _addressChecked = false;
  bool _specsChecked = false;
  bool _docsChecked = false;
  bool _infoChecked = false;

  Map<String, dynamic>? get _buildingData {
    if (widget.buildingData != null) return widget.buildingData;
    final asyncBuilding =
        ref.watch(buildingDetailsStreamProvider(widget.buildingId));
    if (asyncBuilding.value != null && asyncBuilding.value!.exists) {
      try {
        return asyncBuilding.value!.data() as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool get isVerified => _buildingData?['isVerified'] ?? false;
  bool get isRejected => _buildingData?['isRejected'] ?? false;

  Future<void> _showRejectionDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Reject Building'),
            ],
          ),
          content: TextField(
            controller: remarkController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Rejection Remarks',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  Navigator.pop(context);
                  await _rejectBuilding();
                } else {
                  CustomToast.show(context,
                      type: -1, message: 'Please enter rejection remarks.');
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

  Future<void> _showVerificationDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Navigator.pop(context);
                await _verifyBuilding();
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

  Future<void> _verifyBuilding() async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .update({
        'isVerified': true,
        'verificationDate': FieldValue.serverTimestamp(),
        'verifiedBy': 'admin',
      });

      // Send the approval email non-blockingly (fire-and-forget)
      final toEmail = _buildingData?['email'];
      final buildingName = _buildingData?['buildingName'] ?? 'Unknown Building';
      if (toEmail != null && toEmail.isNotEmpty) {
        Future.microtask(() => EmailService.instance
                .sendBuildingApprovalEmail(
              toEmail: toEmail,
              buildingName: buildingName,
            )
                .catchError((e) {
              print('Non-blocking email error: $e');
            }));
      }

      if (mounted) {
        CustomToast.show(context,
            type: 1, message: 'Building successfully verified.');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            type: -1, message: 'Error verifying building: $e');
      }
    }
  }

  Future<void> _rejectBuilding() async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .update({
        'isRejected': true,
        'rejectionDate': FieldValue.serverTimestamp(),
        'rejectedBy': 'admin',
        'rejectionRemark': remarkController.text,
      });

      // Send the rejection email non-blockingly (fire-and-forget)
      final toEmail = _buildingData?['email'];
      final buildingName = _buildingData?['buildingName'] ?? 'Unknown Building';
      if (toEmail != null && toEmail.isNotEmpty) {
        Future.microtask(() => EmailService.instance
                .sendBuildingRejectionEmail(
              toEmail: toEmail,
              buildingName: buildingName,
              remark: remarkController.text,
            )
                .catchError((e) {
              print('Non-blocking email error: $e');
            }));
      }

      if (mounted) {
        CustomToast.show(context,
            type: 1, message: 'Building has been rejected.');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context,
            type: -1, message: 'Error rejecting building: $e');
      }
    }
  }

  // --- UI Builder Methods ---

  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.location_on, color: Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Location Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
                const Spacer(),
                Checkbox(
                  value: isVerified
                      ? true
                      : (isRejected ? false : _addressChecked),
                  onChanged: (isVerified || isRejected)
                      ? null
                      : (bool? value) {
                          setState(() {
                            _addressChecked = value ?? false;
                          });
                        },
                ),
              ],
            ),
            const Divider(height: 12),
            const SizedBox(height: 10),
            _buildDetailRow('Street Name', _buildingData!['streetName']),
            const SizedBox(height: 10),
            _buildDetailRow('Landmark', _buildingData!['landmark']),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildDetailRow('City', _buildingData!['city'])),
                Expanded(
                    child: _buildDetailRow('State', _buildingData!['state'])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminMapsView(
                        defaultBuildingId: widget.buildingId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('View on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF222A54),
                  side: const BorderSide(color: Color(0xFF222A54)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.domain, color: Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Property Specifications',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
                const Spacer(),
                Checkbox(
                  value:
                      isVerified ? true : (isRejected ? false : _specsChecked),
                  onChanged: (isVerified || isRejected)
                      ? null
                      : (bool? value) {
                          setState(() {
                            _specsChecked = value ?? false;
                          });
                        },
                ),
              ],
            ),
            const Divider(height: 12),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildDetailRow(
                        'Area', _buildingData!['buildingArea'], ' sqft')),
                Expanded(
                    child: _buildDetailRow(
                        'Constructed', _buildingData!['constructionYear'])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildDetailRow(
                        'Total Wings', _buildingData!['numberOfWings'])),
                Expanded(
                    child: _buildDetailRow(
                        'Total Flats', _buildingData!['totalFlats'])),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wing Names',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    (_buildingData!['wings'] != null &&
                            _buildingData!['wings'] is List &&
                            (_buildingData!['wings'] as List).isNotEmpty)
                        ? (_buildingData!['wings'] as List)
                            .map((w) => (w is Map && w.containsKey('wingName'))
                                ? w['wingName']
                                : w.toString())
                            .join(', ')
                        : 'Not available',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.description, color: Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Property Documents',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
                const Spacer(),
                Checkbox(
                  value:
                      isVerified ? true : (isRejected ? false : _docsChecked),
                  onChanged: (isVerified || isRejected)
                      ? null
                      : (bool? value) {
                          setState(() {
                            _docsChecked = value ?? false;
                          });
                        },
                ),
              ],
            ),
            const Divider(height: 8),
            SizedBox(height: 8),
            _buildDocumentRow('Occupancy Certificate',
                _buildingData!['occupancyCertificatePath']),
            const SizedBox(height: 4),
            _buildDocumentRow(
                'Registration Document', _buildingData!['registrationDocPath']),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String label, dynamic urlStr) {
    bool hasDoc = urlStr != null &&
        urlStr.toString().trim().isNotEmpty &&
        urlStr.toString().trim() != 'null';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (hasDoc)
          TextButton.icon(
            onPressed: () async {
              final Uri url = Uri.parse(urlStr.toString().trim());
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 14),
            label: const Text('View PDF',
                style: TextStyle(color: Colors.red, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        else
          const Text(
            'Not available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not available';

    DateTime? date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    } else if (timestamp is int) {
      if (timestamp > 10000000000) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    if (date != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months[date.month - 1];
      return "${date.day} $month ${date.year}";
    }

    return timestamp.toString();
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info, color: Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Additional Information',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
                const Spacer(),
                Checkbox(
                  value:
                      isVerified ? true : (isRejected ? false : _infoChecked),
                  onChanged: (isVerified || isRejected)
                      ? null
                      : (bool? value) {
                          setState(() {
                            _infoChecked = value ?? false;
                          });
                        },
                ),
              ],
            ),
            const Divider(height: 12),
            const SizedBox(height: 4),
            _buildDetailRow('Created By', _buildingData!['email']),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildDetailRow('Created At',
                        _formatTimestamp(_buildingData!['createdAt']))),
                Expanded(
                    child: _buildDetailRow('Emergency Contact',
                        _buildingData!['emergencyContact'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfoCard() {
    if (!isVerified && !isRejected) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fact_check, color: Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Status Information',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
              ],
            ),
            const Divider(height: 12),
            const SizedBox(height: 4),
            if (isVerified) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildDetailRow(
                          'Verified By', _buildingData!['verifiedBy'])),
                  Expanded(
                      child: _buildDetailRow(
                          'Verification Date',
                          _formatTimestamp(
                              _buildingData!['verificationDate']))),
                ],
              ),
            ],
            if (isRejected) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildDetailRow(
                          'Rejected By', _buildingData!['rejectedBy'])),
                  Expanded(
                      child: _buildDetailRow('Rejection Date',
                          _formatTimestamp(_buildingData!['rejectionDate']))),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Reason', _buildingData!['rejectionRemark']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsWidget() {
    if (isVerified || isRejected) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.gavel,
                      color: Color(0xFF222A54), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Final Decision',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF222A54),
                      fontFamily: "Poppins"),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Please review all the building details carefully. This action will notify the building owner.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showRejectionDialog,
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_addressChecked &&
                          _specsChecked &&
                          _docsChecked &&
                          _infoChecked) {
                        _showVerificationDialog();
                      } else {
                        CustomToast.show(context,
                            type: -1,
                            message:
                                'Please select all checkboxes to continue.');
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Verify',
                        style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic rawValue, [String suffix = '']) {
    String displayValue = 'Not available';
    if (rawValue != null &&
        rawValue.toString().trim().isNotEmpty &&
        rawValue.toString().trim() != 'null') {
      displayValue = '${rawValue.toString().trim()}$suffix';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    List<String> imagePaths = [];
    if (_buildingData!['buildingImagePaths'] != null) {
      if (_buildingData!['buildingImagePaths'] is List) {
        imagePaths = List<String>.from(_buildingData!['buildingImagePaths']);
      } else if (_buildingData!['buildingImagePaths'] is String) {
        imagePaths = [_buildingData!['buildingImagePaths']];
      }
    }

    if (imagePaths.isEmpty) return const SizedBox.shrink();

    // Skip the first image if we are using it for the header
    final galleryImages =
        imagePaths.length > 1 ? imagePaths.sublist(1) : imagePaths;
    if (galleryImages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Additional Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222A54),
                fontFamily: "Poppins",
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: galleryImages.length,
              itemBuilder: (context, index) {
                final imageUrl = galleryImages[index];
                final heroTag = 'gallery_image_$index';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imageUrl: imageUrl,
                          tag: heroTag,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_buildingData == null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 62.0,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF222A54)),
          titleSpacing: 0,
          shape: const Border(
              bottom: BorderSide(color: Color(0xFF222A54), width: 2.0)),
          title: const Text(
            'Loading Details...',
            style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.w700,
                fontSize: 25,
                color: Color(0xFF222A54)),
          ),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF222A54))),
      );
    }

    String? headerImageUrl;
    if (_buildingData!['buildingImagePaths'] != null) {
      if (_buildingData!['buildingImagePaths'] is List &&
          _buildingData!['buildingImagePaths'].isNotEmpty) {
        headerImageUrl = _buildingData!['buildingImagePaths'][0];
      } else if (_buildingData!['buildingImagePaths'] is String) {
        headerImageUrl = _buildingData!['buildingImagePaths'];
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color(0xFF222A54),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                _buildingData!['buildingName'] ?? 'Building Details',
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
              ),
              background: headerImageUrl != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImageViewer(
                              imageUrl: headerImageUrl!,
                              tag: 'header_image',
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'header_image',
                            child: Image.network(headerImageUrl,
                                fit: BoxFit.cover),
                          ),
                          // Gradient overlay for better text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: const Color(0xFF222A54),
                      child: const Center(
                          child: Icon(Icons.apartment,
                              size: 80, color: Colors.white24)),
                    ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.language, color: Colors.white),
                tooltip: "Change Language",
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStatusInfoCard(),
                _buildAddressCard(),
                _buildSpecsCard(),
                _buildDocumentsCard(),
                _buildAdditionalInfoCard(),
                _buildStatusInfoCard(),
                _buildImageGallery(),
                _buildActionButtonsWidget(),
                const SizedBox(height: 32), // Padding at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    remarkController.dispose();
    super.dispose();
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: tag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
