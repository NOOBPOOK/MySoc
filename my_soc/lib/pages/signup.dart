import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String name = "";
  bool islogin = false;
  final _formKey = GlobalKey<FormState>();
  String customMsg = "";
  // bool isnotcreated = true;

  final TextEditingController user_email_controller = TextEditingController();
  final TextEditingController user_password_controller =
      TextEditingController();

  Future<void> createUserAccount(context) async {
    try {
      final userCreds = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: user_email_controller.text.trim(),
              password: user_password_controller.text.trim());
      customMsg = userCreds.toString();
      print("Created user account");

      // Jumping onto the Verifying Email stage
      await Future.delayed(const Duration(seconds: 3));
      await Navigator.pushNamed(context, MySocRoutes.emailVerify);
      
    } on FirebaseAuthException catch (e) {
      // This message is to be displayed on the screen as a popup incase of some errors
      customMsg = e.message.toString();
      setState(() {});
    }
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
            const Text("This is our SignUp Page",
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
                  ),
                  TextFormField(
                    controller: user_password_controller,
                    obscureText: true,
                    enabled: islogin ? false : true,
                    decoration: const InputDecoration(
                      hintText: "Enter Password",
                      labelText: "Password",
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await createUserAccount(context);
                    },
                    style: TextButton.styleFrom(
                        minimumSize: const Size(120, 40),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    child: islogin
                        ? const Icon(Icons.done, color: Colors.white)
                        : const Text("Sign Up"),
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
