import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package_helpers.dart';

class VisitorCard extends StatelessWidget {
  final Map<String, dynamic> visitorLog;

  const VisitorCard({
    super.key,
    required this.visitorLog,
  });

  @override
  Widget build(BuildContext context) {
    logger.d('VisitorCard: build started for visitor log ID: ${visitorLog['id']}');

    final name = visitorLog['name'] ?? 'Visitor';
    final from = visitorLog['from'] ?? '';
    final reason = visitorLog['reason'] ?? 'No reason stated';
    final count = visitorLog['count']?.toString() ?? '1';
    final timestampVal = visitorLog['timestamp'];

    final timeStr = formatHumanFriendlyDate(timestampVal as Timestamp?);

    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF222A54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222A54).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF222A54).withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          "Count: $count",
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222A54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (from.isNotEmpty) ...[
                    Text(
                      "From: $from",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    "Purpose: $reason",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Visited: $timeStr",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    logger.d('VisitorCard: build completed');
    return cardWidget;
  }
}
