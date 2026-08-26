import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/common/sec_maintain/previous_records_view.dart';
import 'package:my_soc/common/sec_maintain/analytics_view.dart';

// ---------------------------------------------------------
// UI Component: MaintainDash
// ---------------------------------------------------------
class MaintainDash extends ConsumerStatefulWidget {
  const MaintainDash({super.key});

  @override
  ConsumerState<MaintainDash> createState() => _MaintainDashState();
}

class _MaintainDashState extends ConsumerState<MaintainDash> {
  int _currentIndex = 0;

  // Backend: Handle tab navigation
  void _changeTab(int index) {
    logger.i('_changeTab triggered from index $_currentIndex to $index');
    setState(() {
      _currentIndex = index;
    });
    logger.i('_changeTab completed successfully');
  }

  // UI: Build the main content based on selected tab
  Widget _buildBodyContent() {
    if (_currentIndex == 0) {
      return const PreviousRecordsView();
    } else {
      return const AnalyticsView();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Backend: Retrieve arguments passed through the routing context
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userId'] ?? 'N/A';
    final userEmail = args['userEmail'] ?? 'N/A';
    final designation = args['designation'] ?? 'N/A';
    final buildingId = args['buildingId'] ?? 'N/A';

    logger.d('MaintainDash build triggered: userId=$userId, userEmail=$userEmail, designation=$designation, buildingId=$buildingId');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62.0),
        child: AppBar(
          toolbarHeight: 62.0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: const Border(
            bottom: BorderSide(
              color: Color(0xFF222A54), // Dark border matching Watchman Header
              width: 2.0,
            ),
          ),
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF222A54)),
              onPressed: () {
                logger.i('Back navigation tapped on MaintainDash');
                Navigator.of(context).pop();
              },
            ),
          ),
          title: const Text(
            "Maintenance Dashboard",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Color(0xFF222A54),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                logger.i('Language change icon tapped in MaintainDash');
                CustomToast.show(context, type: 0, message: "Language options...");
              },
              icon: const Icon(Icons.language_rounded, color: Color(0xFF222A54)),
              tooltip: "Change Language",
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
              // Navigation Item 1: Previous Records
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeTab(0),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: _currentIndex == 0 ? const Color(0xFF222A54) : Colors.grey,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Previous Records",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 11,
                          fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.w400,
                          color: _currentIndex == 0 ? const Color(0xFF222A54) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Navigation Item 2: Analytics
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeTab(1),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: _currentIndex == 1 ? const Color(0xFF222A54) : Colors.grey,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Analytics",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 11,
                          fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                          color: _currentIndex == 1 ? const Color(0xFF222A54) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
    );
  }
}
