import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/common/packages/viewPack.dart';
import 'package:my_soc/common/polls/polls.dart';
import 'package:my_soc/common/polls/create_polls.dart';
import 'package:my_soc/common/polls/poll_votes_page.dart';
import 'package:my_soc/common/complaints/complaints.dart';
import 'package:my_soc/admin/admin_home.dart';
import 'package:my_soc/admin/admin_payments_view.dart';
import 'package:my_soc/admin/admin_maps_view.dart';
import 'package:my_soc/authentication/emailVerify.dart';
import 'package:my_soc/authentication/signup.dart';
import 'package:my_soc/firebase_options.dart';
import 'package:my_soc/forms/buildForm.dart';
import 'package:my_soc/forms/userForm.dart';
import 'package:my_soc/pages/login_signup/buildingForm.dart';
import 'package:my_soc/pages/login_signup/chooseMap.dart';
import 'package:my_soc/pages/login_signup/chooser.dart';
import 'package:my_soc/common/announcements/announce.dart';
import 'package:my_soc/common/announcements/create_announce.dart';
import 'package:my_soc/common/verification/usersView.dart';
import 'package:my_soc/common/verification/userDetails.dart';
import 'package:my_soc/pages/secretary/generate_maintain.dart';
import 'package:my_soc/pages/secretary/maintain.dart';
import 'package:my_soc/common/penalties/manage_pens.dart';
import 'package:my_soc/common/penalties/detail_pens.dart';
import 'package:my_soc/pages/secretary/permissions_page.dart';
import 'package:my_soc/pages/secretary/view_maintain.dart';
import 'package:my_soc/pages/secretary/view_permissions.dart';
import 'package:my_soc/watchman/watch_home.dart';
import 'package:my_soc/watchman/watch_login.dart';
import 'package:my_soc/practice/maps.dart';
import 'package:my_soc/practice/practice_images.dart';
import 'package:my_soc/common/members/assign_roles.dart';
import 'package:my_soc/common/members/kysociety.dart';
import 'package:my_soc/pages/login_signup/signup.dart';
import 'package:my_soc/pages/login_signup/userForm.dart';
import 'package:my_soc/pages/login_signup/user_home.dart';
import 'package:my_soc/pages/login_signup/verify_email.dart';
import 'package:my_soc/common/security/security.dart';
import 'package:my_soc/common/security/secDetails.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_soc/authentication/login.dart';
import 'package:my_soc/authentication/start.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // Load the .env file
  await dotenv.load(fileName: "C:/GithubRepos/MySoc/my_soc/.env");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent, // Make status bar transparent as well (optional)
      systemNavigationBarColor:
          Colors.transparent, // Make navigation bar transparent
    ),
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
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
        // initialRoute: '/signup',
        // initialRoute:
        // MySocRoutes.testing, // Set the initial route to the login page
        // home: SafeArea(child: userExists ? UserHome() : LoginPage()),
        home: Login(),
        routes: {
          // '/signup': (context) => const SignupPage(),
          // '/login': (context) => const LoginPage(),
          // '/emailverify': (context) => const Emailverify(),
          '/userdash': (context) => const UserHome(),
          '/buildingForm': (context) => const BuildingRegistrationPage(),
          '/userForm': (context) => UserRegistrationPage(),
          '/choose': (context) => const ChooserPage(),
          '/kySociety': (context) => const KySocietyPage(),
          '/secRoleBasedAccess': (context) => const AssignRolesPage(),

          '/adminHome': (context) => AdminHome(),
          '/announcements': (context) => AnnouncementsPage(),
          '/createAnnouncements': (context) => const CreateAnnouncementPage(),
          '/penalties': (context) => const IssuePenaltyPage(),
          '/watchmanLogin': (context) => WatchmanLogin(),
          '/watchmanHome': (context) => WatchmanHome(),
          '/adminMaps': (context) => const AdminMapsView(),
          '/chooseLocation': (context) => ChooseLocation(),
          '/adminPayments': (context) => const AdminPaymentsView(),
          '/generatePDF': (context) => CreateMaintain(),
          '/viewMainatainenanceJob': (context) => ViewMainatainenanceJob(),
          //'/viewDocDetails': (context) => ViewAllDocDetails(),
          '/permissions': (context) => PermissionsPage(),
          '/viewPermissions': (context) => ViewPermissionsPage(),
          '/userPolls': (context) => const UserPollsPage(),
          '/userCreatePolls': (context) => const UserCreatePollsPage(),
          '/pollVotes': (context) => const PollVotesPage(),
          '/userComplaints': (context) => const ComplaintsPage(),
          '/manageUsers': (context) => const ManageUsersPage(),
          '/userDetails': (context) => const UserDetailsPage(),
          '/viewDocDetails': (context) => ViewAllDocDetails(),
          '/maintain': (context) => Maintain(),
          '/penaltyDetails': (context) => const PenaltyDetailsPage(),
          '/viewPackages': (context) => const ViewPackagesPage(),
          '/securitySettings': (context) => const BuildingSecurityPage(),
          '/securityDetails': (context) => const SecurityDetailsPage(),

          // For testing UI we will use this route
          '/home': (context) => HomeScreen(),
          '/login': (context) => Login(),
          '/signup': (context) => Signup(),
          '/emailverify': (context) => const Emailverify(),

          // Currently testing route
          '/testing': (context) => Signup(),
        });
  }
}
