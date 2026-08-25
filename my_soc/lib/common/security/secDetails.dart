import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/admin/building_details.dart';

class SecurityDetailsPage extends StatelessWidget {
  const SecurityDetailsPage({super.key});

  // Backend: Reset watchman password in Firebase Firestore
  Future<void> _resetWatchmanPassword(
      BuildContext context, String buildingId, String watchmanId) async {
    logger.i(
        'SecurityDetailsPage: _resetWatchmanPassword started for: $watchmanId');
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('watchmen')
          .doc(watchmanId)
          .update({'password': 'pass123'});

      if (context.mounted) {
        CustomToast.show(
          context,
          type: 1,
          message: "Password reset to 'pass123' successfully.",
        );
      }
    } catch (e) {
      logger.e('SecurityDetailsPage: Error resetting password - $e');
      if (context.mounted) {
        CustomToast.show(
          context,
          type: 2,
          message: "Failed to reset password.",
        );
      }
    }
    logger.d('SecurityDetailsPage: _resetWatchmanPassword finished');
  }

  @override
  Widget build(BuildContext context) {
    logger.d('SecurityDetailsPage: build method started');

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      logger.w('SecurityDetailsPage: Navigation arguments were null.');
      return const Scaffold(
        body: Center(
          child: Text("Error: No watchman details provided."),
        ),
      );
    }

    final watchmanId = args['id'] ?? 'Unknown';
    final buildingId = args['buildingId'] ?? 'Unknown';
    final name = args['name'] ?? 'No Name';
    final phone = args['phone'] ?? 'No Phone';
    final shift = args['shift'] ?? 'No Shift';
    final username = args['username'] ?? 'No Username';
    final profileUrl = args['profile'] as String?;
    final createdBy = args['createdBy'] ?? 'Unknown';
    final creationStr = args['creationStr'] ?? 'N/A';
    final isDisabled = args['isDisabled'] == true;
    final docUrl = args['doc'] as String?;

    final isNightShift = shift.toString().toLowerCase().contains('night');

    logger.i(
        'SecurityDetailsPage: rendering details for $name (ID: $watchmanId)');

    // UI: App Bar Builder
    PreferredSizeWidget buildAppBar() {
      logger.d('SecurityDetailsPage: buildAppBar started');
      final appBar = AppBar(
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
          "Security Details",
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
              logger.i('SecurityDetailsPage: Language click triggered');
              CustomToast.show(context,
                  type: 1, message: "Language options opened.");
            },
            icon: const Icon(Icons.language, color: Color(0xFF222A54)),
            tooltip: "Change Language",
          ),
          const SizedBox(width: 8),
        ],
      );
      logger.d('SecurityDetailsPage: buildAppBar finished');
      return appBar;
    }

    // UI: Detail Info Row Builder (Matches userDetails.dart)
    Widget buildInfoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF222A54).withValues(alpha: 0.05),
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

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header Profile Card Info
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF222A54),
                    const Color(0xFF222A54).withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF222A54).withValues(alpha: 0.2),
                    blurRadius: 11,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile Image on the left
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (profileUrl != null && profileUrl.isNotEmpty) {
                            logger.i(
                                'SecurityDetailsPage: Open FullScreenImageViewer for profileUrl');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageViewer(
                                  imageUrl: profileUrl,
                                  tag: 'profile_hero_$watchmanId',
                                ),
                              ),
                            );
                          } else {
                            logger.d(
                                'SecurityDetailsPage: No profile image available for viewing');
                            CustomToast.show(context,
                                type: 2, message: "No profile image uploaded.");
                          }
                        },
                        child: Hero(
                          tag: 'profile_hero_$watchmanId',
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 9,
                                  offset: const Offset(0, 3.5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileUrl != null && profileUrl.isNotEmpty
                                  ? Image.network(
                                      profileUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person,
                                                  size: 40,
                                                  color: Colors.white),
                                    )
                                  : const Icon(Icons.person,
                                      size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDisabled ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            isDisabled ? "Disabled" : "Active",
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Name and Shift Details on the right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Shift chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isNightShift
                                    ? Icons.nights_stay_rounded
                                    : Icons.wb_sunny_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "$shift",
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Account Information Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                    child: const Row(
                      children: [
                        Icon(Icons.manage_accounts_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Account Information",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        buildInfoRow(Icons.phone_outlined, "Phone Number", phone),
                        const Divider(height: 12),
                        buildInfoRow(Icons.alternate_email_rounded, "Username", username),
                        const Divider(height: 12),
                        buildInfoRow(Icons.admin_panel_settings_outlined, "Created By", createdBy),
                        const Divider(height: 12),
                        buildInfoRow(Icons.calendar_today_outlined, "Account Created", creationStr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Verification Documents Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                    child: const Row(
                      children: [
                        Icon(Icons.folder_open_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Verification Documents",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: docUrl != null && docUrl.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded,
                                    color: Colors.redAccent, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Uploaded Verification PDF",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Document ID: ${watchmanId.substring(0, watchmanId.length > 8 ? 8 : watchmanId.length)}...",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    logger.i('SecurityDetailsPage: Document view triggered');
                                    CustomToast.show(context,
                                        type: 1, message: "Opening document...");
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded,
                                      color: Color(0xFF222A54)),
                                  tooltip: "Open Document",
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 12.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.folder_open_outlined,
                                    size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text(
                                  "No Documents Registered",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Documents list is empty. Upload options will be available soon.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMiniDocBadge("Identity Verification"),
                                    _buildMiniDocBadge("Address Verification"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: Danger Zone Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Danger Zone",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Resetting the password will override their current credentials and set their login password to 'pass123'.",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _resetWatchmanPassword(
                                context, buildingId, watchmanId),
                            icon: const Icon(Icons.lock_reset_rounded,
                                color: Colors.redAccent),
                            label: const Text(
                              "Reset Password",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );

    logger.d('SecurityDetailsPage: build method finished');
    return scaffold;
  }

  // UI: mini docs helper
  Widget _buildMiniDocBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
