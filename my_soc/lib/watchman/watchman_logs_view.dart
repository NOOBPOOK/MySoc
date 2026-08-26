import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';

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
