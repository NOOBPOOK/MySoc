import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ViewPermissionsPage extends StatefulWidget {
  @override
  _ViewPermissionsPageState createState() => _ViewPermissionsPageState();
}

class _ViewPermissionsPageState extends State<ViewPermissionsPage> {
  String? buildingId;
  bool isLoading = true;

  final String username = 'rtk2825@gmail.com'; // Your Gmail address
  final String password = 'pbkx eupc qwnq qrka'; // Your app-specific password

  @override
  void initState() {
    super.initState();
    _loadBuildingId();
  }

  Future<void> _loadBuildingId() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userDoc.docs.isNotEmpty) {
        setState(() {
          buildingId = userDoc.docs.first['buildingId'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading building ID: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendStatusEmail(
    String userEmail,
    String status,
    Map<String, dynamic> permissionData,
    String remarks,
  ) async {
    final smtpServer = gmail(username, password);

    final startDateTime =
        (permissionData['startDateTime'] as Timestamp).toDate();
    final endDateTime = (permissionData['endDateTime'] as Timestamp).toDate();
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    final message = Message()
      ..from = Address(username)
      ..recipients.add(userEmail)
      ..subject = 'Amenity Booking Request ${status.toUpperCase()}'
      ..text = '''
Dear Resident,

Your amenity booking request has been ${status.toLowerCase()}.

Booking Details:
- Amenity: ${permissionData['amenityName']}
- Purpose: ${permissionData['purpose']}
- Start Time: ${dateFormat.format(startDateTime)}
- End Time: ${dateFormat.format(endDateTime)}
- Number of People: ${permissionData['numberOfPeople']}
- Organizer: ${permissionData['organizerName']}
${remarks.isNotEmpty ? '\nAdmin Remarks: $remarks' : ''}

${status == 'approved' ? 'We look forward to hosting your event.' : 'If you have any questions about this decision, please contact the administration.'}

Best regards,
Building Management Team
''';

    try {
      await send(message, smtpServer);
      print('Status email sent successfully');
    } catch (e) {
      print('Error sending email: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Custom header similar to announcements.dart
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .assignment, // Use an appropriate icon for permissions
                            color: Color(0xFFE94560),
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'View Permissions',
                                textStyle: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                speed: const Duration(milliseconds: 100),
                              ),
                            ],
                            isRepeatingAnimation: false,
                            totalRepeatCount: 1,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                // TabBar and TabBarView
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Color(0xFFE94560),
                        tabs: [
                          Tab(text: 'Pending'),
                          Tab(text: 'Approved'),
                          Tab(text: 'Rejected'),
                        ],
                      ),
                      Expanded(
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFE94560)))
                            : TabBarView(
                                children: [
                                  _buildRequestsList('pending'),
                                  _buildRequestsList('approved'),
                                  _buildRequestsList('rejected'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('permissions')
          .where('buildingId', isEqualTo: buildingId)
          .where('status', isEqualTo: status)
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)));
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No ${status} requests',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: requests.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        title: Text('Loading user details...',
                            style: TextStyle(color: Colors.white)),
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final flatNo = userData['flatNumber'] ?? 'N/A';
                  final userName = userData['firstName'] ?? 'Unknown';
                  final userName1 = userData['lastName'] ?? 'Unknown';

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 600),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Flat: $flatNo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Resident: $userName $userName1',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                      child: Text(
                                        status.capitalize(),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24,
                                    color: Colors.white.withOpacity(0.3)),

                                // Organizer Information Section
                                _buildSectionHeader('Organizer Information'),
                                _buildInfoRow(
                                    'Name', data['organizerName'] ?? 'N/A'),
                                _buildInfoRow(
                                    'Contact', data['organizerPhone'] ?? 'N/A'),

                                SizedBox(height: 16),

                                // Booking Details Section
                                _buildSectionHeader('Booking Details'),
                                _buildInfoRow(
                                    'Amenity', data['amenityName'] ?? 'N/A'),
                                _buildInfoRow(
                                    'Purpose', data['purpose'] ?? 'N/A'),
                                _buildInfoRow(
                                    'Number of People',
                                    data['numberOfPeople']?.toString() ??
                                        'N/A'),

                                SizedBox(height: 16),

                                // Date and Time Section
                                _buildSectionHeader('Date and Time'),
                                _buildInfoRow(
                                  'Start',
                                  data['startDateTime'] != null
                                      ? DateFormat('dd/MM/yyyy hh:mm a').format(
                                          (data['startDateTime'] as Timestamp)
                                              .toDate())
                                      : 'N/A',
                                ),
                                _buildInfoRow(
                                  'End',
                                  data['endDateTime'] != null
                                      ? DateFormat('dd/MM/yyyy hh:mm a').format(
                                          (data['endDateTime'] as Timestamp)
                                              .toDate())
                                      : 'N/A',
                                ),

                                if (data['additionalNotes']?.isNotEmpty ??
                                    false) ...[
                                  SizedBox(height: 16),
                                  _buildSectionHeader('Additional Notes'),
                                  Text(
                                    data['additionalNotes'],
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white70),
                                  ),
                                ],

                                if (data['remarks']?.isNotEmpty ?? false) ...[
                                  SizedBox(height: 16),
                                  _buildSectionHeader('Admin Remarks'),
                                  Text(
                                    data['remarks'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],

                                // Request Timeline
                                SizedBox(height: 16),
                                _buildSectionHeader('Request Timeline'),
                                _buildInfoRow(
                                  'Requested',
                                  DateFormat('dd/MM/yyyy hh:mm a').format(
                                      (data['requestedAt'] as Timestamp)
                                          .toDate()),
                                ),
                                if (data['updatedAt'] != null)
                                  _buildInfoRow(
                                    'Last Updated',
                                    DateFormat('dd/MM/yyyy hh:mm a').format(
                                        (data['updatedAt'] as Timestamp)
                                            .toDate()),
                                  ),

                                // Action Buttons for Pending Requests
                                if (status == 'pending')
                                  Column(
                                    children: [
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.check),
                                            label: Text('Approve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                            onPressed: () => _showUpdateDialog(
                                              context,
                                              request.id,
                                              'approved',
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.close),
                                            label: Text('Reject'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                            onPressed: () => _showUpdateDialog(
                                              context,
                                              request.id,
                                              'rejected',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    String requestId,
    String status,
  ) async {
    final remarksController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${status.capitalize()} Request',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add remarks (optional):',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            TextField(
              controller: remarksController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                hintText: 'Enter remarks',
                hintStyle: TextStyle(color: Colors.white70),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(
                requestId,
                status,
                remarksController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(
    String requestId,
    String status,
    String remarks,
  ) async {
    try {
      final permissionDoc = await FirebaseFirestore.instance
          .collection('permissions')
          .doc(requestId)
          .get();

      if (!permissionDoc.exists) {
        throw 'Permission request not found';
      }

      final permissionData = permissionDoc.data() as Map<String, dynamic>;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(permissionData['userId'])
          .get();

      if (!userDoc.exists) {
        throw 'User not found';
      }

      final userEmail = userDoc.data()?['email'];

      if (userEmail == null) {
        throw 'User email not found';
      }

      await FirebaseFirestore.instance
          .collection('permissions')
          .doc(requestId)
          .update({
        'status': status,
        'remarks': remarks,
        'updatedAt': Timestamp.now(),
      });

      await sendStatusEmail(
        userEmail,
        status,
        permissionData,
        remarks,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'approved' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Request ${status[0].toUpperCase() + status.substring(1)} successfully. Email notification sent.',
                ),
              ),
            ],
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('Error in _updateRequestStatus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
