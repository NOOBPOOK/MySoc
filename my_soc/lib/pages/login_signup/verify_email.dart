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

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3A8DFF), Color(0xFF8EC5FC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Please verify your email",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "A verification email has been sent to your email address. Please check your inbox or spam folder.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      await sendVerificationEmail(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF3A8DFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Resend Verification Email",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamed(context, MySocRoutes.loginRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancel Verification",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// // ignore_for_file: must_be_immutable

// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:my_soc/routes.dart';

// class VerifyEmailMessagePage extends StatefulWidget {
//   const VerifyEmailMessagePage({super.key});

//   @override
//   State<VerifyEmailMessagePage> createState() => _VerifyEmailMessagePageState();
// }

// class _VerifyEmailMessagePageState extends State<VerifyEmailMessagePage> {
//   Timer? timer;

//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }

//   Future<void> checkEmailVerified(context) async {
//     await FirebaseAuth.instance.currentUser?.reload();
//     var isEmailVerified =
//         await FirebaseAuth.instance.currentUser!.emailVerified;
//     if (isEmailVerified) {
//       timer?.cancel();
//       await Navigator.pushNamed(context, MySocRoutes.chooserPage);
//       setState(() {});
//     }
//   }

//   Future sendVerificationEmail(context) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser!;
//       await user.sendEmailVerification();
//       timer = Timer.periodic(
//           const Duration(seconds: 3), (_) => checkEmailVerified(context));
//     } on FirebaseAuthException catch (e) {
//       print(e.toString());
//       await FirebaseAuth.instance.signOut();
//       await Navigator.pushNamed(context, MySocRoutes.signupRoute);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     print("Reached the build method of the Verification Email");

//     return Column(
//       children: [
//         const Text("Please verify your email"),
//         ElevatedButton(
//             onPressed: () async {
//               await sendVerificationEmail(context);
//             },
//             child: const Text("Send Email")),
//         ElevatedButton(
//             onPressed: () {
//               FirebaseAuth.instance.signOut();
//               Navigator.pushNamed(context, MySocRoutes.loginRoute);
//             },
//             child: const Text("Cancel Verification"))
//       ],
//     );
//   }
// }
