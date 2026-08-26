import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: StartScreen (Splash Screen with entrance animation)
// ---------------------------------------------------------
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Backend: Setup timers and initialize animation states
  @override
  void initState() {
    logger.d('StartScreenState: initState started');
    super.initState();

    // Entrance animation controller for the logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Zoom animation sequence: starts extremely close, zooms out to 0.85, then settles to 1.0
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.0, end: 0.85).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35.0,
      ),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Start logo zoom entrance
    _logoController.forward();

    // Start 5-second splash timer then route to destination
    Future.delayed(const Duration(seconds: 5), () {
      _checkAuthAndNavigate();
    });
    
    logger.d('StartScreenState: initState completed successfully');
  }

  // Backend: Dispose animation controllers to avoid memory leaks
  @override
  void dispose() {
    logger.d('StartScreenState: dispose started');
    _logoController.dispose();
    super.dispose();
    logger.d('StartScreenState: dispose completed successfully');
  }

  // Backend: Verify authentication state and navigate to destination
  void _checkAuthAndNavigate() {
    logger.i('StartScreenState: _checkAuthAndNavigate started');
    if (!mounted) {
      logger.w('StartScreenState: Widget not mounted, aborting navigation');
      return;
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      logger.i('StartScreenState: Active session detected for: ${currentUser.email}. Routing to Dashboard.');
      Navigator.pushReplacementNamed(context, '/userdash');
    } else {
      logger.i('StartScreenState: No active user session. Routing to Login.');
      Navigator.pushReplacementNamed(context, '/login');
    }
    logger.i('StartScreenState: _checkAuthAndNavigate completed successfully');
  }

  // UI: Build the central logo and icon column
  Widget _buildLogoColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.home_rounded,
          color: Colors.white,
          size: 72,
          shadows: [
            Shadow(
              color: Color(0x33000000), // Soft drop shadow
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          "MySoc",
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontFamily: "Readex Pro",
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Color(0x33000000), // Soft clean drop shadow
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UI: Build the bottom getting started status label
  Widget _buildGettingStartedLabel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 60,
      child: FadeTransition(
        opacity: _logoOpacity,
        child: const Center(
          child: Text(
            "Getting started...",
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0x99FFFFFF), // Clean translucent white
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.d('StartScreenState: build method triggered');
    final resultWidget = Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF222A54),
              Color.fromARGB(255, 40, 50, 100), // Dark Blue
              Color(0xFF696C9F),
              Color.fromARGB(255, 244, 131, 159), // Original pink accent
            ],
            stops: [0.15, 0.25, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Centered Logo Entrance (Scale Sequence & Fade transitions)
            Center(
              child: FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: _buildLogoColumn(),
                ),
              ),
            ),
            _buildGettingStartedLabel(),
          ],
        ),
      ),
    );
    logger.d('StartScreenState: build method execution completed');
    return resultWidget;
  }
}
