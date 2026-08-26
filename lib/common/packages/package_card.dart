import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package_helpers.dart';

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback onAccept;

  const PackageCard({
    super.key,
    required this.package,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    logger.d('PackageCard: build started for package ID: ${package['id']}');

    final deliveryName = package['deliveryName'] ?? 'Courier/Package';
    final description = package['description'] ?? 'No description';
    final isCollected = package['status'] == true;
    final guardName = package['recievedName'] ?? 'Society Security';
    final receivedAtVal = package['recievedAt'];

    final timeStr = formatHumanFriendlyDate(receivedAtVal as Timestamp?);

    final acceptedAtVal = package['acceptedAt'];
    String acceptedAtStr = 'N/A';
    if (acceptedAtVal is Timestamp) {
      acceptedAtStr = formatHumanFriendlyDate(acceptedAtVal);
    }

    // Determine Theme Color based on Vendor Name
    Color accentColor = const Color(0xFF222A54);
    IconData packageIcon = Icons.inventory_2_outlined;

    final lowerName = deliveryName.toLowerCase();
    if (lowerName.contains('amazon')) {
      accentColor = const Color(0xFFFF9900);
      packageIcon = Icons.local_shipping;
    } else if (lowerName.contains('flipkart')) {
      accentColor = const Color(0xFF2874F0);
      packageIcon = Icons.local_shipping;
    } else if (lowerName.contains('fedex') ||
        lowerName.contains('dhl') ||
        lowerName.contains('courier')) {
      accentColor = const Color(0xFF6A5ACD);
      packageIcon = Icons.local_post_office_outlined;
    }

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
                          deliveryName,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isCollected)
                        ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF222A54),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Accept",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                "Collected",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Received: $timeStr",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Handed over to: $guardName",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCollected) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Accepted at: $acceptedAtStr",
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    logger.d('PackageCard: build completed');
    return cardWidget;
  }
}
