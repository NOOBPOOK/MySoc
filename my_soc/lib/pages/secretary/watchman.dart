import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/pages/secretary/add_announcements.dart';
import 'package:my_soc/pages/secretary/create_watchman.dart';
import 'package:my_soc/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class WatchmanPage extends StatefulWidget {
  const WatchmanPage({super.key});

  @override
  State<WatchmanPage> createState() => _WatchmanPageState();
}

class _WatchmanPageState extends State<WatchmanPage> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  @override
  Widget build(BuildContext context) {
    // Load the args sent from home page
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    Stream watchmen_info() {
      return FirebaseFirestore.instance
          .collection('buildings')
          .doc(build_details.id)
          .collection('watchmen')
          .snapshots();
    }

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: Stack(
            children: [
              StreamBuilder(
                stream: watchmen_info(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Something went Wrong ${snapshot.error}"),
                    );
                  }
                  if (snapshot.hasData) {
                    return DisplayWatchmen(
                      building_id: build_details.id,
                      watchmen_data: snapshot.data!,
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WatchmanForm(
                          user_data: user_details,
                          build_data: build_details,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFFE94560),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayWatchmen extends StatefulWidget {
  final watchmen_data;
  final building_id;
  const DisplayWatchmen({super.key, this.watchmen_data, this.building_id});

  @override
  State<DisplayWatchmen> createState() => _DisplayWatchmenState();
}

class _DisplayWatchmenState extends State<DisplayWatchmen> {
  Future<void> updateWatchmen({String docId = "", bool state = false}) async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.building_id)
          .collection('watchmen')
          .doc(docId)
          .update({'isDisabled': state ? false : true});
    } catch (e) {
      print(e);
      print("Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.watchmen_data.docs.length,
        itemBuilder: (context, index) {
          final ok = widget.watchmen_data.docs[index]['creation'].toDate();
          String doc = DateFormat('yyyy-MM-dd').format(ok);

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A1B3D),
                          const Color(0xFF44318D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Name: ${widget.watchmen_data.docs[index]['name']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Phone: ${widget.watchmen_data.docs[index]['phone']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Shift Timing: ${widget.watchmen_data.docs[index]['shift']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Username: ${widget.watchmen_data.docs[index]['username']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Account created: $doc",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Account created by: ${widget.watchmen_data.docs[index]['createdBy']}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                widget.watchmen_data.docs[index]['profile'],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Switch(
                              value: widget.watchmen_data.docs[index]
                                      ['isDisabled']
                                  ? false
                                  : true,
                              onChanged: (value) async {
                                await updateWatchmen(
                                  state: value,
                                  docId: widget.watchmen_data.docs[index].id,
                                );
                              },
                              activeColor: const Color(0xFFE94560),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
