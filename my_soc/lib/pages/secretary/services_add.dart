// Secretary, Chairperson and Tresaurer all can add data of some technicians which might be helpful for the general bublic of the building

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class AddServices extends StatefulWidget {
  const AddServices({super.key});

  @override
  State<AddServices> createState() => _AddServicesState();
}

class _AddServicesState extends State<AddServices> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  Stream real_time_updates() {
    print(build_details.id);
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(build_details.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return SafeArea(
        child: Scaffold(
      body: StreamBuilder(
          stream: real_time_updates(),
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
              return DisplayServices(
                building_data: snapshot.data!,
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
    ));
  }
}

class DisplayServices extends StatefulWidget {
  final building_data;
  const DisplayServices({
    super.key,
    this.building_data,
  });

  @override
  State<DisplayServices> createState() => _DisplayServicesState();
}

class _DisplayServicesState extends State<DisplayServices> {
  @override
  Widget build(BuildContext context) {
    bool isZero = false;
    if (widget.building_data['services'].isEmpty) {
      isZero = true;
    }

    return Stack(
      children: [
        Scaffold(
            body: isZero
                ? Center(
                    child: Text("No services available!"),
                  )
                : ListView.builder(
                    itemCount: widget.building_data['services'].length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Name"),
                                Text(widget.building_data['services'][index]
                                    ['name'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Occuaption"),
                                Text(widget.building_data['services'][index]
                                    ['occupation'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Email"),
                                Text(widget.building_data['services'][index]
                                    ['email'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Contact Number"),
                                Text(widget.building_data['services'][index]
                                    ['contact'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Description"),
                                Text(widget.building_data['services'][index]
                                    ['description'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Added By"),
                                Text(widget.building_data['services'][index]
                                    ['addedBy'])
                              ],
                            ),
                            Row(
                              children: [
                                Text("Added At"),
                                Text(widget.building_data['services'][index]
                                        ['addedAt']
                                    .toString())
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('buildings')
                                            .doc(widget.building_data.id)
                                            .update({
                                          'services': FieldValue.arrayRemove([
                                            widget.building_data['services']
                                                [index]
                                          ])
                                        });
                                      } catch (e) {
                                        print(e);
                                      }
                                    },
                                    child: Icon(Icons.delete)),
                                ElevatedButton(
                                    onPressed: () async {
                                      addServicesPopup(
                                          context, widget.building_data,
                                          type: 1, index: index);
                                    },
                                    child: Icon(Icons.edit)),
                              ],
                            )
                          ],
                        ),
                      );
                    })),
        Positioned(
            right: 0,
            bottom: 0,
            child: ElevatedButton(
                onPressed: () {
                  addServicesPopup(context, widget.building_data);
                },
                child: Icon(Icons.add)))
      ],
    );
  }
}

void addServicesPopup(context, data, {int type = 0, int index = 0}) {
  TextEditingController nameController = TextEditingController();
  TextEditingController occupationController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController descController = TextEditingController();
  if (type == 1) {
    nameController =
        TextEditingController(text: data['services'][index]['name']);
    occupationController =
        TextEditingController(text: data['services'][index]['occupation']);
    emailController =
        TextEditingController(text: data['services'][index]['email']);
    contactController =
        TextEditingController(text: data['services'][index]['contact']);
    descController =
        TextEditingController(text: data['services'][index]['description']);
  }

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: occupationController,
                  decoration: InputDecoration(
                    labelText: 'Occupation',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (type == 1) {
                    await FirebaseFirestore.instance
                        .collection('buildings')
                        .doc(data.id)
                        .update({
                      'services':
                          FieldValue.arrayRemove([data['services'][index]])
                    });
                  }

                  await FirebaseFirestore.instance
                      .collection('buildings')
                      .doc(data.id)
                      .update({
                    'services': FieldValue.arrayUnion([
                      {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'contact': contactController.text.trim(),
                        'description': descController.text.trim(),
                        'occupation': occupationController.text.trim(),
                        'addedBy': FirebaseAuth.instance.currentUser?.email,
                        'addedAt': Timestamp.now(),
                      }
                    ])
                  });
                  throw Exception('Service has been added successfully');
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(seconds: 5),
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      });
}
