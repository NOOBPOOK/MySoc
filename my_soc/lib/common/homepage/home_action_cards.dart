import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: HomeActionCards
// ---------------------------------------------------------
class HomeActionCards extends StatelessWidget {
  final QueryDocumentSnapshot userDetails;
  final DocumentSnapshot buildingDetails;
  final String userName;

  const HomeActionCards({
    super.key,
    required this.userDetails,
    required this.buildingDetails,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    const cardHeight = 140.0;
    const innerCardHeight = (cardHeight - 10.0) / 2.0; // 55.0 pixels each
    const dividerColor = Color(0x1F000000); // 12% opacity black divider line

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Container(
        height: cardHeight,
        clipBehavior: Clip.antiAlias, // Clip children to parent rounded corners
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5), // Light gray base shade
          borderRadius: BorderRadius.circular(24), // Highly rounded corners
          border: Border.all(color: dividerColor, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000), // Clean shadow
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cells vertically edge-to-edge
          children: [
            // Left Half: Announcements (Purple/Violet Gradient, flush to left edges)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDA22FF), Color(0xFF9733EE)], // Violet purple gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () {
                      logger.i('Announcements tapped from left Action Card');
                      Navigator.pushNamed(context, '/announcements', arguments: {
                        'userId': userDetails.id,
                        'userName': userName,
                        'buildingId': buildingDetails.id,
                        'designation': userDetails['designation'],
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Announcements",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Society notice board",
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 10,
                                  color: Color(0xB3FFFFFF), // 70% opacity white text
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Vertical Divider between Left and Right halves
            Container(
              width: 1.0,
              color: dividerColor,
            ),
            // Right Half: Stacked Community Polls and Complaints (separated by single divider line)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Right Top: Community Polls (Blue Gradient)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Electric Blue Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            logger.i('Community Polls tapped from Action Cards');
                            Navigator.pushNamed(context, '/userPolls', arguments: {
                              'userId': userDetails.id,
                              'firstName': userDetails['firstName'],
                              'lastName': userDetails['lastName'],
                              'buildingId': buildingDetails.id,
                              'designation': userDetails['designation'],
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.how_to_vote_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Community Polls",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Shared Horizontal Divider Line
                  Container(
                    height: 1.0,
                    color: dividerColor,
                  ),
                  // Right Bottom: Complaints (Rose Red Gradient)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Rose Red Gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            logger.i('Complaints tapped from Action Cards');
                            Navigator.pushNamed(context, '/userComplaints', arguments: {
                              'userId': userDetails.id,
                              'ownerName': userName,
                              'buildingId': buildingDetails.id,
                              'flatNumber': '${userDetails['wing']} - ${userDetails['flatNumber']}',
                              'designation': userDetails['designation'],
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.report_problem_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Complaints",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
