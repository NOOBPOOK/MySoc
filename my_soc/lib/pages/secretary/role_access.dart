// On this page secretary can choose Chairperson, Treasurer and much more important people
// This page by default assumes that a secretary is using this page

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class RoleAccessPage extends StatefulWidget {
  const RoleAccessPage({super.key});

  @override
  State<RoleAccessPage> createState() => _RoleAccessPageState();
}

class _RoleAccessPageState extends State<RoleAccessPage> {
  bool isloading = true;
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  Stream fetch_all_users() {
    // Bring only verified users as well
    return FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: user_details['buildingId'])
        .where('isVerified', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];
    return SafeArea(
        child: StreamBuilder(
            stream: fetch_all_users(),
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
                List allUsers = snapshot.data!.docs;
                return Stack(
                  children: [
                    Container(
                      child: ChooseTable(
                        allUserData: allUsers,
                      ),
                    ),
                    Positioned(
                        right: 0,
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                  MySocRoutes.secRoleBasedAccess,
                                  arguments: {
                                    'userDetails': user_details,
                                    'buildingDetails': build_details
                                  });
                            },
                            child: Text("Reload")))
                  ],
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }));
  }
}

class ChooseTable extends StatefulWidget {
  final allUserData;
  const ChooseTable({super.key, required this.allUserData});

  @override
  State<ChooseTable> createState() => _ChooseTableState();
}

class _ChooseTableState extends State<ChooseTable> {
  String currentChairpersonName = "None";
  String currentTreasurerName = "None";
  Set currentMember = {};

  Color chairColor = Colors.orange;
  Color secColor = Colors.yellow;
  Color treColor = Colors.green;
  Color memColor = Colors.grey;

  var chooseState = 1;

  @override
  void initState() {
    super.initState();
    var data;
    for (data in widget.allUserData) {
      if (data['designation'] == 3) {
        currentChairpersonName = '${data['firstName']} ${data['lastName']}';
      }
      if (data['designation'] == 2) {
        currentTreasurerName = '${data['firstName']} ${data['lastName']}';
      }
      if (data['designation'] == 1) {
        currentMember.add('${data['firstName']} ${data['lastName']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            // For displaying existing Chairperson
            Row(
              spacing: 20,
              children: [
                Text("ChairPerson"),
                Text(currentChairpersonName),
              ],
            ),
            // For displaying existing Treasurer
            Row(
              spacing: 20,
              children: [
                Text("Treasurer"),
                Text(currentTreasurerName),
              ],
            ),
            // For displaying existing member
            // Rashmi kindly implement view to display list of Existing members from the array. For now loosely implemented
            Row(
              spacing: 20,
              children: [
                Text("Committee Members"),
                Text(currentMember.toString()),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          chooseState = 1;
                        });
                      },
                      child: Text("Committee Members")),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          chooseState = 2;
                        });
                      },
                      child: Text("Treasurer")),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          chooseState = 3;
                        });
                      },
                      child: Text("Chairperson")),
                ],
              ),
            ),
            Text('Now selected Mode $chooseState'),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                        itemCount: widget.allUserData.length,
                        itemBuilder: (context, index) {
                          var cc = Colors.white;
                          if (widget.allUserData[index]['designation'] == 4) {
                            cc = secColor;
                          }
                          if (widget.allUserData[index]['designation'] == 3) {
                            cc = chairColor;
                          }
                          if (widget.allUserData[index]['designation'] == 2) {
                            cc = treColor;
                          }
                          if (widget.allUserData[index]['designation'] == 1) {
                            cc = memColor;
                          }

                          return ListTile(
                            onLongPress: () async {
                              try {
                                if (widget.allUserData[index]['designation'] ==
                                    4) {
                                  throw Exception(
                                      'Secretary cannot be modified');
                                }
                                // If user choose Committe Members
                                if (chooseState == 1) {
                                  if (widget.allUserData[index]
                                          ['designation'] ==
                                      1) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 0});
                                    currentMember.remove(
                                        '${widget.allUserData[index]['firstName']} ${widget.allUserData[index]['lastName']}');
                                    setState(() {});
                                    throw ("User has been removed from Committe Memers");
                                    // Can later add Snackbar for information Purposes
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 1});
                                    currentMember.add(
                                        '${widget.allUserData[index]['firstName']} ${widget.allUserData[index]['lastName']}');
                                    setState(() {});
                                  }
                                  throw ("User has been added to the Committe Memers");
                                  // Can later add Snackbar for information Purposes
                                }
                                // If user chooses Treasurer
                                if (chooseState == 2) {
                                  if (widget.allUserData[index]
                                          ['designation'] ==
                                      2) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 0});
                                    currentTreasurerName = "None";
                                    setState(() {});
                                    throw ("User has been removed from Treasurer");
                                    // Can later add Snackbar for information Purposes
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 2});
                                    currentTreasurerName =
                                        '${widget.allUserData[index]['firstName']} ${widget.allUserData[index]['lastName']}';
                                    setState(() {});
                                  }
                                  throw ("User has been added as the Treasurer");
                                  // Can later add Snackbar for information Purposes
                                }
                                // If user chooses Chairperson
                                if (chooseState == 3) {
                                  if (widget.allUserData[index]
                                          ['designation'] ==
                                      3) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 0});
                                    currentChairpersonName = "None";
                                    setState(() {});
                                    throw ("User has been removed as Chairperson");
                                    // Can later add Snackbar for information Purposes
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.allUserData[index].id)
                                        .update({'designation': 3});
                                    currentChairpersonName =
                                        '${widget.allUserData[index]['firstName']} ${widget.allUserData[index]['lastName']}';
                                    setState(() {});
                                  }
                                  throw ("User has been added as the Chairperson");
                                  // Can later add Snackbar for information Purposes
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            tileColor: cc,
                            title: Text(
                                '${widget.allUserData[index]['firstName']} ${widget.allUserData[index]['lastName']}'),
                            trailing: Text(widget.allUserData[index]['email']),
                          );
                        })),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
