import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';
class ManageUsersPage extends ConsumerStatefulWidget {
  const ManageUsersPage({super.key});

  @override
  ConsumerState<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends ConsumerState<ManageUsersPage> {
  late String userId;
  late String buildingId;
  late String userName;
  int designation = 0;

  bool _initialized = false;

  String _searchQuery = '';
  String _filterStatus = 'All';

  // Backend: Handle search query change
  void _onSearchQueryChanged(String value) {
    logger.d('ManageUsersPage: _onSearchQueryChanged: "$value"');
    setState(() {
      _searchQuery = value;
    });
  }

  // Backend: Handle filter status change
  void _onFilterStatusChanged(String value) {
    logger
        .i('ManageUsersPage: _onFilterStatusChanged: filter changed to $value');
    setState(() {
      _filterStatus = value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
        userName = args['userName'] ?? '';
      } else {
        userId = '';
        buildingId = '';
        userName = '';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          'ManageUsersPage: Initialized with userId: $userId, buildingId: $buildingId, userName: $userName, designation: $designation');
    }
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 62.0,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF222A54), width: 2.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        "Manage Users",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 25,
          color: Color(0xFF222A54),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // UI: Build the search section (search bar + filter dropdown)
  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _onSearchQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
              filled: true,
              fillColor: Colors.grey.shade100,
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
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF222A54),
            borderRadius: BorderRadius.circular(56),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF222A54).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _filterStatus,
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            tooltip: "Filter Users",
            onSelected: _onFilterStatusChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'All',
                child: Text('All',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _filterStatus == 'All'
                          ? const Color(0xFF222A54)
                          : Colors.black87,
                      fontWeight: _filterStatus == 'All'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'Verified',
                child: Text('Verified',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _filterStatus == 'Verified'
                          ? const Color(0xFF222A54)
                          : Colors.black87,
                      fontWeight: _filterStatus == 'Verified'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'Pending',
                child: Text('Pending',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _filterStatus == 'Pending'
                          ? const Color(0xFF222A54)
                          : Colors.black87,
                      fontWeight: _filterStatus == 'Pending'
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UI: Build the user card
  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isVerified = user['isVerified'] ?? false;

    return Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/userDetails',
              arguments: {
                'userId': user['id'],
                'loggedInUserId': userId,
                'loggedInUserName': userName,
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        user['fullName'],
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF222A54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isVerified
                              ? const Color(0xFF81C784).withOpacity(0.5)
                              : const Color(0xFFFFB74D).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isVerified ? "Verified" : "Pending",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isVerified
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFEF6C00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: Color(0xFF222A54)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user['email'],
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: Color(0xFF222A54)),
                    const SizedBox(width: 8),
                    Text(
                      user['phone'],
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.home_outlined,
                        size: 14, color: Color(0xFF222A54)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222A54).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${user['wing']} - ${user['flatNumber']}",
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222A54),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = ref.watch(buildingUsersStreamProvider(buildingId));

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchSection(),
            const SizedBox(height: 16),
            Expanded(
              child: buildingId.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF222A54)))
                  : usersStream.when(
                      data: (snapshot) {
                        // 1. Convert to List of Maps and format names
                        final allUsers = snapshot.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final fName =
                              data['firstName']?.toString().trim() ?? '';
                          final lName =
                              data['lastName']?.toString().trim() ?? '';

                          // Capitalize name parts
                          final rawName = '$fName $lName'
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim();
                          final nameParts = rawName.split(' ');
                          final capitalizedName = nameParts
                              .map((part) {
                                if (part.isEmpty) return '';
                                return part[0].toUpperCase() +
                                    part.substring(1).toLowerCase();
                              })
                              .join(' ')
                              .trim();

                          return {
                            'id': doc.id,
                            'fullName': capitalizedName,
                            'email': data['email'] ?? '',
                            'phone': data['phone'] ?? '',
                            'wing': data['wing'] ?? '',
                            'flatNumber': data['flatNumber'] ?? '',
                            'isVerified': data['isVerified'] ?? false,
                          };
                        }).toList();

                        // 2. Filter in memory
                        final filteredUsers = allUsers.where((user) {
                          // Filter by status
                          if (_filterStatus == 'Verified' &&
                              !user['isVerified']) {
                            return false;
                          }
                          if (_filterStatus == 'Pending' &&
                              user['isVerified']) {
                            return false;
                          }

                          // Filter by search query
                          if (_searchQuery.isNotEmpty) {
                            final query = _searchQuery.toLowerCase();
                            final nameMatch = user['fullName']
                                .toString()
                                .toLowerCase()
                                .contains(query);
                            final emailMatch = user['email']
                                .toString()
                                .toLowerCase()
                                .contains(query);
                            final phoneMatch = user['phone']
                                .toString()
                                .toLowerCase()
                                .contains(query);
                            final wingMatch = user['wing']
                                .toString()
                                .toLowerCase()
                                .contains(query);
                            final flatMatch = user['flatNumber']
                                .toString()
                                .toLowerCase()
                                .contains(query);
                            final wingFlatCombined =
                                '${user['wing']}-${user['flatNumber']}'
                                    .toLowerCase()
                                    .contains(query);

                            return nameMatch ||
                                emailMatch ||
                                phoneMatch ||
                                wingMatch ||
                                flatMatch ||
                                wingFlatCombined;
                          }

                          return true;
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return const Center(
                            child: Text(
                              "No users found.",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        // 3. Render list inside ShaderMask
                        return ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.05, 0.95, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.only(bottom: 24.0, top: 14),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return _buildUserCard(user);
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF222A54)),
                      ),
                      error: (error, stack) {
                        logger.e('Error loading users: $error');
                        return const Center(
                          child: Text(
                            "Error loading users.",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
