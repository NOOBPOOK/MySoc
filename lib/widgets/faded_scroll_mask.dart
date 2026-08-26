import 'package:flutter/material.dart';

class FadedScrollMask extends StatelessWidget {
  final Widget child;
  final double topFadeRatio;
  final double bottomFadeRatio;

  const FadedScrollMask({
    super.key,
    required this.child,
    this.topFadeRatio = 0.05,
    this.bottomFadeRatio = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.purple,
            Colors.transparent,
            Colors.transparent,
            Colors.purple,
          ],
          stops: [
            0.0,
            topFadeRatio,
            1.0 - bottomFadeRatio,
            1.0,
          ],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: child,
    );
  }
}
