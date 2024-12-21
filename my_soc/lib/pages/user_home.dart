import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/pages/verify_email.dart';

class UserHome extends StatefulWidget {
  // final dynamic userDetails;

  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String userDetails = "";
  bool isEmailVerified = true;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser!.emailVerified != true) {
      isEmailVerified = false;
    } else {
      userDetails = FirebaseAuth.instance.currentUser!.email.toString();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: isEmailVerified
            ? Column(
                children: [
                  const Text("Hello you are signed in"),
                  Text(userDetails),
                  ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        setState(() {});
                      },
                      child: const Text("Signout"))
                ],
              )
            : const VerifyEmailMessagePage(),
      ),
    );
  }
}
