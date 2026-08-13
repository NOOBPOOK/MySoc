import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/utils/app_logger.dart';

// Backend: Defines the consolidated data structure returned by the provider
typedef AdminUsersData = ({
  List<Map<String, dynamic>> users,
  Map<String, int> buildingUserCounts,
});

// Backend: Provides all users from Firestore mapped to a reduced footprint object and groups user counts by building.
final allUsersProvider = FutureProvider<AdminUsersData>((ref) async {
  logger.i('allUsersProvider: Starting to fetch all users');
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    final Map<String, int> buildingUserCounts = {};

    final users = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final buildingId = data['buildingId']?.toString() ?? '';

      // Compute the occurrences of each buildingId
      if (buildingId.isNotEmpty) {
        buildingUserCounts[buildingId] =
            (buildingUserCounts[buildingId] ?? 0) + 1;
      }

      return {
        'id': doc.id,
        'buildingId': buildingId,
        'createdAt': data['createdAt'],
        'email': data['email'],
        'firstName': data['firstName'],
        'lastName': data['lastName'],
      };
    }).toList();

    logger.i(
        'allUsersProvider: Successfully fetched ${users.length} users across ${buildingUserCounts.length} buildings');
    return (users: users, buildingUserCounts: buildingUserCounts);
  } catch (e) {
    logger.e('allUsersProvider: Error fetching users - $e');
    rethrow;
  }
});

// Backend: Provides a live stream of all buildings ordered by timestamp for the admin dashboard.
final buildingsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  logger.i('buildingsStreamProvider: Initializing buildings stream');
  return FirebaseFirestore.instance
      .collection('buildings')
      .orderBy('timestamp')
      .snapshots();
});

// Backend: Provides a live stream for a specific building. Uses autoDispose to close the stream when the details page is closed.
final buildingDetailsStreamProvider = StreamProvider.autoDispose.family<DocumentSnapshot, String>((ref, buildingId) {
  logger.i('buildingDetailsStreamProvider: Fetching stream for building $buildingId');
  return FirebaseFirestore.instance
      .collection('buildings')
      .doc(buildingId)
      .snapshots();
});

// Backend: Defines the aggregated transaction data for a single building
class BuildingTransactionData {
  final int count;
  final double totalAmount;

  BuildingTransactionData({required this.count, required this.totalAmount});
}

// Backend: Fetches all transactions one-time, and aggregates amount & count grouped by build_id
final groupedTransactionsProvider = FutureProvider<Map<String, BuildingTransactionData>>((ref) async {
  logger.i('groupedTransactionsProvider: Fetching all transactions');
  try {
    final snapshot = await FirebaseFirestore.instance.collection('transactions').get();
    
    final Map<String, BuildingTransactionData> groupedData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String? buildId = data['build_id']?.toString();
      
      if (buildId == null || buildId.isEmpty) continue;
      
      // Parse amount safely (could be double, int, or String in DB)
      double amount = 0.0;
      final rawAmount = data['amount'];
      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        amount = double.tryParse(rawAmount) ?? 0.0;
      }

      if (groupedData.containsKey(buildId)) {
        final existing = groupedData[buildId]!;
        groupedData[buildId] = BuildingTransactionData(
          count: existing.count + 1,
          totalAmount: existing.totalAmount + amount,
        );
      } else {
        groupedData[buildId] = BuildingTransactionData(
          count: 1,
          totalAmount: amount,
        );
      }
    }
    
    logger.i('groupedTransactionsProvider: Aggregated transactions for ${groupedData.length} buildings');
    return groupedData;
  } catch (e) {
    logger.e('groupedTransactionsProvider: Error fetching transactions - $e');
    rethrow;
  }
});
