import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';
import 'package:page_transition/page_transition.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF222A54),
              Color.fromARGB(255, 40, 50, 100), // Dark Blue
              Color(0xFF696C9F),
              // Color(0xFF72547A),
              Color.fromARGB(255, 244, 131, 159),
            ],
            stops: [0.15, 0.25, 0.65, 1.0], // Control transition points
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                // width: 134,
                height: 57,
                child: Text(
                  "MySoc",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontFamily: "Readex Pro",
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Center(
                      child: GestureDetector(
                    onTap: () {
                      context.pushNamedTransition(
                          routeName: MySocRoutes.testlogin,
                          duration: Duration(milliseconds: 500),
                          type: PageTransitionType.bottomToTopJoined,
                          cc: HomeScreen());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 42.0),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Color.fromARGB(255, 45, 56, 110),
                        ),
                        child: Center(
                            child: Text(
                          "Get Started",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                              fontSize: 20),
                        )),
                      ),
                    ),
                  )),
                ))
          ],
        ),
      ),
    );
  }
}
