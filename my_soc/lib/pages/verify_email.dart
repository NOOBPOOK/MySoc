// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';

class VerifyEmailMessagePage extends StatefulWidget {
  const VerifyEmailMessagePage({super.key});

  @override
  State<VerifyEmailMessagePage> createState() => _VerifyEmailMessagePageState();
}

class _VerifyEmailMessagePageState extends State<VerifyEmailMessagePage> {
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified(context) async {
    await FirebaseAuth.instance.currentUser?.reload();
    var isEmailVerified =
        await FirebaseAuth.instance.currentUser!.emailVerified;
    if (isEmailVerified) {
      timer?.cancel();
      await Navigator.pushNamed(context, MySocRoutes.chooserPage);
      setState(() {});
    }
  }

  Future sendVerificationEmail(context) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      timer = Timer.periodic(
          const Duration(seconds: 3), (_) => checkEmailVerified(context));
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      await FirebaseAuth.instance.signOut();
      await Navigator.pushNamed(context, MySocRoutes.signupRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Reached the build method of the Verification Email");

    return Column(
      children: [
        const Text("Please verify your email"),
        ElevatedButton(
            onPressed: () async {
              await sendVerificationEmail(context);
            },
            child: const Text("Send Email")),
        ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, MySocRoutes.loginRoute);
            },
            child: const Text("Cancel Verification"))
      ],
    );
  }
}
