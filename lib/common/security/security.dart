import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/providers/watchman_provider.dart';

class BuildingSecurityPage extends ConsumerStatefulWidget {
  const BuildingSecurityPage({super.key});

  @override
  ConsumerState<BuildingSecurityPage> createState() =>
      _BuildingSecurityPageState();
}

class _BuildingSecurityPageState extends ConsumerState<BuildingSecurityPage> {
  late String userId;
  late String userEmail;
  late String buildingId;
  late int designation;
  bool _initialized = false;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    logger.d('BuildingSecurityPage: didChangeDependencies started');
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? 'Unknown';
        userEmail = args['userEmail'] ?? 'Unknown';
        buildingId = args['buildingId'] ?? 'Unknown';
        designation = args['designation'] ?? 0;
      } else {
        userId = 'Unknown';
        userEmail = 'Unknown';
        buildingId = 'Unknown';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          'BuildingSecurityPage: initialized for user: $userId, designation: $designation');

      if (designation != 4) {
        logger.w(
            'BuildingSecurityPage: Access Denied. Designation $designation is not 4.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomToast.show(
            context,
            type: 2,
            message:
                "Access Denied: Only Secretaries can access Building Security.",
          );
          Navigator.pop(context);
        });
      }
    }
    logger.d('BuildingSecurityPage: didChangeDependencies finished');
  }

  // Backend: Friendly Date Formatter
  String _formatFriendlyDate(Timestamp? timestamp) {
    logger.d(
        'BuildingSecurityPage: _formatFriendlyDate started with timestamp: $timestamp');
    if (timestamp == null) {
      logger
          .d('BuildingSecurityPage: _formatFriendlyDate finished. Output: N/A');
      return 'N/A';
    }
    final dt = timestamp.toDate();
    final months = [
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
    final monthStr = months[dt.month - 1];
    final formatted = "${dt.day} $monthStr ${dt.year}";
    logger.d(
        'BuildingSecurityPage: _formatFriendlyDate finished. Output: $formatted');
    return formatted;
  }

  // Backend: Toggle watchman status in database
  Future<void> _toggleWatchmanStatus(
      String docId, bool currentIsDisabled) async {
    logger.i(
        'BuildingSecurityPage: _toggleWatchmanStatus started for docId: $docId, currentIsDisabled: $currentIsDisabled');
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('watchmen')
          .doc(docId)
          .update({'isDisabled': !currentIsDisabled});

      if (mounted) {
        CustomToast.show(
          context,
          type: 1,
          message: currentIsDisabled
              ? "Watchman enabled successfully."
              : "Watchman disabled successfully.",
        );
      }
    } catch (e) {
      logger.e('BuildingSecurityPage: Error toggling watchman status - $e');
      if (mounted) {
        CustomToast.show(context, type: 2, message: "Error updating status.");
      }
    }
    logger.d('BuildingSecurityPage: _toggleWatchmanStatus finished');
  }

  // UI: App Bar Builder
  PreferredSizeWidget _buildAppBar() {
    logger.d('BuildingSecurityPage: _buildAppBar started');
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
        "Building Security",
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
            logger.i('BuildingSecurityPage: Language click triggered');
            CustomToast.show(context,
                type: 1, message: "Language options opened.");
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
    logger.d('BuildingSecurityPage: _buildAppBar finished');
    return appBar;
  }

  // UI: Search bar widget
  Widget _buildSearchBar() {
    logger.d('BuildingSecurityPage: _buildSearchBar started');
    final searchBar = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
        logger
            .d('BuildingSecurityPage: search query updated to: $_searchQuery');
      },
      decoration: InputDecoration(
        hintText: 'Search security personnel',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
        ),
      ),
    );
    logger.d('BuildingSecurityPage: _buildSearchBar finished');
    return searchBar;
  }

  // UI: Build Individual Watchman Card
  Widget _buildWatchmanCard(Map<String, dynamic> data) {
    logger.d(
        'BuildingSecurityPage: _buildWatchmanCard started for: ${data['name']}');
    final name = data['name'] ?? 'No Name';
    final phone = data['phone'] ?? 'No Phone';
    final shift = data['shift'] ?? 'No Shift';
    final username = data['username'] ?? 'No Username';
    final profileUrl = data['profile'] as String?;
    final isDisabled = data['isDisabled'] == true;

    final isNightShift = shift.toString().toLowerCase().contains('night');

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade300,
          width: isDisabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDisabled ? 0.01 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Body Padding
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture / Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF222A54).withValues(alpha: 0.1),
                        width: 1.5),
                  ),
                  child: ClipOval(
                    child: profileUrl != null && profileUrl.isNotEmpty
                        ? Image.network(
                            profileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person,
                                    size: 24, color: Color(0xFF222A54)),
                          )
                        : const Icon(Icons.person,
                            size: 24, color: Color(0xFF222A54)),
                  ),
                ),
                const SizedBox(width: 14),
                // Text Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? Colors.grey.shade600
                                    : const Color(0xFF222A54),
                              ),
                            ),
                          ),
                          if (isDisabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Disabled",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            phone,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 12,
                              color: isDisabled
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      // Shift Tag Displayed Below
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey.shade100
                              : (isNightShift
                                  ? Colors.indigo.shade50
                                  : Colors.orange.shade50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDisabled
                                ? Colors.grey.shade300
                                : (isNightShift
                                    ? Colors.indigo.shade200
                                    : Colors.orange.shade200),
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
                              size: 14,
                              color: isDisabled
                                  ? Colors.grey.shade600
                                  : (isNightShift
                                      ? Colors.indigo.shade700
                                      : Colors.orange.shade700),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "$shift Shift",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? Colors.grey.shade600
                                    : (isNightShift
                                        ? Colors.indigo.shade700
                                        : Colors.orange.shade700),
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // Bottom Actions Row
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildCardButton(
                  text: "View Details",
                  icon: Icons.info_outline_rounded,
                  onPressed: () {
                    logger.i('BuildingSecurityPage: Navigate to SecurityDetailsPage for: ${data['name']}');
                    Navigator.pushNamed(context, '/securityDetails', arguments: {
                      'id': data['id'],
                      'buildingId': buildingId,
                      'name': data['name'],
                      'phone': data['phone'],
                      'shift': data['shift'],
                      'username': data['username'],
                      'profile': data['profile'],
                      'createdBy': data['createdBy'],
                      'creationStr': _formatFriendlyDate(data['creation'] as Timestamp?),
                      'isDisabled': data['isDisabled'] == true,
                      'doc': data['doc'],
                    });
                  },
                  color: const Color(0xFF222A54),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: const Color(0xFFEEEEEE),
                ),
                _buildCardButton(
                  text: isDisabled ? "Enable" : "Disable",
                  icon: isDisabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_flipped,
                  onPressed: () =>
                      _toggleWatchmanStatus(data['id'], isDisabled),
                  color: isDisabled ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    logger.d('BuildingSecurityPage: _buildWatchmanCard finished');
    return card;
  }

  // UI: Card action button builder
  Widget _buildCardButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          text,
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    logger.d('BuildingSecurityPage: build method started');
    if (!_initialized || designation != 4) {
      logger.d(
          'BuildingSecurityPage: build method finished rendering (not initialized or access denied)');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF222A54)),
        ),
      );
    }

    final watchmenAsync = ref.watch(watchmenStreamProvider(buildingId));

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 14.0, bottom: 0.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: watchmenAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF222A54)),
                ),
                error: (err, stack) {
                  logger.e('BuildingSecurityPage: Stream error - $err');
                  return const Center(
                    child: Text(
                      'Error loading security personnel',
                      style:
                          TextStyle(fontFamily: "Poppins", color: Colors.red),
                    ),
                  );
                },
                data: (snapshot) {
                  if (snapshot.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No security personnel registered.',
                        style: TextStyle(
                            fontFamily: "Poppins",
                            color: Colors.grey,
                            fontSize: 14),
                      ),
                    );
                  }

                  final watchmen = snapshot.docs.map((doc) {
                    return {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    };
                  }).toList();

                  // Filter by Search Query
                  final filteredWatchmen = watchmen.where((w) {
                    final name = (w['name'] ?? '').toString().toLowerCase();
                    final phone = (w['phone'] ?? '').toString().toLowerCase();
                    final shift = (w['shift'] ?? '').toString().toLowerCase();
                    final username =
                        (w['username'] ?? '').toString().toLowerCase();

                    return name.contains(_searchQuery) ||
                        phone.contains(_searchQuery) ||
                        shift.contains(_searchQuery) ||
                        username.contains(_searchQuery);
                  }).toList();

                  if (filteredWatchmen.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching personnel found.',
                        style: TextStyle(
                            fontFamily: "Poppins",
                            color: Colors.grey,
                            fontSize: 14),
                      ),
                    );
                  }

                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.04, 0.96, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                      itemCount: filteredWatchmen.length,
                      itemBuilder: (context, index) {
                        return _buildWatchmanCard(filteredWatchmen[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    logger.d('BuildingSecurityPage: build method finished rendering');
    return scaffold;
  }
}
