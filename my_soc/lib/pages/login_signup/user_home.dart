import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/pages/login_signup/login.dart';
// import 'package:my_soc/pages/verify_email.dart';
import 'package:my_soc/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHome extends StatefulWidget {
  // final dynamic userDetails;

  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late QueryDocumentSnapshot UserDetails;
  late DocumentSnapshot buildingDetails;
  bool isLoading = true;
  // bool isEmailVerified = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        var userAuth = FirebaseAuth.instance.currentUser!;
        if (userAuth.emailVerified != true) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.emailVerify, (route) => false);
          });
          throw Exception('Please verify your email first');
        }

        QuerySnapshot userDetails = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userAuth.email.toString())
            .get();

        if (userDetails.docs.isEmpty) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.chooserPage, (route) => false);
          });

          throw Exception(
              'Please create register your flat first before going ahead');
        }

        UserDetails = userDetails.docs[0];

        DocumentSnapshot building_details = await FirebaseFirestore.instance
            .collection('buildings')
            .doc(UserDetails['buildingId'])
            .get();
        buildingDetails = building_details;

        if (UserDetails['isVerified'] == false) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.loginRoute, (route) => false);
          });

          throw Exception(
              'Your account is yet to be verified. We will inform shortly');
        }

        setState(() {
          isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Material(
                child: Column(
                  children: [
                    const Text("Hello you are signed in"),
                    Text(
                        'Welcome to the homepage ${UserDetails['firstName']}!'),
                    ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (route) => false,
                          );
                        },
                        child: const Text("Signout")),

                    // For testing adding secretary dashboard. In real case we need to only display this option for isSecretary fields == true people
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.secDashboardUsers,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Secretary Dashboard")),

                    // For testing role based access allocation by secreatart. Exclusive for only secretary
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.secRoleBasedAccess,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Assign Roles and Designations!")),

                    // For testing adding services by secretary, chairman and treasurer. Pls apply checks for designation before calling
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.addServices,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Add Services Information")),

                    // For testing adding complaints from Secretary. Pls apply checks for designation before calling
                    // For testing adding services by secretary, chairman and treasurer. Pls apply checks for designation before calling
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.complaints,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Complaints/Suggestions")),

                    // For testing we are assuming that you are previliged user with atleast treasurer, secretary and chairman perms
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.announcements,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Announcements")),

                    // For testing we are assuming that you are previliged user with atleast treasurer, secretary and chairman perms for applying fines
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.penalties,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Penalties"))
                  ],
                ),
              ),
      ),
    );
  }
}
