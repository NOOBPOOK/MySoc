import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FullScreenPageView(),
  ));
}

class FullScreenPageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        itemCount: 5, // Number of pages
        controller: PageController(),
        itemBuilder: (context, index) {
          return Container(
            color: Colors.primaries[index % Colors.primaries.length], // Different color for each page
            child: Center(
              child: Text(
                "Page ${index + 1}",
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
