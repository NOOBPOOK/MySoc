import 'package:flutter/material.dart';
import 'package:wave/wave.dart';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';

class UploadButton extends StatefulWidget {
  const UploadButton({
    super.key,
    required this.buttonHeight,
    required this.buttonWidth,
    required this.scale,
  });
  final double buttonHeight;
  final double buttonWidth;
  final double scale;

  @override
  State<UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<UploadButton> {
  late double newHeight;
  late double newWidth;
  late double newCurve;
  late double waveHeight;
  String buttonText = "Upload";

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    newHeight = widget.buttonHeight;
    newWidth = widget.buttonWidth;
    newCurve = newHeight / 2;
    waveHeight = newHeight;
  }

  static const _backgroundColor = Color(0xFFF15BB5);

  static const _colors = [
    Color(0xFF00BBF9),
  ];

  static const _durations = [
    3000,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (buttonText == 'Upload') {
              newHeight += newHeight * widget.scale / 100;
              newWidth += newWidth * widget.scale / 100;
              newCurve = newHeight / 2;
            }

            // _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
            //   setState(() {
            //     waveHeight -= 2;
            //     buttonText = "Uploading...";
            //     if (waveHeight <= 10) {
            //       buttonText = "Uploaded";
            //       waveHeight = 0;
            //       _timer.cancel();
            //     }
            //   });
            // });
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: newHeight,
          width: newWidth,
          curve: Curves.bounceOut,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(newCurve),
              color: Colors.amber),
          child: Stack(
            children: [
              if (buttonText == 'Uploading...')
                ClipRRect(
                  borderRadius: BorderRadius.circular(newCurve),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        color: Colors.amber,
                        height: waveHeight,
                      ),
                      Expanded(
                        child: WaveWidget(
                          config: CustomConfig(
                            colors: _colors,
                            durations: _durations,
                            heightPercentages: [0.05],
                          ),
                          backgroundColor: Colors.amber,
                          size: Size(double.infinity, double.infinity),
                          waveAmplitude: 0.0,
                          waveFrequency: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (buttonText == "Uploaded")
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded),
                    ),
                  Text(buttonText),
                ],
              ))
            ],
          ),
        ),
      ),
    ));
  }
}
