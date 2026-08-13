import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/providers/admin_provider.dart';
import 'package:my_soc/utils/app_logger.dart';

// UI: Admin Payments View displaying aggregated transactions per building
class AdminPaymentsView extends ConsumerStatefulWidget {
  const AdminPaymentsView({super.key});

  @override
  ConsumerState<AdminPaymentsView> createState() => _AdminPaymentsViewState();
}

class _AdminPaymentsViewState extends ConsumerState<AdminPaymentsView> {
  String _searchQuery = '';

  // Backend: Helper to extract building name from the snapshot
  String _getBuildingName(
      String buildId, AsyncValue<QuerySnapshot> buildingsAsync) {
    if (buildingsAsync.value == null) return "Unknown Building";
    try {
      final doc = buildingsAsync.value!.docs.firstWhere((d) => d.id == buildId);
      final data = doc.data() as Map<String, dynamic>;
      return data['buildingName']?.toString() ?? "Unknown Building";
    } catch (_) {
      return "Unknown Building (For Debugging)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(groupedTransactionsProvider);
    final buildingsAsync = ref.watch(buildingsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by building name...',
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
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF222A54)),
                    SizedBox(height: 16),
                    Text(
                      "Aggregating transactions...",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          color: Color(0xFF222A54),
                          fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  "Error loading payments: $err",
                  style:
                      const TextStyle(fontFamily: "Poppins", color: Colors.red),
                ),
              ),
              data: (groupedData) {
                final buildIds = groupedData.keys.where((id) {
                  final name =
                      _getBuildingName(id, buildingsAsync).toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (buildIds.isEmpty) {
                  return const Center(
                    child: Text(
                      "No buildings found matching search.",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          color: Colors.grey,
                          fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buildIds.length,
                  itemBuilder: (context, index) {
                    final buildId = buildIds[index];
                    final data = groupedData[buildId]!;
                    final buildingName =
                        _getBuildingName(buildId, buildingsAsync);

                    return _buildPaymentCard(
                        context, buildId, buildingName, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // UI: Premium card for each building's aggregated payment data
  Widget _buildPaymentCard(BuildContext context, String buildId,
      String buildingName, BuildingTransactionData data) {
    final double amountK = data.totalAmount / 1000;
    final String formattedAmount = "${amountK.toStringAsFixed(0)}K";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            logger.i(
                "Payment card clicked for building: $buildingName (ID: $buildId)");
            // Further implementation will be told later
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buildingName,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222A54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${data.count} transactions",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹ $formattedAmount",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green, // Earning/financial color
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Overall\nAmount",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
