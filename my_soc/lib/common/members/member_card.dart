import 'package:flutter/material.dart';
import 'package:my_soc/common/members/kysociety.dart';
import 'package:my_soc/utils/app_logger.dart';

class MemberCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onLongPress;

  const MemberCard({
    super.key,
    required this.contact,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    logger.d('MemberCard: build started for user: ${contact['id']}');
    String fName = (contact['firstName'] ?? '').toString();
    String lName = (contact['lastName'] ?? '').toString();
    String rawName = '$fName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();
    String finalName = rawName.split(' ').map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join(' ');

    String contactEmail = contact['email'] ?? 'No Email';
    String wing = contact['wing'] ?? 'N/A';
    String flat = contact['flatNumber'] ?? 'N/A';
    int desig = contact['designation'] ?? 0;
    String contactRank = designationMap[desig] ?? '';

    final card = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF222A54).withValues(alpha: 0.1),
              child: Text(
                finalName.isNotEmpty ? finalName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontFamily: "Poppins",
                  color: Color(0xFF222A54),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          finalName.isNotEmpty ? finalName : 'Unknown',
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF222A54),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222A54),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          contactRank,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contactEmail,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.home_outlined,
                          size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "$wing - $flat",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    logger.d('MemberCard: build completed successfully');
    return card;
  }
}
