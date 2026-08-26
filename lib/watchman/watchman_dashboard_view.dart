import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';
import 'package:my_soc/watchman/visitor_dialog.dart';
import 'package:my_soc/watchman/courrier_dialog.dart';
import 'package:my_soc/watchman/watchman_logs_view.dart'; // For WatchmanLogTile

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  // UI: Build a card to display visit counts
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

  // UI: Build a card to trigger quick dialog actions
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
