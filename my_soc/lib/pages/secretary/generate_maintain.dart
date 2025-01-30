import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CreateMaintain extends StatefulWidget {
  const CreateMaintain({super.key});

  @override
  State<CreateMaintain> createState() => _CreateMaintainState();
}

class _CreateMaintainState extends State<CreateMaintain> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  DateTime? dueDate;
  List charges = [];
  List controllers = [];

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Maintain'),
      ),
      body: Column(
        children: <Widget>[
          Text("From Month"),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(startDate == null
                      ? 'Start Date'
                      : DateFormat('dd/MM/yyyy').format(startDate!)),
                  leading: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 120)),
                      firstDate: DateTime.now().subtract(Duration(days: 120)),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          Text("To Month"),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(endDate == null
                      ? 'End Date'
                      : DateFormat('dd/MM/yyyy').format(endDate!)),
                  leading: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate.add(Duration(days: 1)),
                      lastDate: DateTime.now().add(Duration(days: 90)),
                      firstDate: DateTime.now().subtract(Duration(days: 120)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          Text("Due Date for Payment"),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(dueDate == null
                      ? 'End Date'
                      : DateFormat('dd/MM/yyyy').format(dueDate!)),
                  leading: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 90)),
                    );
                    if (date != null) {
                      setState(() => dueDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Text("Maintainenance Charges"),
          // TextField(
          //   decoration: InputDecoration(
          //     hintText: 'Enter Maintainenance Charges',
          //   ),
          //   controller: maintainChargesController,
          // ),
          Text("Parking charges will added automaitcally"),
          ...charges,
          ElevatedButton(
              onPressed: () {
                setState(() {
                  // For adding Key
                  TextEditingController controller = TextEditingController();
                  controllers.add(controller);

                  // For adding Value
                  TextEditingController valueController =
                      TextEditingController();
                  controllers.add(valueController);

                  charges.add(Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Enter Key Name',
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: valueController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter Value Name',
                          ),
                        ),
                      ),
                    ],
                  ));
                });
              },
              child: Text('Add Charges')),
          // This is the final submit button of our maintain creation
          ElevatedButton(
              onPressed: () async {
                // First check if dates are selected and valid
                if (startDate.isBefore(endDate)) {
                  final url =
                      Uri.parse("http://192.168.29.138:3000/maintainenace");

                  try {
                    Map<String, String> headers = {
                      'Content-Type': 'application/json',
                    };

                    // Convert controllers to Map
                    final chargesMap = {};

                    for (int i = 0; i < controllers.length; i += 2) {
                      chargesMap[controllers[i].text.trim()] =
                          controllers[i + 1].text.trim();
                    }

                    print(chargesMap);

                    String jsonBody = jsonEncode({
                      'buildingName': build_details['buildingName'],
                      'buildingId': build_details.id,
                      'secId': user_details.id,
                      'startDate': startDate.toIso8601String(),
                      'endDate': endDate.toIso8601String(),
                      'dueDate': dueDate!.toIso8601String(),
                      'charges': chargesMap,
                    });

                    http.post(url, headers: headers, body: jsonBody);

                    // This is just a promise that the maintainenance would be created without issue
                    // We are not checking the response from the server
                    // Whether PDF task has created or not will notified later using a notification

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'You will be notified about the Maintainenace approval'),
                    ));
                  } catch (e) {
                    print(e.toString());
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error in creating Maintain'),
                    ));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('End Date should be after Start Date'),
                  ));
                }
              },
              child: Text('Create Maintain')),
        ],
      ),
    );
  }
}
