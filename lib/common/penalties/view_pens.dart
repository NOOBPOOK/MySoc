import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';

class ViewPenaltiesPage extends ConsumerStatefulWidget {
  const ViewPenaltiesPage({super.key});

  @override
  ConsumerState<ViewPenaltiesPage> createState() => _ViewPenaltiesPageState();
}

class _ViewPenaltiesPageState extends ConsumerState<ViewPenaltiesPage> {
  late String userId;
  late String userName;
  late String buildingId;
  int designation = 0;
  bool _initialized = false;

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Paid', 'Unpaid'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.d(
          '_ViewPenaltiesPageState: didChangeDependencies started initialization');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        userName = args['userName'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
      } else {
        userId = '';
        userName = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          '_ViewPenaltiesPageState: didChangeDependencies completed initialization with buildingId: $buildingId, userId: $userId, userName: $userName, designation: $designation');
    }
  }


  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('_ViewPenaltiesPageState: _buildAppBar called');
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
        "Your Penalties",
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
    logger.d('_ViewPenaltiesPageState: _buildAppBar completed');
    return appBar;
  }

  // UI: Build the search section (search bar + status filter dropdown)
  Widget _buildSearchSection() {
    logger.d('_ViewPenaltiesPageState: _buildSearchSection called');
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
              logger.d('_ViewPenaltiesPageState: search query changed to: $_searchQuery');
            },
            decoration: InputDecoration(
              hintText: 'Search by reason...',
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
          ),
        ),
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
            initialValue: _statusFilter,
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            tooltip: "Filter by status",
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
              logger.i('_ViewPenaltiesPageState: status filter changed to: $_statusFilter');
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'All',
                child: Text('All Penalties', style: TextStyle(fontFamily: "Poppins")),
              ),
              const PopupMenuItem<String>(
                value: 'Paid',
                child: Text('Paid', style: TextStyle(fontFamily: "Poppins")),
              ),
              const PopupMenuItem<String>(
                value: 'Unpaid',
                child: Text('Unpaid', style: TextStyle(fontFamily: "Poppins")),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UI: Helper to build end-to-end card action buttons
  Widget _buildEndToEndButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.grey.shade300,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI: Build Individual Penalty Card
  Widget _buildPenaltyCard(Map<String, dynamic> penalty) {
    final reason = penalty['reason'] ?? 'No reason';
    final amount = penalty['amount']?.toString() ?? '0';
    final isPaid = penalty['status'] == true;
    final description = penalty['description'] ?? '';
    
    final dueDateVal = penalty['dueDate'];
    String dueDateStr = 'No due date';
    double additionalCharge = 0;
    int daysPast = 0;
    bool isOverdue = false;

    if (dueDateVal is Timestamp) {
      final dt = dueDateVal.toDate();
      dueDateStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      
      if (!isPaid) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(dt.year, dt.month, dt.day);
        final difference = today.difference(due).inDays;
        if (difference > 0) {
          isOverdue = true;
          daysPast = difference;
          additionalCharge = 5.0 * daysPast;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3ED), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: (isPaid ? Colors.green : Colors.red).withValues(alpha: 0.1),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.gavel,
                color: isPaid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reason,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF222A54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "Due Date: $dueDateStr",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Overdue: $daysPast days (+₹${additionalCharge.toStringAsFixed(0)} fine)",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹$amount",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPaid ? "Paid" : "Unpaid",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: Color(0xFFEEEEEE)),
      Row(
        children: [
          _buildEndToEndButton(
            text: "View Details",
            onPressed: () {
              logger.i("Clicked View Details for penalty: ${penalty['id']}");
              Navigator.pushNamed(
                context,
                '/penaltyDetails',
                arguments: {
                  'penalty': penalty,
                },
              );
            },
          ),
          const SizedBox(
            height: 40,
            child: VerticalDivider(width: 1, color: Colors.white24, thickness: 1),
          ),
          if (isPaid)
            _buildEndToEndButton(
              text: "Payment Details",
              onPressed: () {
                logger.i("Clicked Payment Details for penalty: ${penalty['id']}");
              },
            )
          else
            _buildEndToEndButton(
              text: "Pay Now",
              onPressed: () {
                logger.i("Clicked Pay Now for penalty: ${penalty['id']}");
              },
            ),
        ],
      ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.d('_ViewPenaltiesPageState: build method started');
    
    final penaltiesAsync = ref.watch(userPenaltiesStreamProvider('${buildingId}_$userId'));

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchSection(),
            const SizedBox(height: 16),
            Expanded(
              child: penaltiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF222A54)),
                ),
                error: (err, stack) {
                  logger.e('_ViewPenaltiesPageState: Stream error - $err');
                  return const Center(
                    child: Text(
                      'Error loading penalties',
                      style: TextStyle(fontFamily: "Poppins", color: Colors.red),
                    ),
                  );
                },
                data: (snapshot) {
                  if (snapshot.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No penalties issued to you',
                        style: TextStyle(fontFamily: "Poppins", color: Colors.grey, fontSize: 15),
                      ),
                    );
                  }

                  final penalties = snapshot.docs.map((doc) {
                    return {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    };
                  }).toList();

                  // Sort by createdAt descending order to guarantee sorting (handling null local timestamp docs by putting them first)
                  penalties.sort((a, b) {
                    final aTime = a['createdAt'] as Timestamp?;
                    final bTime = b['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return -1;
                    if (bTime == null) return 1;
                    return bTime.compareTo(aTime);
                  });

                  // Filter by Search Query & Status Dropdown Filter
                  final filteredPenalties = penalties.where((penalty) {
                    final reason = (penalty['reason'] ?? '').toString().toLowerCase();
                    final isPaid = penalty['status'] == true;

                    // 1. Filter by status
                    if (_statusFilter == 'Paid' && !isPaid) return false;
                    if (_statusFilter == 'Unpaid' && isPaid) return false;

                    // 2. Filter by search query (residents only search by reason)
                    if (_searchQuery.isNotEmpty) {
                      return reason.contains(_searchQuery);
                    }

                    return true;
                  }).toList();

                  if (filteredPenalties.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching penalties found',
                        style: TextStyle(fontFamily: "Poppins", color: Colors.grey, fontSize: 15),
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
                      padding: const EdgeInsets.only(bottom: 24, top: 8),
                      itemCount: filteredPenalties.length,
                      itemBuilder: (context, index) {
                        return _buildPenaltyCard(filteredPenalties[index]);
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
    
    logger.d('_ViewPenaltiesPageState: build method completed');
    return scaffold;
  }
}
