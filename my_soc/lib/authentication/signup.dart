import 'dart:math';
import 'package:my_soc/routes.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isSecured = true;
  bool userAgreement = false;

  TextEditingController username = TextEditingController();
  TextEditingController passwd = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  // Function for creating account with email and password
  Future<void> createUserAccount() async {
    try {
      final userCreds =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: username.text.trim(),
        password: passwd.text.trim(),
      );
      // customMsg = "Account created successfully!";
      print("Created user account");

      // Invoke a custom msg after dipankar's design

      await Future.delayed(const Duration(seconds: 2));

      await context.pushNamedTransition(
          routeName: MySocRoutes.emailVerify,
          type: PageTransitionType.fade,
          duration: Duration(milliseconds: 200));

      // await Navigator.pushNamed(context, MySocRoutes.emailVerify);
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      // customMsg = e.message.toString();
      // Invoke a custom msg after dipankar's design
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF222A54), Color(0xFFCE798E)],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Center(
                    child: Text(
                      "MySoc",
                      style: TextStyle(
                          fontFamily: "Readex Pro",
                          fontWeight: FontWeight.w700,
                          fontSize: 40,
                          color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 30.0, horizontal: 30.0),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          // mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Create Account",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: "Readex Pro",
                                        color: Color(0xFF222A54)),
                                  ),
                                  Text(
                                    "Your journey starts here—sign up now!",
                                    style: TextStyle(
                                        fontFamily: "Readex Pro",
                                        fontWeight: FontWeight.w300,
                                        fontSize: 14,
                                        color: Color(0xFFACACAC)),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "E-mail",
                                    style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.red),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 2),
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please enter your email";
                                          }
                                          if (!RegExp(
                                                  r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                                              .hasMatch(value)) {
                                            return "Enter a valid email";
                                          }
                                          return null;
                                        },
                                        controller: username,
                                        decoration: InputDecoration(
                                          helperText: " ",
                                          hintText: "Enter your e-mail",
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w300,
                                              fontSize: 15),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                13), // Rounded border
                                            borderSide: BorderSide(
                                                color: Color(0xFFACACAC)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            borderSide: BorderSide(
                                                color: Colors.red,
                                                width:
                                                    2), // Blue border when focused
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Password",
                                    style: TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.red),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 0),
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please enter your password";
                                          }
                                          return null;
                                        },
                                        controller: passwd,
                                        obscureText: isSecured,
                                        decoration: InputDecoration(
                                          helperText: " ",
                                          suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  isSecured = !isSecured;
                                                });
                                              },
                                              icon: Icon(isSecured
                                                  ? Icons.visibility
                                                  : Icons.visibility_off)),
                                          hintText: "Enter your password",
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w300,
                                              fontSize: 15),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                13), // Rounded border
                                            borderSide: BorderSide(
                                                color: Color(0xFFACACAC)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            borderSide: BorderSide(
                                                color: Colors.red,
                                                width:
                                                    2), // Blue border when focused
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Align(
                                  //     alignment: Alignment.topRight,
                                  //     child: Padding(
                                  //       padding: const EdgeInsets.symmetric(
                                  //           vertical: 2.0, horizontal: 8.0),
                                  //       child: Text(
                                  //         "Forgot password?",
                                  //         style: TextStyle(
                                  //             fontFamily: "Poppins",
                                  //             fontWeight: FontWeight.w600,
                                  //             fontSize: 12,
                                  //             color: Colors.red),
                                  //       ),
                                  //     ))
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Container(
                                width: double.infinity,
                                // color: Colors.red,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // For User Terms and Conditions Checkbox
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Transform.scale(
                                            scale: 0.7,
                                            child: Checkbox(
                                                activeColor: Color(0xFFACACAC),
                                                value: userAgreement,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    userAgreement = value!;
                                                  });
                                                }),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2.0),
                                          child: Text(
                                            "I agree to terms and condition of user",
                                            style: TextStyle(
                                                fontFamily: "Poppins",
                                                fontSize: 11,
                                                fontWeight: FontWeight.w300,
                                                color: Color(0xFF3F72AF)),
                                          ),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_formkey.currentState!.validate()) {
                                          if (!userAgreement) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Please agree to our terms'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } else {
                                            createUserAccount();
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          fixedSize: Size(280, 40),
                                          backgroundColor: Color(0xFF222A54)),
                                      child: Text(
                                        "Create my Account",
                                        style: TextStyle(
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Or",
                                          style: TextStyle(
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Color(0xFFACACAC)),
                                        )),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    ElevatedButton.icon(
                                      icon: Image.asset(
                                        'C:/GithubRepos/MySoc/my_soc/lib/images/google.png',
                                        height: 20,
                                      ),
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                          fixedSize: Size(280, 40),
                                          backgroundColor: Color(0xFF222A54)),
                                      label: Text(
                                        "Sign Up with Google",
                                        style: TextStyle(
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Align(
                                        alignment: Alignment.center,
                                        child: Text.rich(
                                          TextSpan(
                                            text: "Already have an account? ",
                                            style: TextStyle(
                                              fontFamily: "Poppins",
                                              color: Color.fromARGB(
                                                  255, 193, 193, 193),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                            children: [
                                              TextSpan(
                                                // Commented as it causes redundancy in application
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        Navigator.pop(context);
                                                      },
                                                text: "Login",
                                                style: TextStyle(
                                                  color: Colors
                                                      .red, // Change to your desired color
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
