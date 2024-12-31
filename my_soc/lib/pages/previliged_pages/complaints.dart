// This page is used for viewing and take actions on user complaints
// This page by default assusmes that you are secretary for that metter

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;
  PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return SafeArea(
      child: Scaffold(
          body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(0,
                        duration: Duration(milliseconds: 100),
                        curve: Curves.linear);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 173, 253, 241),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Public \n Complaints",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(1,
                        duration: Duration(milliseconds: 100),
                        curve: Curves.linear);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 228, 110),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Shared \n with you",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(2,
                        duration: Duration(milliseconds: 100),
                        curve: Curves.linear);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 236, 161, 254),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Your\n Complaints",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              child: PageView(
                controller: _pageController,
                children: [
                  publicComplaints(
                    user_detials: user_details,
                    build_details: build_details,
                  ),
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
          )
        ],
      )),
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

  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 207, 254, 247),
      child: StreamBuilder(
          stream: getPublicComplaints(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Something went Wrong ${snapshot.error}"),
              );
            }
            if (snapshot.hasData) {
              return DisplayPublicComplaints(
                buildId: widget.build_details.id,
                userId: widget.user_detials.id,
                complaints: snapshot.data!.docs,
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
    );
  }
}

class DisplayPublicComplaints extends StatefulWidget {
  final complaints;
  final userId;
  final buildId;
  const DisplayPublicComplaints(
      {super.key, required this.complaints, this.userId, this.buildId});

  @override
  State<DisplayPublicComplaints> createState() =>
      _DisplayPublicComplaintsState();
}

class _DisplayPublicComplaintsState extends State<DisplayPublicComplaints> {
  bool isZero = false;

  List<Map> statusUI = [
    {
      'name': 'Sent to Secretary',
      'color': Colors.grey,
    },
    {
      'name': 'Seen by Secretary',
      'color': Colors.blue,
    },
    {
      'name': 'Working on it',
      'color': Colors.green,
    },
    {
      'name': 'Issue resolved',
      'color': Colors.pinkAccent,
    },
  ];

  addUpVote({var docId}) async {
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

  addDeVote({var docId}) async {
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

  updateStatus({var docId}) async {
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(widget.buildId)
        .collection('complaints')
        .doc(docId)
        .update({'status': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.complaints.length == 0) {
      isZero = true;
    }

    return Container(
        child: isZero
            ? Text("You have not made any complaints yet")
            : ListView.builder(
                itemCount: widget.complaints.length,
                itemBuilder: (context, index) {
                  bool statusEnabled = true;
                  if (widget.complaints[index]['status'] == 3) {
                    statusEnabled = false;
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.complaints[index]['owner'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.complaints[index]['subject'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.complaints[index]['description'],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => addUpVote(
                                        docId: widget.complaints[index].id),
                                    child: Icon(Icons.thumb_up,
                                        color: Colors.green, size: 20),
                                  ),
                                  SizedBox(width: 4),
                                  Text(widget
                                      .complaints[index]['upvotes'].length
                                      .toString()),
                                  SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => addDeVote(
                                        docId: widget.complaints[index].id),
                                    child: Icon(Icons.thumb_down,
                                        color: Colors.red, size: 20),
                                  ),
                                  SizedBox(width: 4),
                                  Text(widget
                                      .complaints[index]['devotes'].length
                                      .toString()),
                                ],
                              ),
                              ElevatedButton(
                                  onPressed: statusEnabled
                                      ? () => updateStatus(
                                          docId: widget.complaints[index].id)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: statusUI[
                                          widget.complaints[index]
                                              ['status']]['color']),
                                  child: Text(statusUI[widget.complaints[index]
                                      ['status']]['name'])),
                            ],
                          ),
                          Text(
                              "Raised on ${widget.complaints[index]['addedAt'].toString()}"),
                          Container(
                            color: widget.complaints[index]['isPrivate']
                                ? Colors.blue
                                : Colors.green,
                            child: Text(
                              widget.complaints[index]['isPrivate']
                                  ? "Private"
                                  : "Public",
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }));
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

  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 207, 254, 247),
      child: StreamBuilder(
          stream: getPublicComplaints(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Something went Wrong ${snapshot.error}"),
              );
            }
            if (snapshot.hasData) {
              return DisplayPublicComplaints(
                buildId: widget.build_details.id,
                userId: widget.user_detials.id,
                complaints: snapshot.data!.docs,
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
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

  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(249, 225, 255, 1),
      child: Stack(
        children: [
          StreamBuilder(
              stream: getOwnComplaints(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Something went Wrong ${snapshot.error}"),
                  );
                }
                if (snapshot.hasData) {
                  return DisplayOwnComplaints(
                    complaints: snapshot.data!.docs,
                  );
                } else {
                  return CircularProgressIndicator();
                }
              }),
          Positioned(
              right: 0,
              bottom: 0,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, MySocRoutes.addComplaints,
                        arguments: {
                          'userDetails': widget.user_detials,
                          'buildingDetails': widget.build_details,
                        });
                  },
                  child: Icon(Icons.add))),
        ],
      ),
    );
  }
}

class DisplayOwnComplaints extends StatefulWidget {
  final complaints;
  const DisplayOwnComplaints({super.key, this.complaints});

  @override
  State<DisplayOwnComplaints> createState() => _DisplayOwnComplaintsState();
}

class _DisplayOwnComplaintsState extends State<DisplayOwnComplaints> {
  bool isZero = false;

  List<Map> statusUI = [
    {
      'name': 'Sent to Secretary',
      'color': Colors.grey,
    },
    {
      'name': 'Seen by Secretary',
      'color': Colors.blue,
    },
    {
      'name': 'Working on it',
      'color': Colors.green,
    },
    {
      'name': 'Issue resolved',
      'color': Colors.pinkAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.complaints.length == 0) {
      isZero = true;
    }

    return Container(
        child: isZero
            ? Text("You have not made any complaints yet")
            : ListView.builder(
                itemCount: widget.complaints.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.complaints[index]['owner'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.complaints[index]['subject'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.complaints[index]['description'],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 4),
                                  Text(widget
                                      .complaints[index]['upvotes'].length
                                      .toString()),
                                  SizedBox(width: 16),
                                  Icon(Icons.thumb_down,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 4),
                                  Text(widget
                                      .complaints[index]['devotes'].length
                                      .toString()),
                                ],
                              ),
                              ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: statusUI[
                                          widget.complaints[index]
                                              ['status']]['color']),
                                  child: Text(statusUI[widget.complaints[index]
                                      ['status']]['name'])),
                            ],
                          ),
                          Text(
                              "Raised on ${widget.complaints[index]['addedAt'].toString()}"),
                          Container(
                            color: widget.complaints[index]['isPrivate']
                                ? Colors.blue
                                : Colors.green,
                            child: Text(
                              widget.complaints[index]['isPrivate']
                                  ? "Private"
                                  : "Public",
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }));
  }
}
