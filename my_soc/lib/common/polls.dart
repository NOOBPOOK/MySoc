import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPollsPage extends ConsumerStatefulWidget {
  const UserPollsPage({super.key});

  @override
  ConsumerState<UserPollsPage> createState() => _UserPollsPageState();
}

class _UserPollsPageState extends ConsumerState<UserPollsPage> {
  late String userId;
  late String firstName;
  late String lastName;
  late String buildingId;
  int designation = 0;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        firstName = args['firstName'] ?? '';
        lastName = args['lastName'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
      } else {
        // Fallback for safety
        userId = '';
        firstName = '';
        lastName = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
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
        "Community Polls",
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

  // UI: Search Bar (Static/Unimplemented functionality for now)
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        // TODO: Implement actual search functionality later
      },
      decoration: InputDecoration(
        hintText: 'Search polls...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
          borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
        ),
      ),
    );
  }

  // UI: Mock List of Polls
  Widget _buildPollList() {
    // For now, returning a completely static UI as per user request
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 6, left: 16, right: 16),
        children: [
          _buildStaticPollCard(
            title: "Install Solar Panels on Roof?",
            description:
                "Should we install solar panels to offset common area electricity costs?",
            expiresAt: "Expires tomorrow at 5:00 PM",
            options: ["Yes, install it", "No, not needed", "Need more info"],
            voted: false,
          ),
          const SizedBox(height: 16),
          _buildStaticPollCard(
            title: "Change Swimming Pool Timings",
            description:
                "Proposal to extend swimming pool timings to 10 PM on weekends.",
            expiresAt: "Expired on Oct 12",
            options: ["Agree", "Disagree"],
            voted: true,
          ),
        ],
      ),
    );
  }

  // UI: A static mock card for a poll
  Widget _buildStaticPollCard({
    required String title,
    required String description,
    required String expiresAt,
    required List<String> options,
    required bool voted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            expiresAt,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.deepOrange,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          // Mock Options
          ...options.map((opt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    voted && opt == options.first
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: voted && opt == options.first
                        ? const Color(0xFF222A54)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (voted)
                    Text(
                      opt == options.first ? "65%" : "35%",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222A54),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      floatingActionButton: designation == 4
          ? Padding(
              padding: const EdgeInsets.only(right: 6.0, bottom: 8.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/userCreatePolls', arguments: {
                    'userId': userId,
                    'firstName': firstName,
                    'lastName': lastName,
                    'buildingId': buildingId,
                    'designation': designation,
                  });
                },
                backgroundColor: const Color(0xFF222A54),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildPollList()),
        ],
      ),
    );
  }
}
