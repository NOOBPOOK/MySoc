import 'package:flutter/material.dart';

class CustomProgressBar extends StatefulWidget {
  final double progress;
  final double bar;

  const CustomProgressBar(
      {super.key, required this.progress, required this.bar});

  @override
  State<CustomProgressBar> createState() => _CustomProgressBarState();
}

class _CustomProgressBarState extends State<CustomProgressBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: double.infinity,
      child: LayoutBuilder(builder: (context, constraints) {
        // print(constraints.maxWidth / 100 * widget.progress);
        return Container(
          width: constraints.maxWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  // width: double.infinity,
                  decoration: BoxDecoration(
                      color: Color(0xFFFFE0E7),
                      borderRadius: BorderRadius.circular(10)),
                ),
                AnimatedPositioned(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                    left: 0,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: 14,
                      width: widget.bar +
                          (constraints.maxWidth / 100 * (widget.progress)),
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 154, 179),
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 6.0, right: 5.0, left: 5.0, bottom: 3.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Color.fromARGB(255, 255, 184, 202),
                          ),
                        ),
                      ),
                    ))
              ],
            ),
          ),
        );
      }),
    );
  }
}
