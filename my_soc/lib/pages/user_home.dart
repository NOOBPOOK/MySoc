import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  late Map UserDetails;
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

        print(userDetails.docs[0].data().runtimeType);
        UserDetails = userDetails.docs[0].data() as Map<String, dynamic>;

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
                          Navigator.pushNamed(context, MySocRoutes.loginRoute);
                        },
                        child: const Text("Signout"))
                  ],
                ),
              ),
      ),
    );
  }
}
