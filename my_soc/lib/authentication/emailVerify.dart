import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_soc/pages/login_signup/chooser.dart';
import 'package:my_soc/routes.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';

class Emailverify extends StatefulWidget {
  const Emailverify({super.key});

  @override
  State<Emailverify> createState() => _EmailverifyState();
}


class _EmailverifyState extends State<Emailverify> {
  String emailText = "Send Email";
  bool isEnabled = true;
  late Timer timer;
  int mins = 2;
  int secx = 0;
  final fomatter = NumberFormat("00");

  // For listening if the user is authorized or not
  Timer? listen;

  @override
  void dispose() {
    timer.cancel();
    listen?.cancel();
    super.dispose();
  }

  // Function which checks whether the email is verified or not
  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    var isEmailVerified =
        FirebaseAuth.instance.currentUser!.emailVerified;
    if (isEmailVerified) {
      listen?.cancel();
      Future.delayed(Duration(seconds: 2), () {
        context.pushAndRemoveUntilTransition(
            child: ChooserPage(),
            type: PageTransitionType.fade,
            predicate: (Route route) {
              return route.settings.name == '/home';
            });
      });
      // await Navigator.popAndPushNamed(context, MySocRoutes.chooserPage);
      setState(() {});
    }
  }

  // Function to send the verification email
  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      timer = Timer.periodic(
          const Duration(seconds: 3), (_) => checkEmailVerified());
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      await FirebaseAuth.instance.signOut();
      // await Navigator.pushNamed(context, MySocRoutes.signupRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
        child: SizedBox(
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              // mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 6,
                ),
                SizedBox(
                  width: double.infinity,
                  // height: MediaQuery.of(context).size.height,
                  child: Text(
                    "Verify Your Email",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 27,
                        color: Color(0xFF49548D)),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                SizedBox(
                  height: 250,
                  width: 250,
                  child: ClipOval(
                    child: Container(
                      color: Color.fromARGB(255, 220, 233, 255),
                      child: Image.asset(
                          'C:/GithubRepos/MySoc/my_soc/lib/images/emailVerify.png'),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  "A verification Email will be sent to your email address. Please check your inbox or spam folder",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF5C6699)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 60,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ElevatedButton(
                    onPressed: isEnabled
                        ? () async {
                            // print("Hello");
                            sendVerificationEmail();
                            isEnabled = false;
                            emailText = "Email Sent!";
                            timer =
                                Timer.periodic(Duration(seconds: 1), (timer) {
                              setState(() {
                                if (mins == 0 && secx == 0) {
                                  timer.cancel();
                                  emailText = "Send Email";
                                  mins = 2;
                                  secx = 0;
                                  isEnabled = true;
                                } else if (secx > 0) {
                                  secx--;
                                } else {
                                  mins--;
                                  secx = 59;
                                }
                              });
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                        disabledBackgroundColor:
                            Color.fromARGB(255, 192, 202, 254),
                        disabledForegroundColor: Color(0xFF5C6699),
                        fixedSize: Size(280, 40),
                        backgroundColor: Color(0xFF222A54)),
                    child: Text(
                      emailText,
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
                if (!isEnabled)
                  Text(
                    "Resend email in ${fomatter.format(mins)}:${fomatter.format(secx)}",
                    style: TextStyle(fontSize: 12, color: Color(0xFF49548D)),
                  ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Signout the user
                      try {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushNamed(context, MySocRoutes.loginRoute);

                        context.pushNamedTransition(
                            routeName: MySocRoutes.loginRoute,
                            type: PageTransitionType.fade,
                            duration: Duration(milliseconds: 200));
                      } catch (e) {
                        print("The error occured $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        side: BorderSide(
                          color: Color(0xFF5C6699),
                          width: 1,
                        ),
                        fixedSize: Size(280, 40),
                        backgroundColor: Colors.white),
                    child: Text(
                      "Cancel Verification",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF5C6699)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
