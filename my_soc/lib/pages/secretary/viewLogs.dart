// This page will also display records from logs who visited your house but for now Im only writing code for displaying courriers information.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class ViewRecordsCourriers extends StatefulWidget {
  const ViewRecordsCourriers({super.key});

  @override
  State<ViewRecordsCourriers> createState() => _ViewRecordsCourriersState();
}

class _ViewRecordsCourriersState extends State<ViewRecordsCourriers> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    Stream getCourriers() {
      return FirebaseFirestore.instance
          .collection('buildings')
          .doc(build_details.id)
          .collection('courriers')
          .where('flat', isEqualTo: user_details['flatNumber'])
          .where('wing', isEqualTo: user_details['wing'])
          .snapshots();
    }

    return SafeArea(
        child: Scaffold(
      body: StreamBuilder(
          stream: getCourriers(),
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
              return DisplayCourriers(
                build_data: build_details,
                courrier_data: snapshot.data!.docs,
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
    ));
  }
}

class DisplayCourriers extends StatefulWidget {
  final build_data;
  final courrier_data;
  const DisplayCourriers({super.key, this.build_data, this.courrier_data});

  @override
  State<DisplayCourriers> createState() => _DisplayCourriersState();
}

class _DisplayCourriersState extends State<DisplayCourriers> {
  _updateState({String id = ""}) {
    try {
      FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.build_data.id)
          .collection('courriers')
          .doc(id)
          .update({'status': true});
    } catch (e) {
      print("Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.courrier_data.length,
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              children: [
                Text("From : ${widget.courrier_data[index]['deliveryName']}"),
                Text(
                    "Received By :${widget.courrier_data[index]['recievedName']}"),
                Text(
                    "description :${widget.courrier_data[index]['description']}"),
                Text(
                    "Recieved By :${widget.courrier_data[index]['recievedName']}"),
                Text("Status : ${widget.courrier_data[index]['status']}"),
                if (!widget.courrier_data[index]['status'])
                  ElevatedButton(
                      onPressed: () {
                        _updateState(id: widget.courrier_data[index].id);
                      },
                      child: Icon(Icons.done)),
              ],
            ),
          );
        });
  }
}
