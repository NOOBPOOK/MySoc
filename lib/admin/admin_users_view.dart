import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/widgets/faded_scroll_mask.dart';
import 'package:my_soc/providers/admin_provider.dart';

// ---------------------------------------------------------
// UI Component: AdminUsersView
// ---------------------------------------------------------
class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final adminUsersData = ref.watch(allUsersProvider).value;
        final users = adminUsersData?.users ?? [];

        final filteredUsers = users.where((user) {
          final firstName = (user['firstName'] ?? '').toString().toLowerCase();
          final lastName = (user['lastName'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final search = _searchQuery.toLowerCase();

          return firstName.contains(search) ||
              lastName.contains(search) ||
              email.contains(search);
        }).toList();

        return Column(
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
                  hintText: 'Search for users or emails...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF222A54)),
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
              child: filteredUsers.isEmpty
                  ? const Center(child: Text("No users found matching search."))
                  : FadedScrollMask(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];

                          String capitalize(String s) {
                            if (s.isEmpty) return s;
                            return s[0].toUpperCase() +
                                s.substring(1).toLowerCase();
                          }

                          final rawFirstName =
                              (user['firstName'] as String?)?.trim() ??
                                  'Unknown';
                          final rawLastName =
                              (user['lastName'] as String?)?.trim() ?? '';

                          final firstName = capitalize(rawFirstName);
                          final lastName = capitalize(rawLastName);

                          final fullName = "$firstName $lastName"
                              .trim()
                              .replaceAll(RegExp(r'\s+'), ' ');

                          final email = user['email'] ?? 'No email';
                          final createdAtTimestamp =
                              user['createdAt'] as Timestamp?;

                          String dateText = "Unknown date";
                          if (createdAtTimestamp != null) {
                            final date = createdAtTimestamp.toDate();
                            final months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ];
                            dateText =
                                "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(
                                  vertical: -4, horizontal: 0),
                              minVerticalPadding: 0,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF222A54).withOpacity(0.1),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: Color(0xFF222A54),
                                ),
                              ),
                              title: Padding(
                                padding: const EdgeInsets.only(bottom: 3.0),
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF222A54),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                email,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  height: 1.2,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Joined",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222A54),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
