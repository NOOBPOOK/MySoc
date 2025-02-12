import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserInfo {
  final String id;
  final String name;

  UserInfo({required this.id, required this.name});
}

class CreatePollsPage extends StatefulWidget {
  final String userId;
  final int userDesignation;

  const CreatePollsPage({
    Key? key,
    required this.userId,
    required this.userDesignation,
  }) : super(key: key);

  @override
  _CreatePollsPageState createState() => _CreatePollsPageState();
}

class _CreatePollsPageState extends State<CreatePollsPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 1));
  bool _showResults = true;
  int _visibility = 0; // Changed default to 0 for "Everyone"
  bool _showCreateForm = false;
  Map<String, UserInfo> _userCache = {};

  @override
  void dispose() {
    _subjectController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<UserInfo> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final name =
            (userData['name'] as Map<String, dynamic>?)?['firstName'] ??
                userData['firstName'] ??
                'Unknown User';

        final userInfo = UserInfo(
          id: userId,
          name: name,
        );
        _userCache[userId] = userInfo;
        return userInfo;
      }

      return UserInfo(id: userId, name: 'Unknown User');
    } catch (e) {
      print('Error fetching user info: $e');
      return UserInfo(id: userId, name: 'Unknown User');
    }
  }

  void _showPollDetails(Map<String, dynamic> poll, String creatorName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final votes = poll['votes'] as Map<dynamic, dynamic>? ?? {};
        final options = List<String>.from(poll['options']);
        final expiryDate = (poll['expiryDate'] as Timestamp).toDate();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        poll['subject'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Created by: $creatorName',
                    style: const TextStyle(color: Colors.grey)),
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy HH:mm').format(expiryDate)}',
                  style: TextStyle(
                    color: expiryDate.isBefore(DateTime.now())
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                Text(
                  'Visibility: ${poll['visibility'] == 0 ? 'Everyone' : 'Committee Members Only'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: options.map((option) {
                        final voters = votes.entries
                            .where((entry) =>
                                entry.value == option ||
                                (entry.value is Map &&
                                    entry.value['option'] == option))
                            .toList();
                        final voteCount = voters.length;
                        final percentage = votes.isNotEmpty
                            ? (voteCount / votes.length * 100)
                                .toStringAsFixed(1)
                            : '0.0';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: votes.isNotEmpty
                                    ? voteCount / votes.length
                                    : 0,
                                backgroundColor: Colors.grey[200],
                                color: Colors.blue,
                                minHeight: 10,
                              ),
                              const SizedBox(height: 4),
                              Text('$voteCount votes ($percentage%)'),
                              if (voters.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: voters.map((voter) {
                                      return FutureBuilder<UserInfo>(
                                        future: _getUserInfo(voter.key),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox.shrink();
                                          }
                                          final voterInfo = snapshot.data!;
                                          final voteData = voter.value is Map
                                              ? voter.value
                                              : null;
                                          final timestamp = voteData != null &&
                                                  voteData['timestamp'] != null
                                              ? DateFormat('MMM dd, HH:mm')
                                                  .format((voteData['timestamp']
                                                          as Timestamp)
                                                      .toDate())
                                              : 'N/A';

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person_outline,
                                                    size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child:
                                                        Text(voterInfo.name)),
                                                Text(timestamp,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Replace the _buildPollsList() method with this updated version:
  Widget _buildPollsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final polls = snapshot.data!.docs;

        if (polls.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No polls available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index].data() as Map<String, dynamic>;
            final votes = poll['votes'] as Map<dynamic, dynamic>? ?? {};
            final options = List<String>.from(poll['options']);
            final expiryDate = (poll['expiryDate'] as Timestamp).toDate();
            final isExpired = expiryDate.isBefore(DateTime.now());
            final creatorId = poll['createdBy'] as String?;
            final showResults = poll['showResults'] ?? true;
            final hasVoted = votes.containsKey(widget.userId);
            final userVote = hasVoted ? votes[widget.userId] : null;
            final pollVisibility = poll['visibility'] ?? 0;

            // Check if user can view this poll
            if (pollVisibility == 1 && widget.userDesignation < 2) {
              return const SizedBox
                  .shrink(); // Hide committee-only polls from regular users
            }

            return FutureBuilder<UserInfo>(
              future: creatorId != null ? _getUserInfo(creatorId) : null,
              builder: (context, creatorSnapshot) {
                final creatorName =
                    creatorSnapshot.data?.name ?? 'Unknown User';

                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        poll['subject'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Created by: $creatorName',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Row(
                            children: [
                              Icon(
                                isExpired ? Icons.timer_off : Icons.timer,
                                size: 14,
                                color: isExpired ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: ${DateFormat('MMM dd, yyyy HH:mm').format(expiryDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                pollVisibility == 0
                                    ? Icons.public
                                    : Icons.group,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Visibility: ${pollVisibility == 0 ? 'Everyone' : 'Committee Members Only'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.how_to_vote,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Total Votes: ${votes.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          if (hasVoted)
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'You voted: ${userVote is Map ? userVote['option'] : userVote}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!showResults && !hasVoted)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Results will be visible after voting',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ...options.map((option) {
                                final voteCount = votes.entries
                                    .where((entry) =>
                                        entry.value == option ||
                                        (entry.value is Map &&
                                            entry.value['option'] == option))
                                    .length;

                                final totalVotes = votes.length;
                                final percentage = totalVotes > 0
                                    ? (voteCount / totalVotes * 100)
                                        .toStringAsFixed(1)
                                    : '0.0';

                                final isUserVote = userVote is Map
                                    ? userVote['option'] == option
                                    : userVote == option;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isUserVote
                                            ? Colors.blue
                                            : Colors.grey[300]!,
                                        width: isUserVote ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (isUserVote)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 8),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontWeight: isUserVote
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Show results in these cases:
                                        // 1. If showResults is true
                                        // 2. If this is the user's own vote
                                        if (showResults ||
                                            (hasVoted && isUserVote)) ...[
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: totalVotes > 0
                                                  ? voteCount / totalVotes
                                                  : 0,
                                              backgroundColor: Colors.grey[200],
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$voteCount votes ($percentage%)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              if (widget.userDesignation >= 3)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Detailed Voter Information:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              if (widget.userDesignation >= 3)
                                ...options.map((option) =>
                                    _buildVoterDetails(votes, option)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.userDesignation < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only committee members can create polls'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = await _getUserInfo(widget.userId);

    final poll = {
      'subject': _subjectController.text,
      'options': _optionControllers.map((c) => c.text).toList(),
      'createdBy': widget.userId,
      'creatorName': currentUser.name,
      'creatorDesignation': widget.userDesignation,
      'createdAt': FieldValue.serverTimestamp(),
      'expiryDate': Timestamp.fromDate(_expiryDate),
      'showResults': _showResults,
      'visibility': _visibility, // 0 for everyone, 1 for committee members
      'votes': {},
    };

    try {
      await FirebaseFirestore.instance.collection('polls').add(poll);
      setState(() {
        _showCreateForm = false;
        _subjectController.clear();
        for (var controller in _optionControllers) {
          controller.clear();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating poll: $e')),
      );
    }
  }

  Widget _buildVoterDetails(Map<dynamic, dynamic> votes, String option) {
    return FutureBuilder<List<Widget>>(
      future: Future.wait(
        votes.entries
            .where((entry) =>
                entry.value == option ||
                (entry.value is Map && entry.value['option'] == option))
            .map((entry) async {
          final userId = entry.key;
          final voteData = entry.value is Map ? entry.value : null;
          final userInfo = await _getUserInfo(userId);
          final timestamp = voteData != null && voteData['timestamp'] != null
              ? DateFormat('MMM dd, yyyy HH:mm')
                  .format((voteData['timestamp'] as Timestamp).toDate())
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.only(left: 24, top: 4),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userInfo.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 24, top: 8, bottom: 4),
              child: Text(
                'Voters:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...snapshot.data!,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polls'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showCreateForm) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: const InputDecoration(
                                    labelText: 'Poll Subject',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Please enter a subject';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Options',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(_optionControllers.length,
                                    (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _optionControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Option ${index + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'Please enter an option';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        if (_optionControllers.length > 2)
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () =>
                                                _removeOption(index),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: _addOption,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Option'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Poll Settings',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('Expiry Date'),
                                  subtitle: Text(
                                    DateFormat('MMM dd, yyyy HH:mm')
                                        .format(_expiryDate),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _expiryDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                              _expiryDate),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _expiryDate = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              time.hour,
                                              time.minute,
                                            );
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                                SwitchListTile(
                                  title: const Text('Show Results'),
                                  subtitle: const Text(
                                    'Allow voters to see all poll results',
                                  ),
                                  value: _showResults,
                                  onChanged: (value) {
                                    setState(() => _showResults = value);
                                  },
                                ),
                                RadioListTile(
                                  title: const Text('Visible to Everyone'),
                                  value: 0, // Changed to 0 for everyone
                                  groupValue: _visibility,
                                  onChanged: (value) {
                                    setState(() => _visibility = value as int);
                                  },
                                ),
                                RadioListTile(
                                  title: const Text('Committee Members Only'),
                                  value:
                                      1, // Changed to 1 for committee members
                                  groupValue: _visibility,
                                  onChanged: (value) {
                                    setState(() => _visibility = value as int);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() => _showCreateForm = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _createPoll,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Text('Create Poll'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_showCreateForm) ...[
                  _buildPollsList(),
                ],
              ],
            ),
          ),
          if (!_showCreateForm)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() => _showCreateForm = true);
                },
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }
}
