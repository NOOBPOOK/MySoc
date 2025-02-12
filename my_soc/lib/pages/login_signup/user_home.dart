import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/pages/login_signup/login.dart';
import 'package:my_soc/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late QueryDocumentSnapshot userDetails;
  late DocumentSnapshot buildingDetails;
  bool isLoading = true;
  final FlutterLocalNotificationsPlugin _plugins =
      FlutterLocalNotificationsPlugin();
  late NotificationDetails platformChannelSpecifics;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final userAuth = FirebaseAuth.instance.currentUser!;
      if (!userAuth.emailVerified) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          MySocRoutes.emailVerify,
          (route) => false,
        );
        throw Exception('Please verify your email first');
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userAuth.email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          MySocRoutes.chooserPage,
          (route) => false,
        );
        throw Exception('Please register your flat first before proceeding.');
      }

      userDetails = userSnapshot.docs[0];
      buildingDetails = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(userDetails['buildingId'])
          .get();

      if (!userDetails['isVerified']) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          MySocRoutes.loginRoute,
          (route) => false,
        );
        throw Exception(
            'Your account is not verified yet. We will inform you shortly.');
      }

      // Only setup Notification if the user is truly a part of the app service
      _setupNotifications();

      setState(() => isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setupNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _plugins.initialize(initializationSettings);

    _createNotificationChannel();
    _getDeviceToken();
    _setupTokenRefreshListener();
    _setupForegroundNotification();
    _setupBackgroundNotification();
  }

  Future<void> _getDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print("Device Token: $token");
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDetails.id)
          .update({'deviceToken': token});
    } catch (e) {
      print('Error updating device token: $e');
    }
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDetails.id)
            .update({'deviceToken': newToken});
      } catch (e) {
        print('Error updating refreshed token: $e');
      }
    });
  }

  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _plugins.show(
        0,
        message.notification!.title,
        message.notification!.body,
        platformChannelSpecifics,
      );
    });
  }

  void _setupBackgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        _navigateNotification(message.data);
      }
    });
  }

  void _navigateNotification(Map<String, dynamic> data) {
    final screen = data['screen'];
    switch (screen) {
      case "courriers":
        Navigator.pushNamed(context, MySocRoutes.viewRecordsCourriers,
            arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
        break;
      case "penalties":
        Navigator.pushNamed(context, MySocRoutes.penalties, arguments: {
          'userDetails': userDetails,
          'buildingDetails': buildingDetails,
        });
        break;
      case "maintenance":
        Navigator.pushNamed(context, MySocRoutes.generatePDF, arguments: {
          'userDetails': userDetails,
          'buildingDetails': buildingDetails,
        });
        break;
    }
  }

  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'inheritance_Mysoc',
      'Har Ghar MyGhar Communist Party',
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

    await _plugins
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : AnimationLimiter(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _buildWelcomeText(),
                          const SizedBox(height: 30),
                          _buildFeatureGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return AnimatedTextKit(
      animatedTexts: [
        FadeAnimatedText(
          'Welcome, ${userDetails['firstName']}!',
          textStyle: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
      isRepeatingAnimation: false,
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildGridButton(
          label: "Sign Out",
          icon: Icons.logout,
          color: Color(0xFFE94560),
          onPressed: () async {
            try {
              // First update the device token
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userDetails.id)
                  .update({'deviceToken': ""});

              // Then sign out
              await FirebaseAuth.instance.signOut();

              // Navigate to login page
              if (mounted) {
                // Check if widget is still mounted
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            } catch (e) {
              if (mounted) {
                // Check if widget is still mounted
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        _buildGridButton(
          label: "Secretary Dashboard",
          icon: Icons.dashboard,
          color: Color(0xFF1E90FF),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.secDashboardUsers,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
        _buildGridButton(
          label: "Assign Roles",
          icon: Icons.assignment_ind,
          color: Color(0xFF32CD32),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.secRoleBasedAccess,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
        _buildGridButton(
          label: "Add Services",
          icon: Icons.add_circle_outline,
          color: Color(0xFFFFA500),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.addServices, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          label: "Complaints",
          icon: Icons.feedback,
          color: Color(0xFFFF6347),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.complaints, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          label: "Announcements",
          icon: Icons.announcement,
          color: Color(0xFF9370DB),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.announcements, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          label: "Penalties",
          icon: Icons.money_off,
          color: Color(0xFF20B2AA),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.penalties, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          label: "Watchmen",
          icon: Icons.security,
          color: Color(0xFF8B4513),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.viewWatchman, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          label: "Couriers",
          icon: Icons.local_shipping,
          color: Color(0xFF6A5ACD),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.viewRecordsCourriers,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
        _buildGridButton(
          label: "Maintenance PDF",
          icon: Icons.picture_as_pdf,
          color: Color(0xFFDAA520),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.viewMainatainenanceJob,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
        _buildGridButton(
          label: "Pay Maintenance",
          icon: Icons.payment,
          color: Color.fromARGB(255, 209, 0, 164),
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.Maintain, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          icon: Icons.assignment,
          color: Color(0xFF6A5ACD),
          label: 'Permissions',
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.permissions, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          icon: Icons.visibility,
          color: Color(0xFF6A5ACD),
          label: 'View Permissions',
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.viewPermissions,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
        _buildGridButton(
          icon: Icons.poll,
          color: Color(0xFF6A5ACD),
          label: 'Polls',
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.polls, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          icon: Icons.create,
          color: Color(0xFF6A5ACD),
          label: 'Create Polls',
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.createPolls, arguments: {
              'userDetails': userDetails,
              'buildingDetails': buildingDetails,
            });
          },
        ),
        _buildGridButton(
          icon: Icons.create,
          color: Color(0xFF6A5ACD),
          label: 'Vehicles Tracking',
          onPressed: () {
            Navigator.pushNamed(context, MySocRoutes.vehiclesTracking,
                arguments: {
                  'userDetails': userDetails,
                  'buildingDetails': buildingDetails,
                });
          },
        ),
      ],
    );
  }

  Widget _buildGridButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
