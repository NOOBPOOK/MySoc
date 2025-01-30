import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, MySocRoutes.adminDashboard);
              },
              child: Text("Admin Dashboard")),
          ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, MySocRoutes.adminPayments);
              },
              child: Text("Payments History"))
        ],
      )),
    );
  }
}
