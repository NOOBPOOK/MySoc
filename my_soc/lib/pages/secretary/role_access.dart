import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class RoleAccessPage extends StatefulWidget {
  const RoleAccessPage({super.key});

  @override
  State<RoleAccessPage> createState() => _RoleAccessPageState();
}

class _RoleAccessPageState extends State<RoleAccessPage> {
  bool isloading = true;
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;
  String currentTreasurerName = "None";
  int selectedRole = 0;

  Stream fetch_all_users() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: user_details['buildingId'])
        .where('isVerified', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFFE94560),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Role Access',
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        isRepeatingAnimation: false,
                        totalRepeatCount: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: SafeArea(
            child: StreamBuilder(
              stream: fetch_all_users(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Something went Wrong ${snapshot.error}",
                        style: const TextStyle(color: Colors.white)),
                  );
                }
                if (snapshot.hasData) {
                  List allUsers = snapshot.data!.docs;
                  return Stack(
                    children: [
                      Container(
                        child: ChooseTable(
                          allUserData: allUsers,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: IconButton(
                          icon:
                              const Icon(Icons.refresh, color: Color(0xFFE94560)),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                              MySocRoutes.secRoleBasedAccess,
                              arguments: {
                                'userDetails': user_details,
                                'buildingDetails': build_details
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateTreasurer(user) async {
    if (user['designation'] == 2) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'designation': 0});
      currentTreasurerName = "None";
      setState(() {});
      throw ("User has been removed from Treasurer");
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'designation': 2});
      currentTreasurerName = '${user['firstName']} ${user['lastName']}';
      setState(() {});
      throw ("User has been added as the Treasurer");
    }
  }
}

class ChooseTable extends StatefulWidget {
  final allUserData;
  const ChooseTable({super.key, required this.allUserData});

  @override
  State<ChooseTable> createState() => _ChooseTableState();
}

class _ChooseTableState extends State<ChooseTable> {
  String currentChairpersonName = "None";
  String currentTreasurerName = "None";
  String currentSecretaryName = "None";
  Set currentMember = {};
  int selectedRole = 1;
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var data;
    for (data in widget.allUserData) {
      if (data['designation'] == 4) {
        currentSecretaryName = '${data['firstName']} ${data['lastName']}';
      }
      if (data['designation'] == 3) {
        currentChairpersonName = '${data['firstName']} ${data['lastName']}';
      }
      if (data['designation'] == 2) {
        currentTreasurerName = '${data['firstName']} ${data['lastName']}';
      }
      if (data['designation'] == 1) {
        currentMember.add('${data['firstName']} ${data['lastName']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Draggable(
          feedback: _buildCurrentRoles(),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildCurrentRoles(),
          ),
          child: _buildCurrentRoles(),
        ),
        _buildRoleSelector(),
        Expanded(
          child: AnimationLimiter(
            child: _buildFilteredUsersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCurrentRoles() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          _buildRoleRow(
            'Secretary',
            currentSecretaryName,
            Colors.grey,
            Icons.admin_panel_settings,
          ),
          const Divider(color: Colors.white24, height: 8),
          _buildRoleRow(
            'Chairperson',
            currentChairpersonName,
            const Color(0xFFE94560),
            Icons.stars,
          ),
          const Divider(color: Colors.white24, height: 8),
          _buildRoleRow(
            'Treasurer',
            currentTreasurerName,
            const Color(0xFF2C698D),
            Icons.account_balance_wallet,
          ),
          const Divider(color: Colors.white24, height: 8),
          InkWell(
            onTap: () => _showCommitteeMembers(),
            child: _buildRoleRow(
              'Committee Members',
              '${currentMember.length} members',
              const Color(0xFF7B2CBF),
              Icons.group,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommitteeMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Committee Members',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currentMember.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  currentMember.elementAt(index),
                  style: const TextStyle(color: Colors.white),
                ),
                leading: const Icon(Icons.person, color: Color(0xFF7B2CBF)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(
    String role,
    String value,
    Color iconColor,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildRoleChip(
              1, 'Committee Members', Icons.group, const Color(0xFF7B2CBF)),
          _buildRoleChip(2, 'Treasurer', Icons.account_balance_wallet,
              const Color(0xFF2C698D)),
          _buildRoleChip(
              3, 'Chairperson', Icons.stars, const Color(0xFFE94560)),
        ],
      ),
    );
  }

  Widget _buildRoleChip(int role, String label, IconData icon, Color color) {
    final isSelected = selectedRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => selectedRole = selected ? role : selectedRole);
        },
        backgroundColor: color.withOpacity(0.2),
        selectedColor: color,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : color,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredUsersList() {
    var filteredUsers = widget.allUserData.where((user) {
      final String fullName =
          '${user['firstName']} ${user['lastName']}'.toLowerCase();
      final String role = _getRoleName(user['designation']).toLowerCase();
      return fullName.contains(searchQuery) || role.contains(searchQuery);
    }).toList();

    // Filter out users with designation 1-3
    filteredUsers = filteredUsers
        .where((user) =>
            user['designation'] != 1 &&
            user['designation'] != 2 &&
            user['designation'] != 3)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildUserCard(filteredUsers[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot user) {
    final Color cardColor = _getRoleColor(user['designation']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(0.7)],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(_getRoleIcon(user['designation']), color: Colors.white),
          ),
          title: Text(
            '${user['firstName']} ${user['lastName']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                user['email'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRoleName(user['designation']),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onLongPress: () => _handleRoleChange(user),
        ),
      ),
    );
  }

  Color _getRoleColor(int designation) {
    switch (designation) {
      case 4:
        return Colors.grey;
      case 3:
        return const Color(0xFFE94560);
      case 2:
        return const Color(0xFF2C698D);
      case 1:
        return const Color(0xFF7B2CBF);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getRoleIcon(int designation) {
    switch (designation) {
      case 4:
        return Icons.admin_panel_settings;
      case 3:
        return Icons.stars;
      case 2:
        return Icons.account_balance_wallet;
      case 1:
        return Icons.group;
      default:
        return Icons.person;
    }
  }

  String _getRoleName(int designation) {
    switch (designation) {
      case 4:
        return 'Secretary';
      case 3:
        return 'Chairperson';
      case 2:
        return 'Treasurer';
      case 1:
        return 'Committee Member';
      default:
        return 'Resident';
    }
  }

  void _handleRoleChange(QueryDocumentSnapshot user) async {
    if (user['designation'] == 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secretary role cannot be modified'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (selectedRole == 1) {
        if (user['designation'] == 1) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 0});
          currentMember.remove('${user['firstName']} ${user['lastName']}');
          setState(() {});
          throw ("User has been removed from Committee Members");
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 1});
          currentMember.add('${user['firstName']} ${user['lastName']}');
          setState(() {});
          throw ("User has been added to the Committee Members");
        }
      }

      if (selectedRole == 2) {
        if (user['designation'] == 2) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 0});
          currentTreasurerName = "None";
          setState(() {});
          throw ("User has been removed from Treasurer");
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 2});
          currentTreasurerName = '${user['firstName']} ${user['lastName']}';
          setState(() {});
          throw ("User has been added as the Treasurer");
        }
      }

      if (selectedRole == 3) {
        if (user['designation'] == 3) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 0});
          currentChairpersonName = "None";
          setState(() {});
          throw ("User has been removed as Chairperson");
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.id)
              .update({'designation': 3});
          currentChairpersonName = '${user['firstName']} ${user['lastName']}';
          setState(() {});
          throw ("User has been added as the Chairperson");
        }
      }
    } catch (e) {
      // Show confirmation message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Role Update Success',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE94560),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
