import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';
import 'package:my_soc/providers/admin_provider.dart';
import 'package:my_soc/admin/building_details.dart';

// ---------------------------------------------------------
// UI Component: AdminBuildingsView
// ---------------------------------------------------------
class AdminBuildingsView extends StatefulWidget {
  const AdminBuildingsView({super.key});

  @override
  State<AdminBuildingsView> createState() => _AdminBuildingsViewState();
}

class _AdminBuildingsViewState extends State<AdminBuildingsView> {
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminUsersData = ref.watch(allUsersProvider).value;
        final buildingsAsyncValue = ref.watch(buildingsStreamProvider);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for buildings...',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF222A54)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF222A54), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 8,
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child:
                              Icon(Icons.filter_list, color: Color(0xFF222A54)),
                        ),
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222A54),
                          fontSize: 14,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _filterStatus = newValue;
                            });
                          }
                        },
                        items: <String>[
                          'All',
                          'Verified',
                          'Pending',
                          'Rejected'
                        ].map<DropdownMenuItem<String>>((String value) {
                          Color dotColor;
                          switch (value) {
                            case 'Verified':
                              dotColor = Colors.green;
                              break;
                            case 'Pending':
                              dotColor = Colors.orange;
                              break;
                            case 'Rejected':
                              dotColor = Colors.red;
                              break;
                            default:
                              dotColor = const Color(0xFF222A54);
                          }
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dotColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: dotColor.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: buildingsAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text("Error: $error")),
                data: (snapshot) {
                  final buildings = snapshot.docs;
                  final filteredBuildings = buildings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Text Search Filter
                    final name =
                        (data['buildingName'] ?? '').toString().toLowerCase();
                    final street =
                        (data['streetName'] ?? '').toString().toLowerCase();
                    final matchesSearch =
                        name.contains(_searchQuery.toLowerCase()) ||
                            street.contains(_searchQuery.toLowerCase());

                    if (!matchesSearch) return false;

                    // Status Filter
                    final bool isVerified = data['isVerified'] ?? false;
                    final bool isRejected = data['isRejected'] ?? false;

                    if (_filterStatus == 'Verified') {
                      return isVerified == true;
                    } else if (_filterStatus == 'Pending') {
                      return isVerified == false && isRejected == false;
                    } else if (_filterStatus == 'Rejected') {
                      return isRejected == true;
                    }

                    // Default is 'All'
                    return true;
                  }).toList();

                  if (filteredBuildings.isEmpty) {
                    return const Center(
                        child: Text("No buildings found matching search."));
                  }

                  return FadedScrollMask(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: filteredBuildings.length,
                      itemBuilder: (context, index) {
                        final data = filteredBuildings[index].data()
                            as Map<String, dynamic>;
                        final String buildingId = filteredBuildings[index].id;
                        final int userCount =
                            adminUsersData?.buildingUserCounts[buildingId] ?? 0;

                        final bool isVerified = data['isVerified'] ?? false;
                        final bool isRejected = data['isRejected'] ?? false;

                        String statusText;
                        Color statusColor;

                        if (isVerified) {
                          statusText = "Verified";
                          statusColor = Colors.green;
                        } else if (isRejected) {
                          statusText = "Rejected";
                          statusColor = Colors.red;
                        } else {
                          statusText = "Pending";
                          statusColor = Colors.orange;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuildingDetailsPage(
                                    buildingId: buildingId,
                                  ),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0.3),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.domain_rounded,
                                size: 20,
                                color: statusColor,
                              ),
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 9,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  Text(
                                    data['buildingName'] ?? 'Unnamed Building',
                                    style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF222A54),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['streetName'] ?? 'No address',
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  data['city'] ?? 'No city',
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$userCount",
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF222A54),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Users",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
