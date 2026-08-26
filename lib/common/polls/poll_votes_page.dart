import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

class PollVotesPage extends ConsumerStatefulWidget {
  const PollVotesPage({super.key});

  @override
  ConsumerState<PollVotesPage> createState() => _PollVotesPageState();
}

class _PollVotesPageState extends ConsumerState<PollVotesPage> {
  String pollId = '';
  String userId = '';
  List<Map<String, dynamic>> options = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        pollId = args['pollId'] ?? '';
        userId = args['userId'] ?? '';
        options = List<Map<String, dynamic>>.from(args['options'] ?? []);
      }
      _initialized = true;
    }
  }

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
        'Poll Votes',
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          color: Color(0xFF222A54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pollId.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('Invalid Poll Data')),
      );
    }

    final votesAsync = ref.watch(pollVotesStreamProvider(pollId));

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: votesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF222A54)),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading votes: $error',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(
              child: Text(
                'No votes cast yet.',
                style: TextStyle(
                  fontFamily: "Poppins",
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          // Grouping logic
          Map<String, List<String>> optionToUsersMap = {};
          List<String> myVotedOptionTexts = [];
          // Initialize map with all options
          for (var opt in options) {
            String optId = opt['optionId'] ?? '';
            optionToUsersMap[optId] = [];
          }

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? 'Unknown User';
            final List<dynamic> selectedOptionIds =
                data['selectedOptionIds'] ?? [];

            if (doc.id == userId) {
              for (var optId in selectedOptionIds) {
                final matchedOpt = options.firstWhere(
                    (o) => o['optionId'] == optId,
                    orElse: () => {});
                if (matchedOpt.isNotEmpty) {
                  myVotedOptionTexts.add(matchedOpt['text'] ?? '');
                }
              }
            }

            for (var optId in selectedOptionIds) {
              if (optionToUsersMap.containsKey(optId)) {
                optionToUsersMap[optId]!.add(name);
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (myVotedOptionTexts.isNotEmpty)
                _buildMyVoteCard(myVotedOptionTexts),
              ...options.map((opt) {
                final String optId = opt['optionId'] ?? '';
                final String text = opt['text'] ?? '';
                final List<String> users = optionToUsersMap[optId] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222A54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 8),
                        if (users.isEmpty)
                          const Text(
                            "No votes yet",
                            style: TextStyle(
                              fontFamily: "Poppins",
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ...users.map((name) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyVoteCard(List<String> myVotes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF222A54), Color(0xFF2C366B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF222A54).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_vote, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Your Vote",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1, thickness: 1),
            const SizedBox(height: 10),
            ...myVotes.map((voteText) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16,
                          color: Color(0xFF4ADE80)), // Premium pastel green
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          voteText,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
