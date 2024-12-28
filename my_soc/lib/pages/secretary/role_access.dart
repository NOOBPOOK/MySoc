// On this page secretary can choose Chairperson, Treasurer and much more important people
// This page by default assumes that a secretary is using this page

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleAccessPage extends StatefulWidget {
  const RoleAccessPage({super.key});

  @override
  State<RoleAccessPage> createState() => _RoleAccessPageState();
}

class _RoleAccessPageState extends State<RoleAccessPage> {
  bool isloading = true;
  late Map args;
  late QueryDocumentSnapshot user_details;
  late QuerySnapshot result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      args = ModalRoute.of(context)!.settings.arguments as Map;
      user_details = args['userDetails'];
      result = await FirebaseFirestore.instance
          .collection('users')
          .where('buildingId', isEqualTo: user_details['buildingId'])
          .get();
      print(result);
    });
    setState(() {
      isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: isloading
            ? CircularProgressIndicator()
            : Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text("ChairPerson"),
                    ],
                  ),
                ),
              ));
  }
}
