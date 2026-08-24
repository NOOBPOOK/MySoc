import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  late String userId;
  late String userName;
  late String buildingId;
  int designation = 0;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        // Support both direct primitives and DocumentSnapshots for backward compatibility
        if (args.containsKey('userDetails')) {
          final userDetails = args['userDetails'];
          final buildingDetails = args['buildingDetails'];

          userId = userDetails.id;
          String fName = userDetails['firstName']?.toString() ?? '';
          String lName = userDetails['lastName']?.toString() ?? '';
          String rawName = '$fName $lName'.trim();
          List<String> nameParts = rawName.split(' ');
          userName = nameParts
              .map((part) {
                if (part.isEmpty) return '';
                return part[0].toUpperCase() + part.substring(1).toLowerCase();
              })
              .join(' ')
              .trim();

          buildingId = buildingDetails.id;
          designation = userDetails['designation'] ?? 0;
        } else {
          userId = args['userId'] ?? '';
          userName = args['userName'] ?? '';
          buildingId = args['buildingId'] ?? '';
          designation = args['designation'] ?? 0;
        }
      } else {
        userId = '';
        userName = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
      logger.d(
          'Announcements initialized with userId: $userId, userName: $userName, buildingId: $buildingId, designation: $designation');
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
        "Announcements",
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
        hintText: 'Search announcements...',
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

  // UI: Announcement Card
  Widget _buildAnnouncementCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'No Title';
    final content = data['content'] ?? '';
    final createdByName = data['createdByName'] ?? 'Admin';
    final createdAt = data['createdAt'] as Timestamp?;
    final tags =
        (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];

    String dateStr = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF7F2FA),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: Color(0xFF222A54)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF222A54),
                    ),
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222A54).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF222A54),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Text(
              "Posted by: $createdByName",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
                  Navigator.pushNamed(context, '/createAnnouncements',
                      arguments: {
                        'userId': userId,
                        'userName': userName,
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
          Expanded(
            child: buildingId.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF222A54)))
                : ref.watch(announcementsStreamProvider(buildingId)).when(
                      data: (snapshot) {
                        if (snapshot.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No announcements yet.",
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
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.only(bottom: 24.0, top: 4),
                            itemCount: snapshot.docs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final doc = snapshot.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildAnnouncementCard(data);
                            },
                          ),
                        );
                      },
                      loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF222A54)),
                      ),
                      error: (error, stack) {
                        logger.e('Error loading announcements: $error');
                        return const Center(
                          child: Text(
                            "Error loading announcements.",
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
    );
  }
}
