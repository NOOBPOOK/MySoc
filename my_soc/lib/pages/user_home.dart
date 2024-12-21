import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:my_soc/pages/verify_email.dart';
import 'package:my_soc/routes.dart';

class UserHome extends StatefulWidget {
  // final dynamic userDetails;

  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String userDetails = "";
  // bool isEmailVerified = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser!.emailVerified != true) {
        print(FirebaseAuth.instance.currentUser);
        print("Now directed to verify the email");
        Navigator.pushNamed(context, MySocRoutes.emailVerify);
      } else {
        setState(() {
          userDetails = FirebaseAuth.instance.currentUser!.email.toString();
        });
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
        child: Material(
          child: Column(
            children: [
              const Text("Hello you are signed in"),
              Text(userDetails),
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
