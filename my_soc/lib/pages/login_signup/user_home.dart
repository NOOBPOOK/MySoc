import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/main.dart';
import 'package:my_soc/pages/login_signup/login.dart';
// import 'package:my_soc/pages/verify_email.dart';
import 'package:my_soc/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UserHome extends StatefulWidget {
  // final dynamic userDetails;

  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late QueryDocumentSnapshot UserDetails;
  late DocumentSnapshot buildingDetails;
  bool isLoading = true;
  final FlutterLocalNotificationsPlugin _plugins =
      FlutterLocalNotificationsPlugin();
  late NotificationDetails platformChannelSpecifics;
  // bool isEmailVerified = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        var userAuth = FirebaseAuth.instance.currentUser!;
        if (userAuth.emailVerified != true) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.emailVerify, (route) => false);
          });
          throw Exception('Please verify your email first');
        }

        QuerySnapshot userDetails = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userAuth.email.toString())
            .get();

        if (userDetails.docs.isEmpty) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.chooserPage, (route) => false);
          });

          throw Exception(
              'Please create register your flat first before going ahead');
        }

        UserDetails = userDetails.docs[0];

        DocumentSnapshot building_details = await FirebaseFirestore.instance
            .collection('buildings')
            .doc(UserDetails['buildingId'])
            .get();
        buildingDetails = building_details;

        if (UserDetails['isVerified'] == false) {
          Future.delayed(Duration(seconds: 3), () async {
            await Navigator.pushNamedAndRemoveUntil(
                context, MySocRoutes.loginRoute, (route) => false);
          });

          throw Exception(
              'Your account is yet to be verified. We will inform shortly');
        }

        setState(() {
          isLoading = false;
        });

        // Code for handling local notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);

        await _plugins.initialize(initializationSettings);
        print("Intialization done");

        _createNotificationChannel();

        _getDeviceToken();
        _setupTokenRefreshListener();

        _setupForegroundNotification();
        _setupBackgroundNotification();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // For notification permission in the app
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not granted permission');
      }
    });
  }

  // Get the initial device token for notification purposes
  Future<void> _getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("Initial Device Token: $token");
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(UserDetails.id)
          .update({
        // For now sending token without any security compression
        'deviceToken': token
      });
    } catch (e) {
      print(e);
    }
  }

  // Set up the listener for token refresh
  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(UserDetails.id)
            .update({
          // For now sending token without any security compression
          'deviceToken': newToken
        });
      } catch (e) {
        print(e);
      }
    });
  }

  // Listen for Foreground notifications
  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Show notification in app drawer
      await _plugins.show(
        0,
        message.notification!.title,
        message.notification!.body,
        platformChannelSpecifics,
      );
    });
  }

  // Listen for Background Notification
  void _setupBackgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        _navigateNotification(message.data);
      }
    });
  }

  // Universal Notification Handler
  void _navigateNotification(data) {
    // print("This function was called");
    if (data['screen'] == "courriers") {
      Navigator.pushNamed(context, MySocRoutes.viewRecordsCourriers,
          arguments: {
            'userDetails': UserDetails,
            'buildingDetails': buildingDetails,
          });
    }
    if (data['screen'] == "penalties") {
      Navigator.pushNamed(context, MySocRoutes.penalties, arguments: {
        'userDetails': UserDetails,
        'buildingDetails': buildingDetails,
      });
    }
    if (data['screen'] == "maintainenance") {
      Navigator.pushNamed(context, MySocRoutes.generatePDF, arguments: {
        'userDetails': UserDetails,
        'buildingDetails': buildingDetails,
      });
    }
  }

  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'inheritance_Mysoc', // Replace with your desired channel ID
      'Har Ghar MyGhar Communist Party', // Replace with your desired channel name,
      description: 'Your channel description',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'inheritance_Mysoc',
      'Har Ghar MyGhar Communist Party',
      channelDescription: 'Your channel description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Create the Android channel
    await _plugins
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Material(
                child: Column(
                  children: [
                    const Text("Hello you are signed in"),
                    Text(
                        'Welcome to the homepage ${UserDetails['firstName']}!'),
                    ElevatedButton(
                        onPressed: () async {
                          // Destroying the device token after logout
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(UserDetails.id)
                              .update({'deviceToken': ""});
                          FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                            (route) => false,
                          );
                        },
                        child: const Text("Signout")),

                    // For testing adding secretary dashboard. In real case we need to only display this option for isSecretary fields == true people
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.secDashboardUsers,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Secretary Dashboard")),

                    // For testing role based access allocation by secreatart. Exclusive for only secretary
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.secRoleBasedAccess,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Assign Roles and Designations!")),

                    // For testing adding services by secretary, chairman and treasurer. Pls apply checks for designation before calling
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.addServices,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Add Services Information")),

                    // For testing adding complaints from Secretary. Pls apply checks for designation before calling
                    // For testing adding services by secretary, chairman and treasurer. Pls apply checks for designation before calling
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.complaints,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Complaints/Suggestions")),

                    // For testing we are assuming that you are previliged user with atleast treasurer, secretary and chairman perms
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.announcements,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Announcements")),

                    // For testing we are assuming that you are previliged user with atleast treasurer, secretary and chairman perms for applying fines
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.penalties,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Penalties")),

                    // For testing we are assuming that you are previliged user with atleast treasurer, secretary and chairman perms for creating watchman accounts
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.viewWatchman,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Handle Watchmans")),

                    // This will have same implementation irrespective for any account
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.viewRecordsCourriers,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("View your Courriers")),

                    // For testing we are assuming that you are previliged user with atleast treasurer
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, MySocRoutes.viewMainatainenanceJob,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("View & Generate Maintainenance PDF")),

                    // For viewing one's own maintainenance records and pdfs
                    // For testing we are assuming that you are previliged user with atleast treasurer
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, MySocRoutes.Maintain,
                              arguments: {
                                'userDetails': UserDetails,
                                'buildingDetails': buildingDetails,
                              });
                        },
                        child: Text("Pay Own Maintainenance")),
                  ],
                ),
              ),
      ),
    );
  }
}
