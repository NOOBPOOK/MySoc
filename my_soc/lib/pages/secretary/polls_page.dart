import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Add provider package

// Create a user provider to manage user state
class UserProvider extends ChangeNotifier {
  String? _userId;
  int _userDesignation = 1;

  String get userId => _userId ?? '';
  int get userDesignation => _userDesignation;

  void setUser(String id, int designation) {
    _userId = id;
    _userDesignation = designation;
    notifyListeners();
  }
}

class ViewPollsPage extends StatefulWidget {
  const ViewPollsPage({Key? key}) : super(key: key);

  @override
  _ViewPollsPageState createState() => _ViewPollsPageState();
}

class _ViewPollsPageState extends State<ViewPollsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize user provider with user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // Assuming you have user data available here
      final userId = 'user_id_example'; // Replace with actual user ID
      final userDesignation = 2; // Replace with actual user designation
      userProvider.setUser(userId, userDesignation);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getPollsStream(bool expired, int userDesignation) {
    final now = Timestamp.now();
    Query query = FirebaseFirestore.instance.collection('polls');

    if (userDesignation < 3) {
      query = query.where('visibility', isEqualTo: 1);
    }

    if (expired) {
      query = query.where('expiryDate', isLessThan: now);
    } else {
      query = query.where('expiryDate', isGreaterThanOrEqualTo: now);
    }

    return query.orderBy('expiryDate', descending: true).snapshots();
  }

  Future<void> _castVote(String pollId, String option, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'votes.$userId': {
          'option': option,
          'timestamp': FieldValue.serverTimestamp(),
          'userName': userId,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote cast successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error casting vote: $e')),
      );
    }
  }

  String _getDesignationText(int designation) {
    switch (designation) {
      case 2:
        return 'Treasurer';
      case 3:
        return 'Chairperson';
      case 4:
        return 'Secretary';
      default:
        return 'Committee Member';
    }
  }

  Widget _buildVoteOption({
    required String option,
    required bool isSelected,
    required bool isExpired,
    required VoidCallback onTap,
    required bool showResults,
    required int voteCount,
    required int totalVotes,
  }) {
    final percentage = totalVotes > 0
        ? (voteCount / totalVotes * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isExpired ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFFE94560) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.1),
          ),
          child: Column(
            children: [
              if (showResults)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: LinearProgressIndicator(
                    value: totalVotes > 0 ? voteCount / totalVotes : 0,
                    backgroundColor: Colors.grey[100],
                    minHeight: 6,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle,
                            color: const Color(0xFFE94560), size: 20),
                      ),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE94560)
                              : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (showResults)
                      Text(
                        '$voteCount ($percentage%)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollCard(
      Map<String, dynamic> data, String docId, bool isExpired, String userId) {
    final expiryDate = (data['expiryDate'] as Timestamp).toDate();
    final votes = data['votes'] as Map<String, dynamic>? ?? {};
    final userVoteData = votes[userId];
    String? userVote;

    if (userVoteData is Map<String, dynamic>) {
      userVote = userVoteData['option'] as String?;
    } else if (userVoteData is String) {
      userVote = userVoteData;
    }

    final showResults = data['showResults'] as bool? ?? false;
    final options = List<String>.from(data['options']);
    final creatorDesignation = data['creatorDesignation'] as int?;

    final voteCounts = <String, int>{};
    int totalVotes = 0;

    for (final vote in votes.values) {
      String? optionVoted;
      if (vote is Map<String, dynamic>) {
        optionVoted = vote['option'] as String?;
      } else if (vote is String) {
        optionVoted = vote;
      }

      if (optionVoted != null) {
        voteCounts[optionVoted] = (voteCounts[optionVoted] ?? 0) + 1;
        totalVotes++;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['subject'] as String? ?? 'Untitled Poll',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (creatorDesignation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getDesignationText(creatorDesignation),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off : Icons.timer,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired
                          ? 'Expired on ${DateFormat('MMM dd, yyyy HH:mm').format(expiryDate)}'
                          : 'Expires on ${DateFormat('MMM dd, yyyy HH:mm').format(expiryDate)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalVotes > 0 && showResults)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Total votes: $totalVotes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ...options.map((option) => _buildVoteOption(
                      option: option,
                      isSelected: userVote == option,
                      isExpired: isExpired,
                      onTap: () => _castVote(docId, option, userId),
                      showResults: showResults,
                      voteCount: voteCounts[option] ?? 0,
                      totalVotes: totalVotes,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsList(bool expired) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: _getPollsStream(expired, userProvider.userDesignation),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      expired ? Icons.history : Icons.how_to_vote,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      expired ? 'No expired polls' : 'No active polls',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                return _buildPollCard(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                  expired,
                  userProvider.userId,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Polls'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.how_to_vote),
                text: 'Active Polls',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Expired Polls',
              ),
            ],
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPollsList(false),
              _buildPollsList(true),
            ],
          ),
        ),
      ),
    );
  }
}
