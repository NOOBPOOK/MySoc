import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';
import 'package:my_soc/common/sec_maintain/createMaintain.dart';

// ---------------------------------------------------------
// UI Component: PreviousRecordsView
// ---------------------------------------------------------
class PreviousRecordsView extends StatefulWidget {
  const PreviousRecordsView({super.key});

  @override
  State<PreviousRecordsView> createState() => _PreviousRecordsViewState();
}

class _PreviousRecordsViewState extends State<PreviousRecordsView> {
  String _searchQuery = '';

  // Mock maintenance records to provide a premium and complete experience
  final List<Map<String, dynamic>> _mockRecords = [
    {
      'id': 'MNT-2026-08',
      'wing': 'A',
      'flat': '102',
      'owner': 'Rohan Sharma',
      'amount': 2500.0,
      'month': 'August 2026',
      'dueDate': DateTime(2026, 8, 15),
      'paidDate': DateTime(2026, 8, 10),
      'status': 'Paid',
    },
    {
      'id': 'MNT-2026-07',
      'wing': 'B',
      'flat': '304',
      'owner': 'Priya Patel',
      'amount': 2500.0,
      'month': 'August 2026',
      'dueDate': DateTime(2026, 8, 15),
      'paidDate': null,
      'status': 'Pending',
    },
    {
      'id': 'MNT-2026-06',
      'wing': 'C',
      'flat': '501',
      'owner': 'Vikram Malhotra',
      'amount': 2800.0,
      'month': 'August 2026',
      'dueDate': DateTime(2026, 8, 15),
      'paidDate': DateTime(2026, 8, 12),
      'status': 'Paid',
    },
    {
      'id': 'MNT-2026-05',
      'wing': 'A',
      'flat': '405',
      'owner': 'Sunita Deshmukh',
      'amount': 2500.0,
      'month': 'July 2026',
      'dueDate': DateTime(2026, 7, 15),
      'paidDate': null,
      'status': 'Overdue',
    },
    {
      'id': 'MNT-2026-04',
      'wing': 'B',
      'flat': '202',
      'owner': 'Amit Verma',
      'amount': 2500.0,
      'month': 'July 2026',
      'dueDate': DateTime(2026, 7, 15),
      'paidDate': DateTime(2026, 7, 14),
      'status': 'Paid',
    },
  ];

  // Backend: Handle search trigger
  void _onSearchChanged(String query) {
    logger.d('_onSearchChanged query: $query');
    setState(() {
      _searchQuery = query;
    });
  }

  // UI: Build record card
  Widget _buildRecordCard(Map<String, dynamic> record) {
    final isPaid = record['status'] == 'Paid';
    final isOverdue = record['status'] == 'Overdue';
    
    Color statusColor = Colors.green;
    if (isOverdue) {
      statusColor = Colors.redAccent;
    } else if (!isPaid) {
      statusColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left indicator status bar
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Flat Wing & Bill Period
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Flat ${record['wing']}-${record['flat']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222A54),
                              fontFamily: "Poppins",
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record['status'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record['owner'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // Details row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Billing Month",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record['month'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222A54),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Due Date",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.yMMMd().format(record['dueDate']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222A54),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Amount",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "₹${record['amount'].toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222A54),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isPaid && record['paidDate'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Paid on ${DateFormat.yMMMd().format(record['paidDate'])}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter records
    final filtered = _mockRecords.where((item) {
      final text = "${item['wing']}-${item['flat']} ${item['owner']} ${item['status']}".toLowerCase();
      return text.contains(_searchQuery.toLowerCase());
    }).toList();

    // Backend: Retrieve arguments passed from previous page
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the dashboard background clean
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF222A54),
        onPressed: () {
          logger.i('FloatingActionButton pressed - Navigating to CreateMaintain');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMaintain(),
              settings: RouteSettings(
                arguments: args,
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Wing-Flat, Owner, or Status',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
                ),
              ),
            ),
          ),
          // Records List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      "No records match your search criteria.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : FadedScrollMask(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildRecordCard(filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
