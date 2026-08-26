import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';

// ---------------------------------------------------------
// UI Component: WatchmanProfileView
// ---------------------------------------------------------
class WatchmanProfileView extends ConsumerStatefulWidget {
  const WatchmanProfileView({super.key});

  @override
  ConsumerState<WatchmanProfileView> createState() =>
      _WatchmanProfileViewState();
}

class _WatchmanProfileViewState extends ConsumerState<WatchmanProfileView> {
  // Backend: Sign out watchman
  Future<void> _handleSignOut(BuildContext context) async {
    logger.i('_handleSignOut starting');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      logger.i('_handleSignOut completed successfully');
    } catch (e) {
      logger.e('_handleSignOut failed with error: $e');
      if (context.mounted) {
        CustomToast.show(context, type: -1, message: 'Failed to sign out: $e');
      }
    }
  }

  // Backend: Fetch profile from Firestore
  Future<Map<String, dynamic>?> _fetchProfile() async {
    logger.d('_fetchProfile starting');
    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) {
      logger.w('_fetchProfile completed: watchmanState is null');
      return null;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(watchmanState.buildId)
          .collection('watchmen')
          .doc(watchmanState.watchId)
          .get();

      final data = doc.data();
      logger.d('_fetchProfile completed successfully');
      return data;
    } catch (e) {
      logger.e('_fetchProfile failed with error: $e');
      rethrow;
    }
  }

  // UI: Build a reusable profile information card
  Widget _buildProfileField(IconData icon, String title, String value,
      {VoidCallback? onTap}) {
    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF222A54).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF222A54)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        onTap != null ? Colors.blue : const Color(0xFF222A54),
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.open_in_new, color: Colors.blue, size: 20),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text("Profile data not found."));
        }

        final profileUrl = data['profile'] as String?;
        final name = data['name'] ?? 'Unknown';
        final phone = data['phone'] ?? 'N/A';
        final shift = data['shift'] ?? 'N/A';
        final username = data['username'] ?? 'N/A';
        final documentUrl = data['doc'] as String?;
        final creationRaw = data['creation'];
        final createdBy = data['createdBy'] ?? 'Unknown';

        String joined = 'Unknown';
        if (creationRaw is Timestamp) {
          joined = DateFormat.yMMMMd().format(creationRaw.toDate());
        } else if (creationRaw is String) {
          joined = creationRaw;
        }

        return Column(
          children: [
            // UI: Header section with gradient and avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF222A54), Color(0xFF3F4E99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          profileUrl != null && profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                      child: profileUrl == null || profileUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 45, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@$username",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            Expanded(
              child: FadedScrollMask(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // UI: Information Cards
                      _buildProfileField(Icons.phone, "Phone Number", phone),
                      if (documentUrl != null && documentUrl.isNotEmpty)
                        _buildProfileField(
                            Icons.file_present,
                            "Uploaded Documents",
                            "Tap here to download", onTap: () {
                          logger.i('Launching document URL: $documentUrl');
                          CustomToast.show(context,
                              type: 0, message: "Opening document...");
                          // Backend: Implement actual URL launch (e.g. url_launcher.launchUrl)
                        }),
                      _buildProfileField(
                          Icons.access_time, "Shift Timing", shift),
                      _buildProfileField(
                          Icons.calendar_today, "Joined On", joined),
                      _buildProfileField(
                          Icons.person_add, "Account Created By", createdBy),

                      const SizedBox(height: 10),

                      // UI: Sign Out Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleSignOut(context),
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
