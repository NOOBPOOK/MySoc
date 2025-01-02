// This page is displayed after email verification is done for either registering your building or your own flat

import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';

class ChooserPage extends StatelessWidget {
  const ChooserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        ElevatedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, MySocRoutes.buildingForm);
            },
            child: Text("Register Building")),
        ElevatedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, MySocRoutes.userForm);
            },
            child: Text("Register Flat"))
      ],
    ));
  }
}
