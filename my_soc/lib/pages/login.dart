import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:my_soc/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String name = "";
  bool islogin = false;
  final _formKey = GlobalKey<FormState>();
  String customMsg = "";

  final TextEditingController user_email_controller = TextEditingController();
  final TextEditingController user_password_controller =
      TextEditingController();

  Future<void> loginUserAcoount() async {
    try {
      final userCreds = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user_email_controller.text.trim(),
          password: user_password_controller.text.trim());
      customMsg = userCreds.toString();
      print(userCreds);
      setState(() {});
    } on FirebaseAuthException catch (e) {
      // This message is to be displayed on the screen as a popup incase of some errors
      customMsg = e.message.toString();
      print(e.message);
      setState(() {});
    }
    // if (_formKey.currentState!.validate()) {
    //   setState(() {
    //     islogin = true;
    //   });
    // await Future.delayed(Duration(seconds: 1));
    // await Navigator.pushNamed(context, MyRoutes.homeRoute);
    // setState(() {
    //   islogin = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: user_email_controller,
                    decoration: InputDecoration(
                      hintText: islogin ? name : "Enter Username",
                      enabled: islogin ? false : true,
                      labelText: "Username",
                    ),
                    onChanged: (value) {
                      name = value;
                      setState(() {});
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
                    enabled: islogin ? false : true,
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
                      await loginUserAcoount();
                    },
                    style: TextButton.styleFrom(
                        minimumSize: const Size(120, 40),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    child: islogin
                        ? const Icon(Icons.done, color: Colors.white)
                        : const Text("Login with email"),
                  ),
                  Text(customMsg),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}