import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/utils/app_logger.dart';

class ComplaintDetailsPage extends ConsumerStatefulWidget {
  final Map args;

  const ComplaintDetailsPage({super.key, required this.args});

  @override
  ConsumerState<ComplaintDetailsPage> createState() =>
      _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends ConsumerState<ComplaintDetailsPage> {
  bool? _hasVoted;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _checkIfVoted();
  }

  Future<void> _checkIfVoted() async {
    final complaintId = widget.args['complaintId'] as String?;
    final userId = widget.args['userId'] as String?;
    if (complaintId == null || userId == null || userId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('upvotes')
          .doc(userId)
          .get();
      if (mounted) {
        setState(() {
          _hasVoted = doc.exists;
        });
      }
    } catch (e) {
      logger.e("Error checking vote status: $e");
    }
  }

  // Backend: Toggle upvote status
  void _toggleUpvote(String complaintId) {
    if (_isVoting || _hasVoted == null) {
      logger.w('_toggleUpvote: Blocked toggle upvote because a transaction is in progress or initial state is still loading.');
      return;
    }

    final userId = widget.args['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      logger.w('_toggleUpvote: Cannot toggle upvote: userId is missing');
      return;
    }

    setState(() {
      _isVoting = true;
    });

    logger.i(
        '_toggleUpvote: Toggling upvote for complaint $complaintId by user $userId');
    Future.microtask(() async {
      final complaintRef =
          FirebaseFirestore.instance.collection('complaints').doc(complaintId);
      final upvoteRef = complaintRef.collection('upvotes').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final upvoteSnapshot = await transaction.get(upvoteRef);
        final complaintSnapshot = await transaction.get(complaintRef);

        if (!complaintSnapshot.exists) return;

        int currentCount = complaintSnapshot.data()?['upvoteCount'] ?? 0;

        if (upvoteSnapshot.exists) {
          // Already voted, remove vote
          transaction.delete(upvoteRef);
          transaction.update(complaintRef, {
            'upvoteCount': currentCount - 1,
          });
        } else {
          // Not voted, add vote
          transaction.set(upvoteRef, {
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(complaintRef, {
            'upvoteCount': currentCount + 1,
          });
        }
      });
      if (mounted) {
        setState(() {
          _hasVoted = !(_hasVoted ?? false);
          _isVoting = false;
        });
      }
      logger.i(
          '_toggleUpvote: Successfully toggled upvote for complaint $complaintId');
    }).catchError((e) {
      logger.e('_toggleUpvote: Error toggling upvote: $e');
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    });
  }

  // UI: Build the main content of the details page based on stream state
  Widget _buildContent(
      BuildContext context, AsyncValue<DocumentSnapshot> complaintAsync) {
    return complaintAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF222A54)),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading complaint: $error',
          style: const TextStyle(color: Colors.red, fontFamily: "Poppins"),
        ),
      ),
      data: (snapshot) {
        if (!snapshot.exists) {
          return const Center(
            child: Text(
              "Complaint not found.",
              style: TextStyle(
                  fontFamily: "Poppins", color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Untitled';
        final subject = data['subject'] ?? 'No subject';
        final description = data['description'] ?? 'No description provided.';
        final status = data['status'] ?? 0;
        final upvoteCount = data['upvoteCount'] ?? 0;

        final createdByName = data['createdByName'] ?? 'Anonymous';
        final createdAtTimestamp = data['createdAt'] as Timestamp?;
        final createdAtStr = createdAtTimestamp != null
            ? DateFormat('MMM dd, yyyy').format(createdAtTimestamp.toDate())
            : 'Unknown Date';

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

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: FractionallySizedBox(
            heightFactor: (widget.args['designation'] as int? ?? 0) == 4 ? 0.9 : 0.8,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222A54),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        createdByName,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        createdAtStr,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  _buildSectionBox("Subject", subject, Icons.subject_rounded),
                  const SizedBox(height: 16),
                  _buildExpandedSectionBox(
                      "Description", description, Icons.description_rounded),
                  const SizedBox(height: 16),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_hasVoted == null || _isVoting)
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF222A54),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _toggleUpvote(snapshot.id),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              _hasVoted!
                                  ? Icons.thumb_up_alt
                                  : Icons.thumb_up_alt_outlined,
                              color: const Color(0xFF222A54),
                              size: 20,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        "$upvoteCount",
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222A54),
                        ),
                      ),
                    ],
                  ),
                  if ((widget.args['designation'] as int? ?? 0) == 4) ...[
                    const SizedBox(height: 16),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),
                    AdminStatusSlider(
                      complaintId: snapshot.id,
                      initialStatus: status,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // UI: Static Section Box (for subject)
  Widget _buildSectionBox(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF222A54)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222A54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // UI: Expanded Section Box (for scrollable description)
  Widget _buildExpandedSectionBox(String title, String content, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF222A54)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222A54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintId = widget.args['complaintId'] as String?;

    if (complaintId == null || complaintId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Error",
            style: TextStyle(fontFamily: "Poppins", color: Color(0xFF222A54)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF222A54)),
        ),
        body: const Center(
          child: Text(
            "Invalid Complaint ID",
            style: TextStyle(fontFamily: "Poppins"),
          ),
        ),
      );
    }

    final complaintAsync = ref.watch(complaintStreamProvider(complaintId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 62.0,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF222A54), width: 2.0),
        ),
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        titleSpacing: 0,
        title: const Text(
          "Complaint Details",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 25,
            color: Color(0xFF222A54),
          ),
        ),
      ),
      body: _buildContent(context, complaintAsync),
    );
  }
}

class AdminStatusSlider extends StatefulWidget {
  final String complaintId;
  final int initialStatus;

  const AdminStatusSlider({
    super.key,
    required this.complaintId,
    required this.initialStatus,
  });

  @override
  State<AdminStatusSlider> createState() => _AdminStatusSliderState();
}

class _AdminStatusSliderState extends State<AdminStatusSlider> {
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialStatus.toDouble();
  }

  @override
  void didUpdateWidget(AdminStatusSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      _currentValue = widget.initialStatus.toDouble();
    }
  }

  String _getLabel(int status) {
    switch (status) {
      case 1:
        return 'Seen';
      case 2:
        return 'Resolving';
      case 3:
        return 'Resolved';
      case 0:
      default:
        return 'Yet to see';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Update Status",
          style: TextStyle(
            fontFamily: "Poppins",
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222A54),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF222A54),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: const Color(0xFF222A54),
            valueIndicatorTextStyle: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.white,
            ),
          ),
          child: Slider(
            value: _currentValue,
            min: 0,
            max: 3,
            divisions: 3,
            label: _getLabel(_currentValue.toInt()),
            onChanged: (value) {
              if (value >= widget.initialStatus.toDouble()) {
                setState(() {
                  _currentValue = value;
                });
              }
            },
            onChangeEnd: (value) {
              if (value.toInt() > widget.initialStatus) {
                FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(widget.complaintId)
                    .update({'status': value.toInt()}).catchError((e) {
                  // Revert if error
                  setState(() {
                    _currentValue = widget.initialStatus.toDouble();
                  });
                });
              } else {
                setState(() {
                  _currentValue = widget.initialStatus.toDouble();
                });
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Yet to see",
                style: TextStyle(
                    fontFamily: "Poppins", fontSize: 12, color: Colors.grey)),
            Text("Seen",
                style: TextStyle(
                    fontFamily: "Poppins", fontSize: 12, color: Colors.grey)),
            Text("Resolving",
                style: TextStyle(
                    fontFamily: "Poppins", fontSize: 12, color: Colors.grey)),
            Text("Resolved",
                style: TextStyle(
                    fontFamily: "Poppins", fontSize: 12, color: Colors.grey)),
          ],
        )
      ],
    );
  }
}
