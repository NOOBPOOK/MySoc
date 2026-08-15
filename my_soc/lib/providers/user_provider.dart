import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/utils/app_logger.dart';

// Backend: Provides the currently logged-in user's Firestore document.
final currentUserProvider = FutureProvider<QueryDocumentSnapshot?>((ref) async {
  logger.i('currentUserProvider: Fetching current user details');
  try {
    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) {
      logger.i('currentUserProvider: No authenticated user found');
      return null;
    }

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userAuth.email)
        .get();

    if (userSnapshot.docs.isEmpty) {
      logger.i('currentUserProvider: User document not found in Firestore');
      return null;
    }

    logger.i('currentUserProvider: Successfully fetched current user details');
    return userSnapshot.docs.first;
  } catch (e) {
    logger.e('currentUserProvider: Error fetching current user - $e');
    rethrow;
  }
});

// Backend: Provides a live stream for a specific user's building. Uses autoDispose.
final userBuildingStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot, String>((ref, buildingId) {
  logger.i(
      'userBuildingStreamProvider: Fetching stream for building $buildingId');
  return FirebaseFirestore.instance
      .collection('buildings')
      .doc(buildingId)
      .snapshots();
});

// Backend: Provides all vehicles in a given building. Uses autoDispose.
final buildingVehiclesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, buildingId) async {
  logger.i(
      'buildingVehiclesProvider: Fetching vehicles for building $buildingId');
  try {
    final QuerySnapshot buildingUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: buildingId)
        .where('isVerified', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> vehicles = [];

    for (var doc in buildingUsers.docs) {
      final userData = doc.data() as Map<String, dynamic>;
      if (userData.containsKey('vehicles') && userData['vehicles'] is List) {
        final List<dynamic> userVehicles = userData['vehicles'];
        for (var vehicle in userVehicles) {
          if (vehicle is Map) {
            String fName = (userData['firstName'] ?? '').toString();
            String lName = (userData['lastName'] ?? '').toString();

            // Combine, collapse all multiple whitespaces into a single space, and trim.
            String rawName =
                '$fName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();

            // Capitalize the first letter of each individual word.
            List<String> nameParts = rawName.split(' ');
            List<String> capitalizedParts = nameParts.map((part) {
              if (part.isEmpty) return '';
              return part[0].toUpperCase() + part.substring(1).toLowerCase();
            }).toList();

            String finalOwnerName = capitalizedParts.join(' ');

            vehicles.add({
              ...vehicle as Map<String, dynamic>,
              'ownerName': finalOwnerName,
              'flatNumber': userData['flatNumber'] ?? 'N/A',
              'wing': userData['wing'] ?? 'N/A',
              'phone': userData['phone'] ?? 'N/A',
            });
          }
        }
      }
    }

    logger.i(
        'buildingVehiclesProvider: Successfully fetched ${vehicles.length} vehicles');
    return vehicles;
  } catch (e) {
    logger.e('buildingVehiclesProvider: Error fetching vehicles - $e');
    rethrow;
  }
});

// Backend: Provides a live stream of polls for a specific building.
final pollsStreamProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, buildingId) {
  logger.i('pollsStreamProvider: Opened poll stream for building $buildingId');
  return FirebaseFirestore.instance
      .collection('polls')
      .where('buildingId', isEqualTo: buildingId)
      .orderBy('createdAt', descending: true)
      .snapshots();
});

// Backend: Provides a live stream of all votes for a specific poll.
final pollVotesStreamProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, pollId) {
  logger.i('pollVotesStreamProvider: Opened votes stream for poll $pollId');
  return FirebaseFirestore.instance
      .collection('polls')
      .doc(pollId)
      .collection('votes')
      .snapshots();
});

class ComplaintsFilter {
  final String buildId;
  final bool? isPrivate;
  final String? userId;

  ComplaintsFilter({
    required this.buildId,
    this.isPrivate,
    this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplaintsFilter &&
        other.buildId == buildId &&
        other.isPrivate == isPrivate &&
        other.userId == userId;
  }

  @override
  int get hashCode =>
      buildId.hashCode ^ (isPrivate?.hashCode ?? 0) ^ (userId?.hashCode ?? 0);
}

// Backend: Provides a live stream of complaints for a specific building with filters.
final complaintsStreamProvider =
    StreamProvider.family<QuerySnapshot, ComplaintsFilter>((ref, filter) {
  logger.i(
      'complaintsStreamProvider: Opened stream for building ${filter.buildId}, isPrivate: ${filter.isPrivate}, userId: ${filter.userId}');

  Query query = FirebaseFirestore.instance
      .collection('complaints')
      .where('buildId', isEqualTo: filter.buildId);

  if (filter.isPrivate != null) {
    query = query.where('isPrivate', isEqualTo: filter.isPrivate);
  }

  if (filter.userId != null && filter.userId!.isNotEmpty) {
    query = query.where('createdBy', isEqualTo: filter.userId);
  }

  return query.orderBy('createdAt', descending: true).snapshots();
});

// Backend: Provides a live stream for a specific complaint document using its ID.
final complaintStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot, String>((ref, complaintId) {
  logger.i('complaintStreamProvider: Opened stream for complaint $complaintId');
  return FirebaseFirestore.instance
      .collection('complaints')
      .doc(complaintId)
      .snapshots();
});

// Backend: Provides a live stream of announcements for a specific building.
final announcementsStreamProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, buildingId) {
  logger.i(
      'announcementsStreamProvider: Opened announcements stream for building $buildingId');
  return FirebaseFirestore.instance
      .collection('buildings')
      .doc(buildingId)
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots();
});
