import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/common/complaints/create_complaints.dart';
import 'package:my_soc/common/complaints/complaint_details.dart';
import 'package:my_soc/providers/user_provider.dart';

class ComplaintsPage extends ConsumerStatefulWidget {
  const ComplaintsPage({super.key});

  @override
  ConsumerState<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends ConsumerState<ComplaintsPage> {
  int _currentIndex = 0;

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
        "Complaints",
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

  // UI: Common Sticky Search Bar
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        // TODO: Implement actual search functionality later
      },
      decoration: InputDecoration(
        hintText: 'Search complaints...',
        hintStyle: const TextStyle(
            fontFamily: "Poppins", color: Colors.grey, fontSize: 14),
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

  Widget _buildBodyContent(Map args) {
    final designation = args['designation'] ?? 0;
    final buildingId = args['buildingId'] ?? '';
    final userId = args['userId'] ?? '';

    if (designation == 4) {
      switch (_currentIndex) {
        case 0:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: false),
          );
        case 1:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: true),
          );
        case 2:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: null, userId: userId),
            showFab: true,
          );
        default:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: false),
          );
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: false),
          );
        case 1:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: null, userId: userId),
            showFab: true,
          );
        default:
          return ComplaintsTabView(
            args: args,
            filter: ComplaintsFilter(buildId: buildingId, isPrivate: false),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final designation = args['designation'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBodyContent(args)),
        ],
      ),
      bottomNavigationBar: ComplaintsFooter(
        currentIndex: _currentIndex,
        designation: designation,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: ComplaintsFooter
// ---------------------------------------------------------
class ComplaintsFooter extends StatelessWidget {
  final int currentIndex;
  final int designation;
  final Function(int) onTabSelected;

  const ComplaintsFooter({
    super.key,
    required this.currentIndex,
    required this.designation,
    required this.onTabSelected,
  });

  // UI: Build individual icon item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF222A54) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    if (designation == 4) {
      items = [
        _buildNavItem(index: 0, icon: Icons.public_rounded, label: "Public"),
        _buildNavItem(index: 1, icon: Icons.lock_rounded, label: "Private"),
        _buildNavItem(index: 2, icon: Icons.person_rounded, label: "Yours"),
      ];
    } else {
      items = [
        _buildNavItem(index: 0, icon: Icons.public_rounded, label: "Public"),
        _buildNavItem(index: 1, icon: Icons.person_rounded, label: "Yours"),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: Common Complaints Tab View
// ---------------------------------------------------------
class ComplaintsTabView extends ConsumerWidget {
  final Map args;
  final ComplaintsFilter filter;
  final bool showFab;

  const ComplaintsTabView({
    super.key,
    required this.args,
    required this.filter,
    this.showFab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsStreamProvider(filter));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: complaintsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF222A54)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading complaints: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(
                  fontFamily: "Poppins",
                  color: Colors.grey,
                  fontSize: 16,
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
              padding: const EdgeInsets.only(bottom: 80, top: 6, left: 16, right: 16),
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Untitled';
                final subject = data['subject'] ?? 'No subject';
                final description = data['description'] ?? 'No description provided.';
                final upvoteCount = data['upvoteCount'] ?? 0;
                final status = data['status'] ?? 0;

                String statusText;
                Color statusColor;
                switch (status) {
                  case 1:
                    statusText = 'Seen';
                    statusColor = Colors.blue;
                    break;
                  case 2:
                    statusText = 'Resolving';
                    statusColor = Colors.orange;
                    break;
                  case 3:
                    statusText = 'Resolved';
                    statusColor = Colors.green;
                    break;
                  case 0:
                  default:
                    statusText = 'Yet to see';
                    statusColor = Colors.grey;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailsPage(
                          args: {
                            ...args,
                            'complaintId': doc.id,
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF222A54),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subject,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$upvoteCount',
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF222A54),
                              ),
                            ),
                            const Text(
                              'Upvotes',
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateComplaintsPage(args: args),
                  ),
                );
              },
              backgroundColor: const Color(0xFF222A54),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
