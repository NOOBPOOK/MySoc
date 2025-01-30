import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/pages/secretary/add_announcements.dart';
import 'package:my_soc/pages/secretary/create_watchman.dart';
import 'package:my_soc/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
      body: Stack(
        children: [
          StreamBuilder(
              stream: watchmen_info(),
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
                  return DisplayWatchmen(
                    building_id: build_details.id,
                    watchmen_data: snapshot.data!,
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WatchmanForm(
                                  user_data: user_details,
                                  build_data: build_details,
                                )));
                  },
                  child: Icon(Icons.add)))
        ],
      ),
    ));
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
    print(widget.watchmen_data.docs.length);
    return ListView.builder(
        itemCount: widget.watchmen_data.docs.length,
        itemBuilder: (context, index) {
          final ok = widget.watchmen_data.docs[index]['creation'].toDate();
          String doc = DateFormat('yyyy-MM-dd').format(ok);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              // alignment: Alignment.topLeft,
              height: 200,
              width: 300,
              color: const Color.fromARGB(255, 253, 203, 251),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Name : ${widget.watchmen_data.docs[index]['name']}"),
                        Text(
                            "Phone: ${widget.watchmen_data.docs[index]['phone']}"),
                        Container(
                          width: 200,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                                "Shift Timing: ${widget.watchmen_data.docs[index]['shift']}"),
                          ),
                        ),
                        Text(
                            "username: ${widget.watchmen_data.docs[index]['username']}"),
                        Text(
                            "Phone: ${widget.watchmen_data.docs[index]['phone']}"),
                        Text("Account created: ${doc}"),
                        Container(
                          width: 200,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                                "Account created by: ${widget.watchmen_data.docs[index]['createdBy']}"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                              widget.watchmen_data.docs[index]['profile']),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Switch(
                          value: widget.watchmen_data.docs[index]['isDisabled']
                              ? false
                              : true,
                          onChanged: (value) async {
                            await updateWatchmen(
                                state: value,
                                docId: widget.watchmen_data.docs[index].id);
                          })
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}
