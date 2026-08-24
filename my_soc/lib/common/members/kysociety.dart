import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/common/members/assign_roles.dart';

const Map<int, String> designationMap = {
  0: 'Resident',
  1: 'Committee Member',
  2: 'Treasurer',
  3: 'Chairman',
  4: 'Secretary',
};

// Backend: Provider to store title of members list page
final membersPageTitleProvider = StateProvider<String>((ref) => "Members");

// Backend: Provider to store designation filter of members list page
final membersPageDesignationProvider = StateProvider<int>((ref) => 0);

// Backend: Provider to store buildingId for members list page
final membersPageBuildingIdProvider = StateProvider<String>((ref) => "");

Color getDesignationColor(int designation) {
  switch (designation) {
    case 4:
      return const Color.fromARGB(255, 0, 255, 242); // Red for Secretary
    case 3:
      return const Color(0xFFFFB74D); // Orange for Chairman
    case 2:
      return const Color(0xFF81C784); // Green for Treasurer
    case 1:
      return const Color(0xFF64B5F6); // Blue for Committee Member
    case 0:
    default:
      return const Color.fromARGB(163, 255, 255, 255); // White for Resident
  }
}

class KySocietyPage extends ConsumerStatefulWidget {
  const KySocietyPage({super.key});

  @override
  ConsumerState<KySocietyPage> createState() => _KySocietyPageState();
}

class _KySocietyPageState extends ConsumerState<KySocietyPage> {
  late String userId;
  late String userName;
  late String email;
  late String buildingId;
  int designation = 0;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.d(
          '_KySocietyPageState: didChangeDependencies started initialization');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        userName = args['userName'] ?? '';
        email = args['email'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
      } else {
        userId = '';
        userName = '';
        email = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          '_KySocietyPageState: didChangeDependencies completed initialization with userId: $userId, buildingId: $buildingId, designation: $designation');
    }
  }

  // Backend: Process Society Data from Snapshot
  Map<String, dynamic> _processSocietyData(QuerySnapshot snapshot) {
    logger.d(
        '_KySocietyPageState: _processSocietyData started with ${snapshot.docs.length} documents');
    int displayDesignation = designation;
    List<Map<String, dynamic>> keyContacts = [];
    int committeeMembersCount = 0;
    int residentsCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (doc.id == userId) {
        displayDesignation = data['designation'] ?? designation;
      }
      int userDesignation = data['designation'] ?? 0;
      if (userDesignation >= 2) {
        keyContacts.add(data);
      } else if (userDesignation == 1) {
        committeeMembersCount++;
      } else if (userDesignation == 0) {
        residentsCount++;
      }
    }

    keyContacts.sort(
        (a, b) => (b['designation'] ?? 0).compareTo(a['designation'] ?? 0));

    final result = {
      'displayDesignation': displayDesignation,
      'keyContacts': keyContacts,
      'committeeMembersCount': committeeMembersCount,
      'residentsCount': residentsCount,
      'rank': designationMap[displayDesignation] ?? 'Resident',
    };
    logger.i(
        '_KySocietyPageState: _processSocietyData completed successfully. Key contacts: ${keyContacts.length}, Committee: $committeeMembersCount, Residents: $residentsCount');
    return result;
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('_KySocietyPageState: _buildAppBar called');
    final appBar = AppBar(
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
        "About Your Society",
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
    logger.d('_KySocietyPageState: _buildAppBar completed');
    return appBar;
  }

  // UI: About You Card
  Widget _buildAboutYouCard({
    required String initials,
    required String userName,
    required String email,
    required String rank,
    required int displayDesignation,
  }) {
    logger.d(
        '_KySocietyPageState: _buildAboutYouCard called with initials: $initials, userName: $userName, email: $email, rank: $rank, displayDesignation: $displayDesignation');
    final widget = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF222A54),
            const Color(0xFF222A54).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF222A54).withValues(alpha: 0.2),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? "You, $userName" : "Unknown User",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty ? email : "No Email",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 11,
                        height: 0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getDesignationColor(displayDesignation)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rank,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: getDesignationColor(displayDesignation),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    logger.d('_KySocietyPageState: _buildAboutYouCard completed');
    return widget;
  }

  // UI: Key Contacts Card
  Widget _buildKeyContactsCard(List<Map<String, dynamic>> keyContacts) {
    logger.d(
        '_KySocietyPageState: _buildKeyContactsCard called with keyContacts count: ${keyContacts.length}');
    final widget = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF222A54),
            const Color(0xFF222A54).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF222A54).withValues(alpha: 0.2),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Key Contacts",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const Divider(height: 16, thickness: 1, color: Colors.white30),
          ...keyContacts.asMap().entries.map((entry) {
            int index = entry.key;
            var contact = entry.value;
            String fName = (contact['firstName'] ?? '').toString();
            String lName = (contact['lastName'] ?? '').toString();
            String rawName =
                '$fName $lName'.replaceAll(RegExp(r'\s+'), ' ').trim();
            String finalName = rawName.split(' ').map((part) {
              if (part.isEmpty) return '';
              return part[0].toUpperCase() + part.substring(1).toLowerCase();
            }).join(' ');

            String contactEmail = contact['email'] ?? 'No Email';
            String wing = contact['wing'] ?? 'N/A';
            String flat = contact['flatNumber'] ?? 'N/A';
            int desig = contact['designation'] ?? 0;
            String contactRank = designationMap[desig] ?? '';

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: index < keyContacts.length - 1 ? 12.0 : 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    finalName.isNotEmpty
                                        ? finalName
                                        : 'Unknown',
                                    style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
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
                                    color: getDesignationColor(desig)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    contactRank,
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 0,
                                      color: getDesignationColor(desig),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    contactEmail,
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "$wing - $flat",
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
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
                if (index < keyContacts.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white12,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
    logger.d('_KySocietyPageState: _buildKeyContactsCard completed');
    return widget;
  }

  // UI: Assign Roles Button
  Widget _buildAssignRolesButton({required VoidCallback onTap}) {
    logger.d('_KySocietyPageState: _buildAssignRolesButton called');
    final button = Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.assignment_ind_outlined, color: Colors.white),
          label: const Text(
            "Assign Roles",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222A54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
    logger.d('_KySocietyPageState: _buildAssignRolesButton completed');
    return button;
  }

  // UI: Count Card (for Committee Members or Residents)
  Widget _buildCountCard({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onTap,
  }) {
    logger.d(
        '_KySocietyPageState: _buildCountCard called with title: $title, subtitle: $subtitle, count: $count');
    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222A54),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    height: 1,
                    color: Color(0xFF222A54),
                  ),
                ),
                Text(
                  "Count",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    logger.d('_KySocietyPageState: _buildCountCard completed');
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    logger.d('_KySocietyPageState: build method started');
    final verifiedUsersAsync =
        ref.watch(verifiedBuildingUsersStreamProvider(buildingId));

    String initials = "";
    if (userName.isNotEmpty) {
      List<String> names = userName.split(RegExp(r'\s+'));
      if (names.isNotEmpty) {
        initials += names[0][0];
        if (names.length > 1) {
          initials += names.last[0];
        }
      }
    }

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: verifiedUsersAsync.when(
        loading: () {
          logger.d('_KySocietyPageState: verifiedUsersAsync stream is loading');
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF222A54)),
          );
        },
        error: (error, stack) {
          logger.e('_KySocietyPageState: verifiedUsersAsync error - $error');
          return const Center(
            child:
                Text('Error loading data', style: TextStyle(color: Colors.red)),
          );
        },
        data: (snapshot) {
          final processed = _processSocietyData(snapshot);
          final displayDesignation = processed['displayDesignation'] as int;
          final keyContacts =
              processed['keyContacts'] as List<Map<String, dynamic>>;
          final committeeMembersCount =
              processed['committeeMembersCount'] as int;
          final residentsCount = processed['residentsCount'] as int;
          final rank = processed['rank'] as String;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAboutYouCard(
                  initials: initials,
                  userName: userName,
                  email: email,
                  rank: rank,
                  displayDesignation: displayDesignation,
                ),
                const SizedBox(height: 20),
                if (keyContacts.isNotEmpty) ...[
                  _buildKeyContactsCard(keyContacts),
                  const SizedBox(height: 12),
                ],
                _buildCountCard(
                  title: "Committee Members",
                  subtitle: "Total Members",
                  count: committeeMembersCount,
                  onTap: () {
                    logger.i(
                        'KySocietyPage: Navigating to Committee Members list');
                    ref.read(membersPageTitleProvider.notifier).state =
                        "Committee Members";
                    ref.read(membersPageDesignationProvider.notifier).state = 1;
                    ref.read(membersPageBuildingIdProvider.notifier).state =
                        buildingId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MembersListPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildCountCard(
                  title: "Residents",
                  subtitle: "Total Residents",
                  count: residentsCount,
                  onTap: () {
                    logger.i('KySocietyPage: Navigating to Residents list');
                    ref.read(membersPageTitleProvider.notifier).state =
                        "Residents";
                    ref.read(membersPageDesignationProvider.notifier).state = 0;
                    ref.read(membersPageBuildingIdProvider.notifier).state =
                        buildingId;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MembersListPage()),
                    );
                  },
                ),
                if (displayDesignation == 4)
                  _buildAssignRolesButton(
                    onTap: () {
                      logger.i('KySocietyPage: Navigating to Assign Roles page');
                      ref.read(assignRolesBuildingIdProvider.notifier).state = buildingId;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AssignRolesPage()),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
    logger.d('_KySocietyPageState: build method completed');
    return scaffold;
  }
}

class MembersListPage extends ConsumerStatefulWidget {
  const MembersListPage({super.key});

  @override
  ConsumerState<MembersListPage> createState() => _MembersListPageState();
}

class _MembersListPageState extends ConsumerState<MembersListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // UI: App Bar for Members List Page
  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    logger.d('MembersListPage: _buildAppBar called with title: $title');
    final appBar = AppBar(
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
      title: Text(
        title,
        style: const TextStyle(
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
    logger.d('MembersListPage: _buildAppBar completed');
    return appBar;
  }

  // UI: Member Item Card
  Widget _buildMemberItem(Map<String, dynamic> contact) {
    logger.d('MembersListPage: _buildMemberItem called');
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

    final itemWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        color: (desig == 0
                                ? const Color(0xFF78909C)
                                : getDesignationColor(desig))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        contactRank,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 0,
                          color: desig == 0
                              ? const Color(0xFF78909C)
                              : getDesignationColor(desig),
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
    );
    logger.d('MembersListPage: _buildMemberItem completed');
    return itemWidget;
  }

  // UI: Search Bar Field
  Widget _buildSearchBar() {
    logger.d('MembersListPage: _buildSearchBar called');
    final searchBarWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(
            fontFamily: "Poppins",
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
          ),
        ),
      ),
    );
    logger.d('MembersListPage: _buildSearchBar completed');
    return searchBarWidget;
  }

  @override
  Widget build(BuildContext context) {
    logger.d('MembersListPage: build method started');
    final title = ref.watch(membersPageTitleProvider);
    final targetDesignation = ref.watch(membersPageDesignationProvider);
    final buildingId = ref.watch(membersPageBuildingIdProvider);

    final verifiedUsersAsync =
        ref.watch(verifiedBuildingUsersStreamProvider(buildingId));

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, title),
      body: verifiedUsersAsync.when(
        loading: () {
          logger.d('MembersListPage: verifiedUsersAsync stream is loading');
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF222A54)),
          );
        },
        error: (error, stack) {
          logger.e('MembersListPage: verifiedUsersAsync error - $error');
          return const Center(
            child:
                Text('Error loading data', style: TextStyle(color: Colors.red)),
          );
        },
        data: (snapshot) {
          final members = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((data) => (data['designation'] ?? 0) == targetDesignation)
              .toList();

          final filteredMembers = members.where((member) {
            if (_searchQuery.isEmpty) return true;
            final fName = (member['firstName'] ?? '').toString().toLowerCase();
            final lName = (member['lastName'] ?? '').toString().toLowerCase();
            final email = (member['email'] ?? '').toString().toLowerCase();
            final fullName = '$fName $lName';
            return fullName.contains(_searchQuery) ||
                email.contains(_searchQuery);
          }).toList();

          logger.i(
              'MembersListPage: successfully filtered ${filteredMembers.length} members with designation $targetDesignation (search query: "$_searchQuery")');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              Expanded(
                child: filteredMembers.isEmpty
                    ? const Center(
                        child: Text(
                          'No members found',
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          return _buildMemberItem(filteredMembers[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
    logger.d('MembersListPage: build method completed');
    return scaffold;
  }
}
