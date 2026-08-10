import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';

class WatchmanHome extends ConsumerStatefulWidget {
  const WatchmanHome({super.key});

  @override
  ConsumerState<WatchmanHome> createState() => _WatchmanHomeState();
}

class _WatchmanHomeState extends ConsumerState<WatchmanHome> {
  int _currentIndex = 0;

  // UI: Build the main content based on selected tab
  Widget _buildBodyContent() {
    if (_currentIndex == 0) {
      return const WatchmanDashboardView();
    } else if (_currentIndex == 1) {
      return const WatchmanLogsView();
    } else {
      return const WatchmanProfileView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchmanState = ref.watch(watchmanProvider);
    if (watchmanState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: WatchmanHeader(buildName: watchmanState.buildName),
      bottomNavigationBar: WatchmanFooter(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanDashboardView
// ---------------------------------------------------------
class WatchmanDashboardView extends StatelessWidget {
  const WatchmanDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        WatchmanDashboardGrid(),
        SizedBox(height: 24),
        Expanded(child: WatchmanRecentLogsWidget()),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanRecentLogsWidget
// ---------------------------------------------------------
class WatchmanRecentLogsWidget extends ConsumerWidget {
  const WatchmanRecentLogsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsyncValue = ref.watch(watchmanLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                "Recent Logs",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222A54),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: "This view displays 10 most recent visits only",
                triggerMode: TooltipTriggerMode.tap,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF222A54),
                  fontWeight: FontWeight.w500,
                  fontFamily: "Poppins",
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: logsAsyncValue.when(
            data: (snapshot) {
              final allDocs = snapshot.docs.toList();
              allDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['timestamp'] as Timestamp?;
                final bTime = bData['timestamp'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });
              final logs = allDocs.take(10).toList();
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("No recent logs found."),
                );
              }
              return FadedScrollMask(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    var logData = logs[index].data() as Map<String, dynamic>;
                    return WatchmanLogTile(
                      logData: logData,
                      isExpandable: false,
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Error: $error"),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanDashboardGrid
// ---------------------------------------------------------
class WatchmanDashboardGrid extends StatelessWidget {
  const WatchmanDashboardGrid({super.key});

  Widget _buildCounterCard({
    required BuildContext context,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.21,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            flex: 15,
            child: Row(
              children: [
                Expanded(
                  child: _buildCounterCard(
                    context: context,
                    title: "Visitors Today",
                    count: "69",
                    color: const Color.fromARGB(255, 0, 72, 255),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCounterCard(
                    context: context,
                    title: "Couriers Today",
                    count: "67",
                    color: const Color.fromARGB(255, 0, 72, 255),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context: context,
                    title: "Add Visitor",
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFF222A54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const VisitorDialog(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context: context,
                    title: "Add Courier",
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFF222A54),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CourrierDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanLogsView
// ---------------------------------------------------------
class WatchmanLogsView extends ConsumerWidget {
  const WatchmanLogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsyncValue = ref.watch(watchmanLogsProvider);
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: logsAsyncValue.when(
              data: (snapshot) => DisplayRecords(logs: snapshot.docs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                logger.e('Error loading logs: $error');
                return Center(child: Text("Something went Wrong $error"));
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    logger.i('_handleSignOut completed successfully');
  }

  // Backend: Fetch profile from Firestore
  Future<Map<String, dynamic>?> _fetchProfile() async {
    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('buildings')
        .doc(watchmanState.buildId)
        .collection('watchmen')
        .doc(watchmanState.watchId)
        .get();

    return doc.data();
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

// ---------------------------------------------------------
// UI Component: WatchmanHeader
// ---------------------------------------------------------
class WatchmanHeader extends StatelessWidget implements PreferredSizeWidget {
  final String buildName;

  const WatchmanHeader({super.key, required this.buildName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 62.0,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(
          color: Color(0xFF222A54), // Dark border
          width: 2.0,
        ),
      ),
      title: Text(
        buildName,
        style: const TextStyle(
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

  @override
  Size get preferredSize => const Size.fromHeight(62.0);
}

// ---------------------------------------------------------
// UI Component: WatchmanFooter
// ---------------------------------------------------------
class WatchmanFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const WatchmanFooter({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  // UI: Build individual icon item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(
                index: 0, icon: Icons.dashboard_rounded, label: "Dashboard"),
            _buildNavItem(
                index: 1, icon: Icons.list_alt_rounded, label: "Logs"),
            _buildNavItem(
                index: 2, icon: Icons.person_rounded, label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: VisitorDialog
// ---------------------------------------------------------
class VisitorDialog extends ConsumerStatefulWidget {
  const VisitorDialog({super.key});

  @override
  ConsumerState<VisitorDialog> createState() => _VisitorDialogState();
}

class _VisitorDialogState extends ConsumerState<VisitorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _countController =
      TextEditingController(text: "1");
  final TextEditingController _flatNumber = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _selectedWing;
  bool _forBuilding = false;
  List _wings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(watchmanProvider);
      if (state != null) {
        _wings = state.wings;
        if (_wings.isEmpty) {
          _wings = ["A", "B", "C"];
        }
        setState(() {
          _selectedWing =
              _wings[0] is Map ? _wings[0]['wingName'] : _wings[0].toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _countController.dispose();
    _flatNumber.dispose();
    _description.dispose();
    super.dispose();
  }

  // Backend: Records visitor details to Firestore
  Future<void> _recordDetails() async {
    logger.i(
        '_recordDetails starting for name: ${_nameController.text.trim()}, forBuilding: $_forBuilding');

    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) {
      logger.e('Watchman state is null when recording visitor');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(watchmanState.buildId)
          .collection('logs')
          .add({
        'name': _nameController.text.trim(),
        'from': _fromController.text.trim(),
        'count': _countController.text.trim(),
        'forBuild': _forBuilding,
        'flat': _forBuilding ? "" : _flatNumber.text.trim(),
        'wing': _forBuilding ? "" : _selectedWing,
        'createdBy': watchmanState.watchName,
        'createdById': watchmanState.watchId,
        'timestamp': Timestamp.now(),
        'reason': _description.text.trim()
      });
      logger.i('_recordDetails completed successfully');
      if (mounted) {
        CustomToast.show(context, type: 1, message: 'Recorded successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error recording visitor details: $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: e.toString());
      }
    }
  }

  // UI: Build generic text field
  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // UI: For building maintenance checkbox
  Widget _buildForBuildingCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _forBuilding,
          onChanged: (bool? newValue) {
            setState(() {
              _forBuilding = newValue ?? false;
            });
          },
        ),
        const Text("For Building's Maintainenace",
            textScaler: TextScaler.linear(0.8))
      ],
    );
  }

  // UI: Wings and Flat selection
  Widget _buildWingAndFlatSelection() {
    if (_forBuilding || _selectedWing == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Wings"),
            ),
            DropdownButton<String>(
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              value: _selectedWing,
              icon: const Icon(Icons.apartment),
              iconSize: 24,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedWing = newValue;
                  });
                }
              },
              items: _wings.map((wing) {
                String wingName =
                    wing is Map ? wing['wingName'] : wing.toString();
                return DropdownMenuItem<String>(
                  value: wingName,
                  child: Text(wingName),
                );
              }).toList(),
            ),
          ],
        ),
        TextField(
          controller: _flatNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            constraints: BoxConstraints(maxWidth: 120),
            labelText: 'Flat Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // UI: Individual reason chip
  Widget _buildReasonChip(String label, Color color, String reasonText) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _description.text = reasonText;
        });
      },
      child: Chip(
        padding: const EdgeInsets.all(0),
        label: Text(label, textScaler: const TextScaler.linear(0.9)),
        backgroundColor: color,
      ),
    );
  }

  // UI: Quick reason chips
  Widget _buildQuickReasonChips() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 0,
          children: [
            _buildReasonChip("Swiggy", const Color.fromARGB(255, 255, 217, 114),
                "Food deleivery by Swiggy"),
            _buildReasonChip("Zomato", const Color.fromARGB(255, 255, 163, 163),
                "Food deleivery by Zomato"),
            _buildReasonChip(
                "Electrician",
                const Color.fromARGB(255, 210, 208, 205),
                "Electrician in the house"),
            _buildReasonChip("Plumber", Colors.blueAccent, "Plumber works"),
            _buildReasonChip(
                "Courriers",
                const Color.fromARGB(255, 250, 185, 168),
                "Courrier by ECommerce Websites"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add a visitor log"),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 10),
              _buildTextField(_fromController, 'From Where'),
              const SizedBox(height: 10),
              _buildTextField(_countController, 'People Count',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildForBuildingCheckbox(),
              _buildWingAndFlatSelection(),
              const SizedBox(height: 10),
              _buildQuickReasonChips(),
              _buildTextField(_description, 'Reason for Visit', maxLines: 3),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _recordDetails,
          child: const Text("Record"),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: CourrierDialog
// ---------------------------------------------------------
class CourrierDialog extends ConsumerStatefulWidget {
  const CourrierDialog({super.key});

  @override
  ConsumerState<CourrierDialog> createState() => _CourrierDialogState();
}

class _CourrierDialogState extends ConsumerState<CourrierDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _flatNumber = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _selectedWing;
  List _wings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(watchmanProvider);
      if (state != null) {
        _wings = state.wings;
        if (_wings.isEmpty) {
          _wings = ["A", "B", "C"];
        }
        setState(() {
          _selectedWing =
              _wings[0] is Map ? _wings[0]['wingName'] : _wings[0].toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flatNumber.dispose();
    _description.dispose();
    super.dispose();
  }

  // Backend: Sends notification to server
  Future<void> _sendNotiToServer(String buildId) async {
    logger.i('_sendNotiToServer starting for courrier buildId: $buildId');
    try {
      QuerySnapshot notifiedUser = await FirebaseFirestore.instance
          .collection('users')
          .where('buildingId', isEqualTo: buildId)
          .where('flatNumber', isEqualTo: _flatNumber.text.trim())
          .where('wing', isEqualTo: _selectedWing)
          .get()
          .timeout(const Duration(seconds: 10));

      if (notifiedUser.docs.isNotEmpty) {
        final url = Uri.parse('http://192.168.29.138:3000/courriers');
        Map<String, String> headers = {'Content-Type': 'application/json'};
        Map<String, String> body = {
          'delivery_name': _nameController.text.trim(),
          'user_id': notifiedUser.docs[0].id.toString(),
          'description': _description.text.trim(),
        };

        final response =
            await http.post(url, headers: headers, body: json.encode(body));
        if (response.statusCode == 201) {
          logger.i('_sendNotiToServer completed successfully (status 201)');
        } else {
          logger.e(
              '_sendNotiToServer failed: ${response.statusCode} ${response.body}');
        }
      } else {
        logger.i(
            '_sendNotiToServer completed: User not found for flat ${_flatNumber.text.trim()} in wing $_selectedWing');
      }
    } catch (e) {
      logger.e('Error in _sendNotiToServer: $e');
    }
  }

  // Backend: Saves courrier info to Firestore
  Future<void> _saveCourrierInfo() async {
    logger.i(
        '_saveCourrierInfo starting for deliveryName: ${_nameController.text.trim()}, flat: ${_flatNumber.text.trim()}, wing: $_selectedWing');

    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) {
      logger.e('Watchman state is null when saving courrier');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(watchmanState.buildId)
          .collection('courriers')
          .add({
        'deliveryName': _nameController.text.trim(),
        'flat': _flatNumber.text.trim(),
        'wing': _selectedWing,
        'description': _description.text.trim(),
        'recievedAt': Timestamp.now(),
        'recievedName': watchmanState.watchName,
        'recievedBy': watchmanState.watchId,
        'status': false
      });
      logger.i('_saveCourrierInfo saved document successfully');

      // Send notification in background
      _sendNotiToServer(watchmanState.buildId);

      logger.i('_saveCourrierInfo completed successfully');
      if (mounted) {
        CustomToast.show(context,
            type: 1, message: 'Data recorded successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error in _saveCourrierInfo: $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: e.toString());
      }
    }
  }

  // UI: Build generic text field
  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // UI: Wings and Flat selection
  Widget _buildWingAndFlatSelection() {
    if (_selectedWing == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Wings"),
            ),
            DropdownButton<String>(
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              value: _selectedWing,
              icon: const Icon(Icons.apartment),
              iconSize: 24,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedWing = newValue;
                  });
                }
              },
              items: _wings.map((wing) {
                String wingName =
                    wing is Map ? wing['wingName'] : wing.toString();
                return DropdownMenuItem<String>(
                  value: wingName,
                  child: Text(wingName),
                );
              }).toList(),
            ),
          ],
        ),
        TextField(
          controller: _flatNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            constraints: BoxConstraints(maxWidth: 120),
            labelText: 'Flat Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // UI: Individual reason chip
  Widget _buildReasonChip(String label, Color color, String reasonText) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _description.text = reasonText;
        });
      },
      child: Chip(
        padding: const EdgeInsets.all(0),
        label: Text(label, textScaler: const TextScaler.linear(0.9)),
        backgroundColor: color,
      ),
    );
  }

  // UI: Quick reason chips
  Widget _buildQuickReasonChips() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 0,
          children: [
            _buildReasonChip("Amazon", const Color.fromARGB(255, 255, 217, 114),
                "Package Recieved from Amazon"),
            _buildReasonChip(
                "Flipkart",
                const Color.fromARGB(255, 255, 163, 163),
                "Package Recieved from Flipkart"),
            _buildReasonChip(
                "Courriers",
                const Color.fromARGB(255, 210, 208, 205),
                "A courrier is recieved. Please collect from base"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Notify About Packages"),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              _buildTextField(_nameController, 'From General Name'),
              const SizedBox(height: 10),
              _buildWingAndFlatSelection(),
              const SizedBox(height: 10),
              _buildQuickReasonChips(),
              _buildTextField(
                  _description, 'Custom Description for Notification',
                  maxLines: 3),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCourrierInfo,
          child: const Text("Record"),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// Component: ConnectionStatus
// ---------------------------------------------------------
class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool isConnected = false;
  StreamSubscription<List<ConnectivityResult>>? subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  // Backend: Starts listening to connectivity changes
  void _startListening() {
    logger.d('_startListening starting connectivity check');
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        setState(() => isConnected = false);
        logger.i('Connectivity changed: Offline');
      } else {
        final hasInternet = await _hasInternetConnection();
        setState(() => isConnected = hasInternet);
        logger.i(
            'Connectivity changed: ${hasInternet ? "Online" : "Offline (No Internet)"}');
      }
    });
    logger.d('_startListening completed setup');
  }

  // Backend: Stops listening to connectivity changes
  void _stopListening() {
    logger.d('_stopListening starting');
    subscription?.cancel();
    logger.d('_stopListening completed successfully');
  }

  // Backend: Checks internet access
  Future<bool> _hasInternetConnection() async {
    logger.d('_hasInternetConnection starting');
    try {
      final result = await InternetAddress.lookup('example.com');
      bool hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      logger.d('_hasInternetConnection completed with result: $hasConnection');
      return hasConnection;
    } catch (_) {
      logger.e('_hasInternetConnection failed');
      return false;
    }
  }

  // UI: Build Connection Status Indicator
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isConnected
                  ? Colors.green
                  : const Color.fromARGB(255, 201, 230, 255),
              width: 2.0,
            ),
          ),
          child: Text(
            isConnected ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Component: DisplayRecords
// ---------------------------------------------------------
class DisplayRecords extends StatefulWidget {
  final List<QueryDocumentSnapshot> logs;

  const DisplayRecords({super.key, required this.logs});

  @override
  State<DisplayRecords> createState() => _DisplayRecordsState();
}

class _DisplayRecordsState extends State<DisplayRecords> {
  String _searchQuery = '';

  // UI: Build an individual log record tile
  Widget _buildLogTile(BuildContext context, int index,
      List<QueryDocumentSnapshot> filteredLogs) {
    var logData = filteredLogs[index].data() as Map<String, dynamic>;
    return WatchmanLogTile(
      logData: logData,
      isExpandable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter logs based on search query
    final filteredLogs = widget.logs.where((log) {
      final logData = log.data() as Map<String, dynamic>;
      final name = (logData['name'] ?? '').toString().toLowerCase();
      final wing = (logData['wing'] ?? '').toString().toLowerCase();
      final flat = (logData['flat'] ?? '').toString().toLowerCase();

      final searchableString = '$name $wing $flat $wing-$flat'.toLowerCase();

      return searchableString.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Sticky Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by visitor name or flat number.',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF222A54), width: 1.5),
              ),
            ),
          ),
        ),
        // Filtered list with ShaderMask
        // Filtered list with ShaderMask
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: filteredLogs.isEmpty
                    ? const Center(
                        child: Text("No logs found matching your search."))
                    : FadedScrollMask(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, top: 8.0, bottom: 80.0),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) =>
                              _buildLogTile(context, index, filteredLogs),
                        ),
                      ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Backend: Implement CSV Export
                    logger.i('Export to CSV requested from Watchman Logs View');
                  },
                  backgroundColor: const Color(0xFF222A54),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "Export CSV",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: WatchmanLogTile
// ---------------------------------------------------------
class WatchmanLogTile extends StatefulWidget {
  final Map<String, dynamic> logData;
  final bool isExpandable;

  const WatchmanLogTile({
    super.key,
    required this.logData,
    this.isExpandable = false,
  });

  @override
  State<WatchmanLogTile> createState() => _WatchmanLogTileState();
}

class _WatchmanLogTileState extends State<WatchmanLogTile> {
  bool _isExpanded = false;

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return "Just now";
    if (difference.inHours < 1) return "${difference.inMinutes}m ago";
    if (difference.inDays < 1) return "${difference.inHours}h ago";
    return "${difference.inDays}d ago";
  }

  Widget _buildExpandedDetailRow(String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF222A54),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = (widget.logData['timestamp'] as Timestamp).toDate();
    String timeAgo = _getTimeAgo(date);

    // Derived values
    String? flatWing = widget.logData['forBuild'] == true
        ? "Building Maintenance"
        : '${widget.logData['wing']}-${widget.logData['flat']}';
    String? createdBy =
        widget.logData['createdBy'] ?? widget.logData['watchmanName'];

    return GestureDetector(
      onTap: widget.isExpandable
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 6, top: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF222A54).withOpacity(0.1),
                  child: Icon(
                    widget.logData['forBuild'] == true
                        ? Icons.engineering
                        : Icons.person,
                    color: const Color(0xFF222A54),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.logData['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF222A54),
                        ),
                      ),
                      Text(
                        widget.logData['forBuild'] == true
                            ? "Building Maintenance"
                            : 'Flat: ${widget.logData['wing']}-${widget.logData['flat']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                if (widget.isExpandable)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (widget.isExpandable && _isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),
              _buildExpandedDetailRow("Name", widget.logData['name']),
              _buildExpandedDetailRow("From Where",
                  widget.logData['fromWhere'] ?? widget.logData['from']),
              _buildExpandedDetailRow("Flat/Wing", flatWing),
              _buildExpandedDetailRow("Reason", widget.logData['reason']),
              _buildExpandedDetailRow(
                  "Count", widget.logData['count']?.toString()),
              _buildExpandedDetailRow("Created By", createdBy),
            ],
          ],
        ),
      ),
    );
  }
}
