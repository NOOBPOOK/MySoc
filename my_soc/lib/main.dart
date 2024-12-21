import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/firebase_options.dart';
import 'package:my_soc/pages/login.dart';
import 'package:my_soc/pages/signup.dart';
import 'package:my_soc/pages/user_home.dart';
import 'package:my_soc/pages/verify_email.dart';
import 'package:my_soc/routes.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        // theme: MyThemes.lightTheme(context),
        // darkTheme: MyThemes.darkTheme(context),
        // initialRoute: MySocRoutes.signupRoute,
        home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.data != null) {
                print(snapshot.data);
                return const UserHome();
              }
              print("Called");
              print(snapshot.data);
              return const LoginPage();
            }),
        routes: {
          MySocRoutes.signupRoute: (context) => const SignupPage(),
          MySocRoutes.loginRoute: (context) => const LoginPage(),
          MySocRoutes.emailVerify: (context) => const VerifyEmailMessagePage(),
          MySocRoutes.homeRoute: (context) => const UserHome(),
        });
  }
}
