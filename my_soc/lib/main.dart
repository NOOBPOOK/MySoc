// ignore_for_file: must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/admin/admin_dashboard.dart';
import 'package:my_soc/admin/admin_login_page.dart';
import 'package:my_soc/firebase_options.dart';
import 'package:my_soc/pages/login_signup/buildingFom.dart';
import 'package:my_soc/pages/login_signup/chooser.dart';
import 'package:my_soc/pages/login_signup/login.dart';
import 'package:my_soc/pages/secretary/announcements.dart';
import 'package:my_soc/pages/secretary/penalties.dart';
import 'package:my_soc/practice/maps.dart';
import 'package:my_soc/practice/practice_images.dart';
import 'package:my_soc/pages/secretary/add_complaints.dart';
import 'package:my_soc/pages/secretary/complaints.dart';
import 'package:my_soc/pages/secretary/services_add.dart';
import 'package:my_soc/pages/secretary/role_access.dart';
import 'package:my_soc/pages/secretary/sec_building_users.dart';
import 'package:my_soc/pages/login_signup/signup.dart';
import 'package:my_soc/pages/login_signup/userForm.dart';
import 'package:my_soc/pages/login_signup/user_home.dart';
import 'package:my_soc/pages/login_signup/verify_email.dart';
import 'package:my_soc/practice/practice.dart';
import 'package:my_soc/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load the .env file
  await dotenv.load(fileName: "C:/GithubRepos/MySoc/my_soc/.env");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  bool userExists = false;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      userExists = true;
    }

    print("Main root file was executed");
    print(userExists);

    return MaterialApp(
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        // theme: MyThemes.lightTheme(context),
        // darkTheme: MyThemes.darkTheme(context),
        // initialRoute: MySocRoutes.signupRoute,
        home: SafeArea(child: userExists ? UserHome() : LoginPage()),
        routes: {
          MySocRoutes.signupRoute: (context) => const SignupPage(),
          MySocRoutes.loginRoute: (context) => const LoginPage(),
          MySocRoutes.emailVerify: (context) => const VerifyEmailMessagePage(),
          MySocRoutes.homeRoute: (context) => const UserHome(),
          MySocRoutes.buildingForm: (context) =>
              const BuildingRegistrationPage(),
          MySocRoutes.userForm: (context) => UserRegistrationPage(),
          MySocRoutes.chooserPage: (context) => const ChooserPage(),
          MySocRoutes.secDashboardUsers: (context) => SecDashboardUsers(),
          MySocRoutes.secDashboardUserDetails: (context) =>
              SecDashboardUserDetails(),
          MySocRoutes.secRoleBasedAccess: (context) => RoleAccessPage(),
          MySocRoutes.addServices: (context) => AddServices(),
          MySocRoutes.complaints: (context) => ComplaintsPage(),
          MySocRoutes.addComplaints: (context) => AddComplaints(),
          MySocRoutes.adminDashboard: (context) => AdminDashboard(),
          MySocRoutes.adminLogin: (context) => AdminLoginPage(),
          MySocRoutes.announcements: (context) => AnnouncementsPage(),
          MySocRoutes.penalties: (context) => PenaltiesPage(),
        });
  }
}
