import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_soc/admin/admin_login_page.dart';
import 'package:my_soc/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String customMsg = "";

  final TextEditingController user_email_controller = TextEditingController();
  final TextEditingController user_password_controller =
      TextEditingController();

  Future<void> loginUserAcoount(context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user_email_controller.text.trim(),
          password: user_password_controller.text.trim());
      await Navigator.pushNamed(context, MySocRoutes.homeRoute);
    } on FirebaseAuthException catch (e) {
      // This message is to be displayed on the screen as a popup incase of some errors
      customMsg = e.message.toString();
      print(e.message);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Material(
            child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image.asset("assets/images/login.png", fit: BoxFit.cover),
                const SizedBox(
                  height: 28.0,
                ),
                const Text("This is our Login Page",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 30.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: user_email_controller,
                        decoration: const InputDecoration(
                          hintText: "Enter Username",
                          enabled: true,
                          labelText: "Username",
                        ),
                        onChanged: (value) {
                          // name = value;
                          // setState(() {});
                        },
                        // validator: (value) {
                        //   if (value!.isEmpty) {
                        //     return "Username cannot be empty";
                        //   }
                        //   return null;
                        // },
                      ),
                      TextFormField(
                        controller: user_password_controller,
                        obscureText: true,
                        enabled: true,
                        decoration: const InputDecoration(
                          hintText: "Enter Password",
                          labelText: "Password",
                        ),
                        // validator: (value) {
                        //   if (value!.isEmpty) {
                        //     return "Password cannot be empty";
                        //   } else if (value.length < 6) {
                        //     return "The password should atleast be 6 characters";
                        //   }

                        //   return null;
                        // },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await loginUserAcoount(context);
                        },
                        style: TextButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white),
                        child: const Text("Login with email"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.signupRoute);
                        },
                        style: TextButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white),
                        child: const Text("Signup Instead"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: user_email_controller.text.trim());
                          } catch (e) {
                            setState(() {
                              customMsg = e.toString();
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                            minimumSize: const Size(120, 40),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white),
                        child: const Text("Forgot Password"),
                      ),

                      // For admin login we get
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.pushNamed(context, MySocRoutes.adminLogin);
                          },
                          child: Text("Admin Login Instead")),

                      Text(customMsg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
