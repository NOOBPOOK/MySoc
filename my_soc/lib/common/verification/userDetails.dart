import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_soc/widgets/custom_toast.dart';

class UserDetailsPage extends ConsumerStatefulWidget {
  const UserDetailsPage({super.key});

  @override
  ConsumerState<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends ConsumerState<UserDetailsPage> {
  late String userId;
  late String loggedInUserId;
  late String loggedInUserName;
  bool _initialized = false;
  bool _personalInfoChecked = false;
  bool _residenceDetailsChecked = false;
  bool _registeredVehiclesChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        loggedInUserId = args['loggedInUserId'] ?? '';
        loggedInUserName = args['loggedInUserName'] ?? '';
      } else {
        userId = '';
        loggedInUserId = '';
        loggedInUserName = '';
      }
      _initialized = true;
      logger.i(
          'UserDetailsPage: Initialized for userId: $userId, loggedInUserId: $loggedInUserId, loggedInUserName: $loggedInUserName');
    }
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 62.0,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF222A54), width: 2.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        "User Details",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 25,
          color: Color(0xFF222A54),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // UI: Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF222A54),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
    return 'N/A';
  }

  String _formatTimestampWithTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
    return 'N/A';
  }

  int _calculateDaysPassedCount(dynamic verifiedDate) {
    if (verifiedDate == null || verifiedDate is! Timestamp) return 0;
    final verifiedDateTime = verifiedDate.toDate();
    final currentDateTime = DateTime.now();
    final verifiedDateOnly = DateTime(verifiedDateTime.year, verifiedDateTime.month, verifiedDateTime.day);
    final currentDateOnly = DateTime(currentDateTime.year, currentDateTime.month, currentDateTime.day);
    final daysPassed = currentDateOnly.difference(verifiedDateOnly).inDays;
    return daysPassed < 0 ? 0 : daysPassed;
  }

  Widget _buildHeaderMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _approveUser(BuildContext context) async {
    if (!_personalInfoChecked || !_residenceDetailsChecked || !_registeredVehiclesChecked) {
      CustomToast.show(
        context,
        type: -1,
        message: "Please verify all sections by checking the checkboxes first.",
      );
      return;
    }
    logger.i('_approveUser: starting approval for userId: $userId');
    try {
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isVerified': true,
        'verifiedBy': currentUserEmail,
        'verifiedDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      logger.i('_approveUser: successfully approved userId: $userId by $currentUserEmail');
      if (context.mounted) {
        CustomToast.show(
          context,
          type: 1,
          message: "User approved successfully!",
        );
      }
    } catch (e) {
      logger.e('_approveUser: failed to approve userId: $userId with error: $e');
      if (context.mounted) {
        CustomToast.show(
          context,
          type: -1,
          message: "Failed to approve user.",
        );
      }
    }
  }

  // UI: Detail Row for Personal Info Card
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF222A54).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF222A54)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UI: Column for Residence Grid
  Widget _buildResidenceColumn(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF222A54).withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 24,
                height: 0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222A54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            "No user details found",
            style: TextStyle(fontFamily: "Poppins", fontSize: 16),
          ),
        ),
      );
    }

    final userStream = ref.watch(userDocumentStreamProvider(userId));

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: userStream.when(
        data: (doc) {
          if (!doc.exists) {
            return const Center(
              child: Text(
                "User document does not exist.",
                style: TextStyle(fontFamily: "Poppins", fontSize: 16),
              ),
            );
          }

          final data = doc.data() as Map<String, dynamic>;
          final fName = data['firstName']?.toString().trim() ?? '';
          final lName = data['lastName']?.toString().trim() ?? '';

          final rawName =
              '$fName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();
          final nameParts = rawName.split(' ');
          final fullName = nameParts
              .map((part) {
                if (part.isEmpty) return '';
                return part[0].toUpperCase() + part.substring(1).toLowerCase();
              })
              .join(' ')
              .trim();

          final email = data['email']?.toString().trim().isNotEmpty == true
              ? data['email'].toString().trim()
              : 'N/A';
          final phone = data['phone']?.toString().trim().isNotEmpty == true
              ? data['phone'].toString().trim()
              : 'N/A';
          final otherPhone =
              data['otherPhone']?.toString().trim().isNotEmpty == true
                  ? data['otherPhone'].toString().trim()
                  : 'N/A';
          final aadhar =
              data['aadharNumber']?.toString().trim().isNotEmpty == true
                  ? data['aadharNumber'].toString().trim()
                  : 'N/A';
          final familyMembersVal = data['familyMembers'];
          final familyMembersStr = (familyMembersVal != null &&
                  familyMembersVal.toString().trim().isNotEmpty)
              ? familyMembersVal.toString().trim()
              : 'N/A';

          final wing = data['wing'] ?? 'N/A';
          final floor = data['floorNumber']?.toString() ?? 'N/A';
          final flat = data['flatNumber'] ?? 'N/A';
          final secondaryAddress =
              data['secondaryAddress']?.toString().trim().isNotEmpty == true
                  ? data['secondaryAddress'].toString().trim()
                  : 'N/A';

          final vehicles = (data['vehicles'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          final bool isVerified = data['isVerified'] ?? false;
          final initials = (fName.isNotEmpty ? fName[0] : '') +
              (lName.isNotEmpty ? lName[0] : '');

          final createdAt = data['createdAt'];
          final lastUpdated = data['lastUpdated'];
          final verifiedBy = data['verifiedBy']?.toString().trim().isNotEmpty == true ? data['verifiedBy'].toString().trim() : 'N/A';
          final verifiedDate = data['verifiedDate'];

          final createdAtFormatted = _formatTimestamp(createdAt);
          final lastUpdatedFormatted = _formatTimestamp(lastUpdated);
          final verifiedDateFormatted = _formatTimestampWithTime(verifiedDate);

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF222A54),
                        const Color(0xFF222A54).withOpacity(0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF222A54).withOpacity(0.2),
                        blurRadius: 11,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? Colors.green.shade400.withOpacity(0.3)
                                        : Colors.orange.shade400.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isVerified
                                          ? Colors.green.shade300
                                          : Colors.orange.shade300,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified
                                            ? Icons.verified
                                            : Icons.pending_actions,
                                        size: 13,
                                        color: isVerified
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isVerified
                                            ? "Verified"
                                            : "Pending Verification",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: isVerified
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isVerified && verifiedDate != null) ...[
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Since",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 9,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  _calculateDaysPassedCount(verifiedDate).toString(),
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  "Days",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 9,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20, thickness: 1),
                      _buildHeaderMetaRow(Icons.calendar_today_outlined, "Created:", createdAtFormatted),
                      const SizedBox(height: 6),
                      _buildHeaderMetaRow(Icons.edit_calendar_outlined, "Last Updated:", lastUpdatedFormatted),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Verification Details Card (if verified)
                if (isVerified) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222A54),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF222A54).withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Verification Audit Logs",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 16, thickness: 1),
                        _buildHeaderMetaRow(Icons.person_pin_outlined, "Verified By:", verifiedBy),
                        const SizedBox(height: 6),
                        _buildHeaderMetaRow(Icons.verified_user_outlined, "Verified Date:", verifiedDateFormatted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section: Personal Information
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFF222A54),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Personal Info",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            if (!isVerified) ...[
                              const Spacer(),
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _personalInfoChecked,
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54, width: 1.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _personalInfoChecked = val ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            _buildInfoRow(
                                Icons.email_outlined, "Email Address", email),
                            const Divider(height: 12),
                            _buildInfoRow(Icons.people_outline,
                                "Family Members", familyMembersStr),
                            const Divider(height: 12),
                            _buildInfoRow(Icons.fingerprint_outlined,
                                "Aadhaar Card", aadhar),
                            const Divider(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(Icons.phone_outlined,
                                      "Phone Number", phone),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoRow(
                                      Icons.phone_android_outlined,
                                      "Other Phone",
                                      otherPhone),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Residence Details
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFF222A54),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Residence Details",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            if (!isVerified) ...[
                              const Spacer(),
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _residenceDetailsChecked,
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54, width: 1.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _residenceDetailsChecked = val ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildResidenceColumn("Wing", wing),
                                const SizedBox(width: 12),
                                _buildResidenceColumn("Floor", floor),
                                const SizedBox(width: 12),
                                _buildResidenceColumn("Flat No", flat),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.location_on_outlined,
                                "Secondary Address", secondaryAddress),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Registered Vehicles
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFF222A54),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Registered Vehicles",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            if (!isVerified) ...[
                              const Spacer(),
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _registeredVehiclesChecked,
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54, width: 1.5),
                                  onChanged: (val) {
                                    setState(() {
                                      _registeredVehiclesChecked = val ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 14, bottom: 0, left: 14, right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vehicles.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.directions_car_outlined,
                                          size: 32,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        "No registered vehicles",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: vehicles.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                        height: 12, color: Colors.transparent),
                                itemBuilder: (context, index) {
                                  final vehicle = vehicles[index];
                                  final type =
                                      vehicle['type']?.toString() ?? 'N/A';
                                  final number =
                                      vehicle['number']?.toString() ?? 'N/A';
                                  final isCar = type.toLowerCase() == 'car';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222A54)
                                          .withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF222A54)
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCar
                                                ? Icons.directions_car
                                                : Icons.two_wheeler,
                                            color: const Color(0xFF222A54),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                type.toUpperCase(),
                                                style: const TextStyle(
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: Color(0xFF222A54),
                                                ),
                                              ),
                                              Text(
                                                number,
                                                style: TextStyle(
                                                  fontFamily: "Poppins",
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Approve Button (only if isVerified is false)
                if (!isVerified) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _approveUser(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222A54),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF222A54).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Approve",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF222A54)),
        ),
        error: (error, stack) {
          logger.e('Error loading user details: $error');
          return const Center(
            child: Text(
              "Error loading user details.",
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
