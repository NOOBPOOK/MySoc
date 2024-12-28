// This is a dashboard viewed by secretary to see the list of people waiting for verification by the building's secretary

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class SecDashboardUsers extends StatefulWidget {
  const SecDashboardUsers({super.key});

  @override
  State<SecDashboardUsers> createState() => _SecDashboardUsersState();
}

class _SecDashboardUsersState extends State<SecDashboardUsers> {
  late Map<String, dynamic> args;
  late QuerySnapshot result;
  late Map buildingData;

  Future fetchAllUsers() async {
    result = await FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: args['userDetails']['buildingId'])
        .get();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Getting user details from previous screen
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('For ${args['buildingDetails']['buildingName']}'),
      ),
      body: FutureBuilder(
          future: fetchAllUsers(),
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
              return UserTile(
                allUserData: allUsers,
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    ));
  }
}

class UserTile extends StatelessWidget {
  final List allUserData;
  const UserTile({
    super.key,
    required this.allUserData,
  });

  void detailed_view(context, DocumentSnapshot user) async {
    print(user);
    await Navigator.pushNamed(context, MySocRoutes.secDashboardUserDetails,
        arguments: {'details': user});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allUserData.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
              '${allUserData[index].data()['firstName']} ${allUserData[index].data()['lastName']}'),
          subtitle: Text(allUserData[index].data()['email']),
          trailing: allUserData[index].data()['isVerified']
              ? Icon(Icons.done)
              : Icon(
                  Icons.hourglass_empty,
                  color: Colors.grey,
                ),
          onTap: () {
            detailed_view(context, allUserData[index]);
          },
        );
      },
    );
  }
}

class SecDashboardUserDetails extends StatefulWidget {
  const SecDashboardUserDetails({super.key});

  @override
  State<SecDashboardUserDetails> createState() =>
      _SecDashboardUserDetailsState();
}

class _SecDashboardUserDetailsState extends State<SecDashboardUserDetails> {
  bool isSwitched = false;
  TextEditingController remarks = TextEditingController();
  late Map args;
  bool isloading = true;
  late Map arg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      arg = ModalRoute.of(context)!.settings.arguments as Map;
      args = arg['details'].data();
      isSwitched = args['isVerified'];
      setState(() {
        isloading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? CircularProgressIndicator()
        : SafeArea(
            child: Scaffold(
            body: Column(
              children: [
                // For First Name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("First Name"), Text(args['firstName'])],
                  ),
                ),
                // For last name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("Last Name"), Text(args['lastName'])],
                  ),
                ),
                // For Email Id
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("Email Id"), Text(args['email'])],
                  ),
                ),
                // For Contactt Number
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("Phone Number"), Text(args['phone'])],
                  ),
                ),
                // For Aadhar Card
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [
                      Text("Aadhaar Card"),
                      Text(args['aadharNumber'])
                    ],
                  ),
                ),

                // For Flat and fmaily Information
                SizedBox(
                  height: 20,
                ),
                // For flat number
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("Flat Number"), Text(args['flatNumber'])],
                  ),
                ),
                // For Floor Number
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [
                      Text("Floor Number"),
                      Text(args['floorNumber'].toString())
                    ],
                  ),
                ),
                // For Wing Within Building
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10.0,
                    children: [Text("Wing"), Text(args['wing'])],
                  ),
                ),
                Expanded(
                    child: // For vehicles information
                        ListView.builder(
                            itemCount: args['vehicles'].length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(args['vehicles'][index]['type']),
                                subtitle:
                                    Text(args['vehicles'][index]['number']),
                              );
                            })),
                // Switch for approving the user
                Expanded(
                    child: TextField(
                  controller: remarks,
                  decoration: InputDecoration(
                    labelText: "Any Remarks or Discripancies",
                  ),
                )),
                Switch(
                    value: isSwitched,
                    onChanged: (value) async {
                      // print(value);
                      setState(() {
                        isSwitched = value;
                      });
                      print(args['_id']);
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(arg['details'].id)
                          .update({
                        'isVerified': value,
                        'verifiedBy': value
                            ? FirebaseAuth.instance.currentUser?.email
                            : "",
                        'lastUpdated': FieldValue.serverTimestamp()
                        // Also call the function which sends email out for the information
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: Duration(seconds: 3),
                          content: value
                              ? Text('User will be notified about his approval')
                              : Text(
                                  'User will be notified about his rejection'),
                          backgroundColor: value ? Colors.green : Colors.red,
                        ),
                      );
                      Future.delayed(Duration(seconds: 3), () async {
                        Navigator.pop(context);
                      });
                    })
              ],
            ),
          ));
  }
}
