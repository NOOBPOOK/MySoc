import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/common/members/member_card.dart';
import 'package:my_soc/common/members/role_selection_sheet.dart';

// Backend: Provider to store the buildingId for the assign roles page.
// This allows us to share building context between KySocietyPage and AssignRolesPage without passing arguments.
final assignRolesBuildingIdProvider = StateProvider<String>((ref) {
  logger.d('assignRolesBuildingIdProvider: Initialized with empty string');
  return "";
});

class AssignRolesPage extends ConsumerStatefulWidget {
  const AssignRolesPage({super.key});

  @override
  ConsumerState<AssignRolesPage> createState() => _AssignRolesPageState();
}

class _AssignRolesPageState extends ConsumerState<AssignRolesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.d('_AssignRolesPageState: didChangeDependencies started initialization');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        final buildingDetails = args['buildingDetails'] as DocumentSnapshot?;
        final buildingId = buildingDetails?.id ?? args['buildingId'] ?? '';
        if (buildingId.isNotEmpty) {
          Future.microtask(() {
            ref.read(assignRolesBuildingIdProvider.notifier).state = buildingId;
            logger.i('_AssignRolesPageState: Set assignRolesBuildingIdProvider from route arguments: $buildingId');
          });
        }
      }
      _initialized = true;
      logger.d('_AssignRolesPageState: didChangeDependencies completed initialization');
    }
  }

  @override
  void dispose() {
    logger.d('_AssignRolesPageState: dispose started');
    _searchController.dispose();
    logger.d('_AssignRolesPageState: dispose completed');
    super.dispose();
  }

  // Backend: Handle search query change
  void _onSearchQueryChanged(String value) {
    logger.d('_AssignRolesPageState: _onSearchQueryChanged started with value: $value');
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
    logger.d('_AssignRolesPageState: _onSearchQueryChanged completed successfully with query: $_searchQuery');
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('_AssignRolesPageState: _buildAppBar called');
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
        "Assign Roles",
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
    logger.d('_AssignRolesPageState: _buildAppBar completed');
    return appBar;
  }

  // UI: Build the search bar
  Widget _buildSearchBar() {
    logger.d('_AssignRolesPageState: _buildSearchBar started');
    final searchBar = TextField(
      controller: _searchController,
      onChanged: _onSearchQueryChanged,
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
                  logger.d('_AssignRolesPageState: Clear search clicked');
                  _searchController.clear();
                  _onSearchQueryChanged("");
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
    );
    logger.d('_AssignRolesPageState: _buildSearchBar completed successfully');
    return searchBar;
  }

  // UI: Show options sheet on long press
  void _showOptionsSheet(BuildContext context, Map<String, dynamic> member) {
    logger.d('_AssignRolesPageState: _showOptionsSheet started for user: ${member['id']}');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF222A54)),
                title: const Text(
                  'View Profile',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  logger.i('_AssignRolesPageState: View Profile clicked for ${member['id']}');
                  Navigator.pop(context);
                  
                  final currentUser = ref.read(currentUserProvider).value;
                  final loggedInUserId = currentUser?.id ?? '';
                  final loggedInUserName = '${currentUser?.get('firstName') ?? ''} ${currentUser?.get('lastName') ?? ''}'.trim();
                  
                  Navigator.pushNamed(
                    context,
                    '/userDetails',
                    arguments: {
                      'userId': member['id'],
                      'loggedInUserId': loggedInUserId,
                      'loggedInUserName': loggedInUserName,
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF222A54)),
                title: const Text(
                  'Change Role',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  logger.i('_AssignRolesPageState: Change Role clicked for ${member['id']}');
                  Navigator.pop(context);
                  _showRoleSelectionDialog(context, member);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    logger.d('_AssignRolesPageState: _showOptionsSheet completed');
  }

  // UI: Show sheet to change role (delegates to RoleSelectionSheet widget class)
  void _showRoleSelectionDialog(BuildContext context, Map<String, dynamic> member) {
    logger.d('_AssignRolesPageState: _showRoleSelectionDialog started for user: ${member['id']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return RoleSelectionSheet(member: member);
      },
    );
    logger.d('_AssignRolesPageState: _showRoleSelectionDialog completed');
  }

  @override
  Widget build(BuildContext context) {
    logger.d('_AssignRolesPageState: build method started');
    final buildingId = ref.watch(assignRolesBuildingIdProvider);
    final verifiedUsersAsync = ref.watch(verifiedBuildingUsersStreamProvider(buildingId));

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                'Long press on cards to view options',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: buildingId.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF222A54),
                      ),
                    )
                  : verifiedUsersAsync.when(
                      loading: () {
                        logger.d('_AssignRolesPageState: verifiedUsersAsync is loading');
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF222A54)),
                        );
                      },
                      error: (error, stack) {
                        logger.e('_AssignRolesPageState: verifiedUsersAsync error - $error');
                        return const Center(
                          child: Text(
                            'Error loading data',
                            style: TextStyle(color: Colors.red, fontFamily: "Poppins"),
                          ),
                        );
                      },
                      data: (snapshot) {
                        final members = snapshot.docs
                            .map((doc) => {
                                  'id': doc.id,
                                  ...doc.data() as Map<String, dynamic>
                                })
                            .toList();

                        // Backend: Sort members by designation in descending order
                        members.sort((a, b) {
                          final aDesig = int.tryParse(a['designation']?.toString() ?? '0') ?? 0;
                          final bDesig = int.tryParse(b['designation']?.toString() ?? '0') ?? 0;
                          return bDesig.compareTo(aDesig);
                        });

                        final filteredMembers = members.where((member) {
                          if (_searchQuery.isEmpty) return true;
                          final fName = (member['firstName'] ?? '').toString().toLowerCase();
                          final lName = (member['lastName'] ?? '').toString().toLowerCase();
                          final email = (member['email'] ?? '').toString().toLowerCase();
                          final fullName = '$fName $lName';
                          return fullName.contains(_searchQuery) ||
                              email.contains(_searchQuery);
                        }).toList();

                        logger.i('_AssignRolesPageState: successfully filtered ${filteredMembers.length} members (search query: "$_searchQuery")');

                        if (filteredMembers.isEmpty) {
                          return const Center(
                            child: Text(
                              'No members found',
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

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
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24.0, top: 10),
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final contact = filteredMembers[index];
                              return MemberCard(
                                contact: contact,
                                onLongPress: () {
                                  logger.i('_AssignRolesPageState: Member item long pressed: $contact');
                                  _showOptionsSheet(context, contact);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    logger.d('_AssignRolesPageState: build method completed');
    return scaffold;
  }
}
