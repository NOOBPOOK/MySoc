// This page is used for viewing and take actions on user complaints
// This page by default assumes that you are secretary for that matter

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';

class ComplaintsPage extends StatefulWidget {
  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

@override
Widget build(BuildContext context) {
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
                          'Complaints',
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Your list of complaints and other widgets go here
                      // Example:
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: 10, // Replace with your actual item count
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: Text('Complaint $index'),
                              subtitle: Text('Details of complaint $index'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Your other widgets go here
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    // Add your onPressed code here
                  },
                  child: Icon(Icons.add),
                  backgroundColor: Color(0xFFE94560),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complaints',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          MySocRoutes.addComplaints,
                          arguments: {
                            'userDetails': user_details,
                            'buildingDetails': build_details,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      'Public\nComplaints',
                      0,
                      const Color(0xFF4ECDC4),
                    ),
                    if (user_details['designation'] == 4)
                      _buildTabButton(
                        'Shared\nwith you',
                        1,
                        const Color(0xFFFFBE0B),
                      ),
                    _buildTabButton(
                      'Your\nComplaints',
                      2,
                      const Color(0xFFFF006E),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    publicComplaints(
                      user_detials: user_details,
                      build_details: build_details,
                    ),
                    if (user_details['designation'] == 4)
                      sharedWithYou(
                        user_detials: user_details,
                        build_details: build_details,
                      ),
                    yourComplaints(
                      user_detials: user_details,
                      build_details: build_details,
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

  Widget _buildTabButton(String text, int pageIndex, Color color) {
    final isSelected = _currentPage == pageIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.white.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class publicComplaints extends StatefulWidget {
  final user_detials;
  final build_details;
  const publicComplaints({super.key, this.user_detials, this.build_details});

  @override
  State<publicComplaints> createState() => _publicComplaintsState();
}

class _publicComplaintsState extends State<publicComplaints> {
  Stream getPublicComplaints() {
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.build_details.id)
        .collection('complaints')
        .orderBy('status')
        .where('isPrivate', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
      ),
      child: StreamBuilder(
        stream: getPublicComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went Wrong ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.hasData) {
            return DisplayPublicComplaints(
              buildId: widget.build_details.id,
              userId: widget.user_detials.id,
              user: widget.user_detials,
              complaints: snapshot.data!.docs,
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class sharedWithYou extends StatefulWidget {
  final user_detials;
  final build_details;
  const sharedWithYou({super.key, this.user_detials, this.build_details});

  @override
  State<sharedWithYou> createState() => _sharedWithYouState();
}

class _sharedWithYouState extends State<sharedWithYou> {
  Stream getPublicComplaints() {
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.build_details.id)
        .collection('complaints')
        .orderBy('status')
        .where('isPrivate', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.user_detials);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
      ),
      child: StreamBuilder(
        stream: getPublicComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went Wrong ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.hasData) {
            print(widget.user_detials);
            return DisplayPublicComplaints(
              buildId: widget.build_details.id,
              userId: widget.user_detials.id,
              user: widget.user_detials,
              complaints: snapshot.data!.docs,
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class DisplayPublicComplaints extends StatefulWidget {
  final complaints;
  final userId;
  final user;
  final buildId;
  const DisplayPublicComplaints(
      {super.key,
      required this.complaints,
      this.userId,
      this.user,
      this.buildId});

  @override
  State<DisplayPublicComplaints> createState() =>
      _DisplayPublicComplaintsState();
}

class _DisplayPublicComplaintsState extends State<DisplayPublicComplaints> {
  final List<Map<String, dynamic>> statusUI = [
    {
      'text': 'Sent to Secretary',
      'color': Colors.grey,
    },
    {
      'text': 'Seen by Secretary',
      'color': Colors.blue,
    },
    {
      'text': 'Working on it',
      'color': Colors.green,
    },
    {
      'text': 'Issue resolved',
      'color': Colors.pinkAccent,
    },
  ];

  Future<void> addUpVote({required String docId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildId)
          .collection('complaints')
          .doc(docId)
          .update({
        'upvotes': FieldValue.arrayUnion([widget.userId]),
        'devotes': FieldValue.arrayRemove([widget.userId]),
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> addDeVote({required String docId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildId)
          .collection('complaints')
          .doc(docId)
          .update({
        'upvotes': FieldValue.arrayRemove([widget.userId]),
        'devotes': FieldValue.arrayUnion([widget.userId]),
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateStatus({required String docId}) async {
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.buildId)
        .collection('complaints')
        .doc(docId)
        .update({'status': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.complaints.isEmpty) {
      return const Center(
        child: Text(
          'No complaints found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.complaints.length,
      itemBuilder: (context, index) {
        final complaint = widget.complaints[index];
        final bool statusEnabled = complaint['status'] < 3;
        print(widget.user);
        print(widget.userId);
        DateTime addedAt = complaint['addedAt'].toDate();
        String formattedDate = DateFormat('dd MMM, yyyy').format(addedAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      complaint['owner'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusUI[complaint['status']]['color']
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: statusUI[complaint['status']]['color']),
                      ),
                      child: Text(
                        statusUI[complaint['status']]['text'],
                        style: TextStyle(
                          color: statusUI[complaint['status']]['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  complaint['subject'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  complaint['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (complaint['images'].isNotEmpty)
                  Container(
                    height: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: complaint['images'].length,
                      itemBuilder: (context, imageIndex) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    leading: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  body: Container(
                                    color: Colors.black,
                                    child: Center(
                                      child: InteractiveViewer(
                                        child: Image.network(
                                          complaint['images'][imageIndex],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    complaint['images'][imageIndex],
                                    height: 200,
                                    width: 300,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        width: 300,
                                        color: Colors.white.withOpacity(0.1),
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        width: 300,
                                        color: Colors.grey[800],
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 48,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Failed to load image',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${imageIndex + 1}/${complaint['images'].length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => addUpVote(docId: complaint.id),
                          child: const Icon(
                            Icons.thumb_up,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          complaint['upvotes'].length.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => addDeVote(docId: complaint.id),
                          child: const Icon(
                            Icons.thumb_down,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          complaint['devotes'].length.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (widget.user['designation'] == 4)
                      if (statusEnabled)
                        TextButton(
                          onPressed: () => updateStatus(docId: complaint.id),
                          style: TextButton.styleFrom(
                            backgroundColor: statusUI[complaint['status']]
                                    ['color']
                                .withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Update Status',
                            style: TextStyle(
                              color: statusUI[complaint['status']]['color'],
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Added on $formattedDate",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: complaint['isPrivate']
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: complaint['isPrivate']
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                      child: Text(
                        complaint['isPrivate'] ? "Private" : "Public",
                        style: TextStyle(
                          color: complaint['isPrivate']
                              ? Colors.blue
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class yourComplaints extends StatefulWidget {
  final user_detials;
  final build_details;
  const yourComplaints({super.key, this.user_detials, this.build_details});

  @override
  State<yourComplaints> createState() => _yourComplaintsState();
}

class _yourComplaintsState extends State<yourComplaints> {
  Stream getOwnComplaints() {
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.build_details.id)
        .collection('complaints')
        .where('owner_id', isEqualTo: widget.user_detials.id)
        .orderBy('status')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
      ),
      child: Stack(
        children: [
          StreamBuilder(
            stream: getOwnComplaints(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Something went Wrong ${snapshot.error}",
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (snapshot.hasData) {
                return DisplayPublicComplaints(
                  buildId: widget.build_details.id,
                  userId: widget.user_detials.id,
                  user: widget.user_detials,
                  complaints: snapshot.data!.docs,
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ],
      ),
    );
  }
}
