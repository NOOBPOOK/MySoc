import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

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

  // UI: Dynamic List of Polls from Firestore
  Widget _buildPollList() {
    final pollsAsync = ref.watch(pollsStreamProvider(buildingId));

    return pollsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF222A54)),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading polls: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (snapshot) {
        if (snapshot.docs.isEmpty) {
          return const Center(
            child: Text(
              'No polls available for your community.',
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
          child: ListView.separated(
            padding:
                const EdgeInsets.only(bottom: 24, top: 6, left: 16, right: 16),
            itemCount: snapshot.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled Poll';
              final description = data['description'] ?? '';

              bool isExpired = false;
              String expiresAtText = 'Unknown Expiry';
              if (data['expiresAt'] != null) {
                final expiresAt = (data['expiresAt'] as Timestamp).toDate();
                if (expiresAt.isBefore(DateTime.now())) {
                  isExpired = true;
                  expiresAtText =
                      'Expired on ${DateFormat('MMM dd, yyyy').format(expiresAt)}';
                } else {
                  expiresAtText =
                      'Expires on ${DateFormat('MMM dd, yyyy').format(expiresAt)}';
                }
              }

              List<Map<String, dynamic>> parsedOptions = [];
              if (data['options'] != null) {
                for (var opt in data['options']) {
                  parsedOptions.add(Map<String, dynamic>.from(opt));
                }
              }

              final isAnonymous = data['isAnonymous'] ?? true;
              final allowMultipleSelections =
                  data['allowMultipleSelections'] ?? false;

              final List<dynamic> votedUserIds = data['votedUserIds'] ?? [];
              final bool hasVoted = votedUserIds.contains(userId);

              final Map<String, dynamic> optionCounts =
                  Map<String, dynamic>.from(data['optionCounts'] ?? {});

              return PollCard(
                pollId: doc.id,
                userId: userId,
                firstName: firstName,
                lastName: lastName,
                title: title,
                description: description,
                expiresAt: expiresAtText,
                options: parsedOptions,
                optionCounts: optionCounts,
                isAnonymous: isAnonymous,
                allowMultipleSelections: allowMultipleSelections,
                voted: hasVoted,
                isExpired: isExpired,
              );
            },
          ),
        );
      },
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

class PollCard extends ConsumerStatefulWidget {
  final String pollId;
  final String userId;
  final String firstName;
  final String lastName;
  final String title;
  final String description;
  final String expiresAt;
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic> optionCounts;
  final bool isAnonymous;
  final bool allowMultipleSelections;
  final bool voted;
  final bool isExpired;

  const PollCard({
    super.key,
    required this.pollId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.description,
    required this.expiresAt,
    required this.options,
    required this.optionCounts,
    required this.isAnonymous,
    required this.allowMultipleSelections,
    required this.voted,
    required this.isExpired,
  });

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  List<String> _selectedOptions = [];
  bool _localExpired = false;

  bool get _isExpired => widget.isExpired || _localExpired;

  void _toggleOption(String optId) {
    if (_isExpired) {
      logger.d(
          'User ${widget.userId} tried to vote on expired poll ${widget.pollId}, ignoring tap.');
      return;
    }
    if (widget.voted) {
      logger.d(
          'User ${widget.userId} already voted on poll ${widget.pollId}, ignoring tap.');
      return;
    }

    setState(() {
      if (widget.allowMultipleSelections) {
        if (_selectedOptions.contains(optId)) {
          _selectedOptions.remove(optId);
        } else {
          _selectedOptions.add(optId);
        }
      } else {
        _selectedOptions = [optId];
      }
    });
    logger.d(
        'Poll ${widget.pollId}: Local selections updated -> $_selectedOptions');
  }

  void _submitVote() {
    if (_selectedOptions.isEmpty) {
      logger.d(
          'User ${widget.userId} attempted to submit vote with no options selected.');
      return;
    }
    logger.i(
        'User ${widget.userId} submitting vote for poll ${widget.pollId} with options: $_selectedOptions');

    Future.microtask(() async {
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final pollRef =
              FirebaseFirestore.instance.collection('polls').doc(widget.pollId);
          final voteRef = pollRef.collection('votes').doc(widget.userId);

          final pollSnapshot = await transaction.get(pollRef);
          if (!pollSnapshot.exists) return;

          final data = pollSnapshot.data()!;
          if (data['expiresAt'] != null) {
            final expiresAt = (data['expiresAt'] as Timestamp).toDate();
            if (expiresAt.isBefore(DateTime.now())) {
              logger.w(
                  'User ${widget.userId} attempted to vote on an expired poll');
              throw Exception('EXPIRED');
            }
          }

          final voteSnapshot = await transaction.get(voteRef);
          if (voteSnapshot.exists) {
            logger.i("Duplicate voting is not allowed");
            return;
          } // Prevent duplicate voting

          String rawName = '${widget.firstName} ${widget.lastName}'
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          List<String> nameParts = rawName.split(' ');
          List<String> capitalizedParts = nameParts.map((part) {
            if (part.isEmpty) return '';
            return part[0].toUpperCase() + part.substring(1).toLowerCase();
          }).toList();
          String finalName = capitalizedParts.join(' ');

          transaction.set(voteRef, {
            'selectedOptionIds': _selectedOptions,
            'name': finalName,
            'votedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Map<String, dynamic> optionCounts =
              Map<String, dynamic>.from(data['optionCounts'] ?? {});
          int totalVotes = data['totalVotes'] ?? 0;

          for (var optId in _selectedOptions) {
            int currentCount = optionCounts[optId] ?? 0;
            optionCounts[optId] = currentCount + 1;
          }
          totalVotes += 1;

          transaction.update(pollRef, {
            'optionCounts': optionCounts,
            'totalVotes': totalVotes,
            'votedUserIds': FieldValue.arrayUnion([widget.userId]),
          });
        });
        logger.i(
            'User ${widget.userId} successfully submitted vote for poll ${widget.pollId}');
      } catch (e) {
        if (e.toString().contains('EXPIRED')) {
          CustomToast.show(context, type: -1, message: 'The poll has expired.');
          if (mounted) {
            setState(() {
              _localExpired = true;
            });
          }
        }
        logger.e('Error submitting vote for poll ${widget.pollId}: $e');
      }
    }).catchError((e) {
      logger.e('Microtask error in _submitVote: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasVoted = widget.voted;

    return Container(
      padding: const EdgeInsets.all(12),
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
            widget.title,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222A54),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.expiresAt,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.deepOrange,
            ),
          ),
          const Divider(height: 16, thickness: 1),
          // Options
          ...widget.options.map((opt) {
            final String optId = opt['optionId'] ?? '';
            final String optText = opt['text'] ?? '';
            final bool isSelected = _selectedOptions.contains(optId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _toggleOption(optId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF222A54).withOpacity(0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF222A54).withOpacity(0.3)
                            : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? (widget.allowMultipleSelections
                                ? Icons.check_box
                                : Icons.radio_button_checked)
                            : (widget.allowMultipleSelections
                                ? Icons.check_box_outline_blank
                                : Icons.radio_button_off),
                        color:
                            isSelected ? const Color(0xFF222A54) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF222A54)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        "${widget.optionCounts[optId] ?? 0}",
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222A54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (_isExpired || hasVoted || _selectedOptions.isEmpty)
                          ? null
                          : _submitVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222A54),
                    disabledBackgroundColor: _isExpired
                        ? Colors.grey.shade800
                        : (hasVoted ? Colors.green : null),
                    disabledForegroundColor:
                        (_isExpired || hasVoted) ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isExpired
                        ? "Expired"
                        : (hasVoted ? "Voted" : "Submit Vote"),
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isAnonymous
                      ? null
                      : () {
                          logger.i(
                              'User ${widget.userId} clicked View Votes for poll ${widget.pollId}');
                          Navigator.pushNamed(
                            context,
                            '/pollVotes',
                            arguments: {
                              'pollId': widget.pollId,
                              'options': widget.options,
                              'userId': widget.userId,
                            },
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.isAnonymous
                          ? Colors.grey.shade400
                          : const Color(0xFF222A54),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "View Votes",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      color: widget.isAnonymous
                          ? Colors.grey.shade500
                          : const Color(0xFF222A54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
