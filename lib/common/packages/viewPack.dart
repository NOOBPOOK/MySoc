import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package_helpers.dart';
import 'package_card.dart';
import 'visitor_card.dart';

class ViewPackagesPage extends ConsumerStatefulWidget {
  const ViewPackagesPage({super.key});

  @override
  ConsumerState<ViewPackagesPage> createState() => _ViewPackagesPageState();
}

class _ViewPackagesPageState extends ConsumerState<ViewPackagesPage> {
  late String userId;
  late String buildingId;
  String? wing;
  String? flat;
  bool _initialized = false;
  bool _loadingUser = true;

  int _currentIndex = 0;
  String _packageSearchQuery = '';
  String _visitorSearchQuery = '';
  String _packageFilter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.d(
          '_ViewPackagesPageState: didChangeDependencies started initialization');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        buildingId = args['buildingId'] ?? '';
        wing = args['wing'] ?? '';
        flat = args['flatNumber'] ?? '';
        _loadingUser = false;
        logger.i(
            '_ViewPackagesPageState: didChangeDependencies completed directly with wing: $wing, flat: $flat');
      } else {
        userId = '';
        buildingId = '';
        _loadingUser = false;
        logger.w('_ViewPackagesPageState: No route arguments found');
      }
      _initialized = true;
    }
  }

  // Backend: Handles package filter changes
  void _onPackageFilterChanged(String value) {
    logger.i('_ViewPackagesPageState: _onPackageFilterChanged started with value: $value');
    setState(() {
      _packageFilter = value;
    });
    logger.i('_ViewPackagesPageState: _onPackageFilterChanged completed with package filter set to: $_packageFilter');
  }

  // Backend: Marks a package as accepted/collected
  Future<void> _acceptPackage(String packageId) async {
    logger.i(
        '_ViewPackagesPageState: _acceptPackage started for packageId: $packageId');
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('courriers')
          .doc(packageId)
          .update({
        'status': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      logger.i(
          '_ViewPackagesPageState: _acceptPackage completed successfully for packageId: $packageId');
      if (mounted) {
        CustomToast.show(context,
            type: 1, message: 'Package accepted successfully!');
      }
    } catch (e) {
      logger.e('_ViewPackagesPageState: Error accepting package - $e');
      if (mounted) {
        CustomToast.show(context,
            type: -1, message: 'Failed to accept package: $e');
      }
    }
  }

  // Backend: Stream of packages for this user's flat/wing
  Stream<QuerySnapshot> _fetchPackagesStream() {
    logger.d(
        '_ViewPackagesPageState: _fetchPackagesStream called for buildingId: $buildingId, wing: $wing, flat: $flat');
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingId)
        .collection('courriers')
        .where('wing', isEqualTo: wing)
        .where('flat', isEqualTo: flat)
        .orderBy('recievedAt', descending: true)
        .snapshots();
  }

  // Backend: Stream of visitors for this user's flat/wing
  Stream<QuerySnapshot> _fetchVisitorsStream() {
    logger.d(
        '_ViewPackagesPageState: _fetchVisitorsStream called for buildingId: $buildingId, wing: $wing, flat: $flat');
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingId)
        .collection('logs')
        .where('wing', isEqualTo: wing)
        .where('flat', isEqualTo: flat)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('_ViewPackagesPageState: _buildAppBar called');
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
      title: Text(
        _currentIndex == 0 ? "Your Packages" : "Your Visitors",
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
    logger.d('_ViewPackagesPageState: _buildAppBar completed');
    return appBar;
  }

  // UI: Search Section
  Widget _buildSearchSection() {
    logger.d('_ViewPackagesPageState: _buildSearchSection called');
    final isPackages = _currentIndex == 0;
    
    final searchTextField = TextField(
      onChanged: (value) {
        setState(() {
          if (isPackages) {
            _packageSearchQuery = value.trim().toLowerCase();
          } else {
            _visitorSearchQuery = value.trim().toLowerCase();
          }
        });
        logger.d(
            '_ViewPackagesPageState: search query changed for index $_currentIndex to: $value');
      },
      decoration: InputDecoration(
        hintText: isPackages
            ? 'Search by delivery company or details...'
            : 'Search by visitor name or purpose...',
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

    if (!isPackages) {
      logger.d('_ViewPackagesPageState: _buildSearchSection completed (visitor mode)');
      return searchTextField;
    }

    final row = Row(
      children: [
        Expanded(child: searchTextField),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF222A54),
            borderRadius: BorderRadius.circular(56),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF222A54).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _packageFilter,
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            tooltip: "Filter Packages",
            onSelected: _onPackageFilterChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'All',
                child: Text('All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _packageFilter == 'All' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _packageFilter == 'All' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'Collected',
                child: Text('Collected',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _packageFilter == 'Collected' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _packageFilter == 'Collected' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'Not Collected',
                child: Text('Not Collected',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _packageFilter == 'Not Collected' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _packageFilter == 'Not Collected' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ],
          ),
        ),
      ],
    );

    logger.d('_ViewPackagesPageState: _buildSearchSection completed (packages mode)');
    return row;
  }





  // UI: Build the packages list stream builder
  Widget _buildPackagesList() {
    logger.d('_ViewPackagesPageState: _buildPackagesList called');
    final widget = StreamBuilder<QuerySnapshot>(
      stream: _fetchPackagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF222A54)),
          );
        }
        if (snapshot.hasError) {
          logger.e(
              '_ViewPackagesPageState: Packages Stream error - ${snapshot.error}');
          return const Center(
            child: Text(
              'Error loading packages',
              style: TextStyle(fontFamily: "Poppins", color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No packages recorded for your flat',
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          );
        }

        final packages = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Sort by recievedAt descending order in memory
        packages.sort((a, b) {
          final aTime = a['recievedAt'] as Timestamp?;
          final bTime = b['recievedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        // Filter by search query and collection status
        final filteredPackages = packages.where((pkg) {
          final deliveryName =
              (pkg['deliveryName'] ?? '').toString().toLowerCase();
          final description =
              (pkg['description'] ?? '').toString().toLowerCase();
          final matchesSearch = deliveryName.contains(_packageSearchQuery) ||
              description.contains(_packageSearchQuery);

          if (!matchesSearch) return false;

          final isCollected = pkg['status'] == true;
          if (_packageFilter == 'Collected') {
            return isCollected;
          } else if (_packageFilter == 'Not Collected') {
            return !isCollected;
          }
          return true; // For 'All'
        }).toList();

        if (filteredPackages.isEmpty) {
          return const Center(
            child: Text(
              'No matching packages found',
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.grey,
                fontSize: 15,
              ),
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
              stops: [0.0, 0.03, 0.97, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            itemCount: filteredPackages.length,
            itemBuilder: (context, index) {
              final pkg = filteredPackages[index];
              return PackageCard(
                package: pkg,
                onAccept: () => _acceptPackage(pkg['id']),
              );
            },
          ),
        );
      },
    );
    logger.d('_ViewPackagesPageState: _buildPackagesList completed');
    return widget;
  }

  // UI: Build the visitors list stream builder
  Widget _buildVisitorsList() {
    logger.d('_ViewPackagesPageState: _buildVisitorsList called');
    final widget = StreamBuilder<QuerySnapshot>(
      stream: _fetchVisitorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF222A54)),
          );
        }
        if (snapshot.hasError) {
          logger.e(
              '_ViewPackagesPageState: Visitors Stream error - ${snapshot.error}');
          return const Center(
            child: Text(
              'Error loading visitors',
              style: TextStyle(fontFamily: "Poppins", color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No visitors recorded for your flat',
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          );
        }

        final logs = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        // Sort by timestamp descending order in memory
        logs.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return -1;
          if (bTime == null) return 1;
          return bTime.compareTo(aTime);
        });

        // Filter by search query
        final filteredLogs = logs.where((log) {
          final name = (log['name'] ?? '').toString().toLowerCase();
          final from = (log['from'] ?? '').toString().toLowerCase();
          final reason = (log['reason'] ?? '').toString().toLowerCase();
          return name.contains(_visitorSearchQuery) ||
              from.contains(_visitorSearchQuery) ||
              reason.contains(_visitorSearchQuery);
        }).toList();

        if (filteredLogs.isEmpty) {
          return const Center(
            child: Text(
              'No matching visitors found',
              style: TextStyle(
                fontFamily: "Poppins",
                color: Colors.grey,
                fontSize: 15,
              ),
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
              stops: [0.0, 0.03, 0.97, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              return VisitorCard(visitorLog: filteredLogs[index]);
            },
          ),
        );
      },
    );
    logger.d('_ViewPackagesPageState: _buildVisitorsList completed');
    return widget;
  }

  // UI: Build individual nav item for bottom navigation bar
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          logger.i(
              '_ViewPackagesPageState: Bottom navigation index changed to: $_currentIndex');
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
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
    logger.d('_ViewPackagesPageState: build method started');

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loadingUser
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF222A54)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _currentIndex == 0
                        ? _buildPackagesList()
                        : _buildVisitorsList(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: "Packages",
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: "Visitors",
              ),
            ],
          ),
        ),
      ),
    );

    logger.d('_ViewPackagesPageState: build method completed');
    return scaffold;
  }
}
