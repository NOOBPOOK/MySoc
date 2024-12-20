import 'package:flutter/material.dart';
import 'package:my_soc/firebase_options.dart';
import 'package:my_soc/pages/login.dart';
import 'package:my_soc/pages/signup.dart';
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
        initialRoute: MySocRoutes.signupRoute,
        routes: {
          MySocRoutes.signupRoute: (context) => SignupPage(),
          MySocRoutes.loginRoute: (context) => LoginPage(),
        });
  }
}
