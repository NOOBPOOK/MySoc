import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// Component: ConnectionStatus
// ---------------------------------------------------------
class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool isConnected = false;
  StreamSubscription<List<ConnectivityResult>>? subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  // Backend: Starts listening to connectivity changes
  void _startListening() {
    logger.d('_startListening starting connectivity check');
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        setState(() => isConnected = false);
        logger.i('Connectivity changed: Offline');
      } else {
        final hasInternet = await _hasInternetConnection();
        setState(() => isConnected = hasInternet);
        logger.i(
            'Connectivity changed: ${hasInternet ? "Online" : "Offline (No Internet)"}');
      }
    });
    logger.d('_startListening completed setup');
  }

  // Backend: Stops listening to connectivity changes
  void _stopListening() {
    logger.d('_stopListening starting');
    subscription?.cancel();
    logger.d('_stopListening completed successfully');
  }

  // Backend: Checks internet access
  Future<bool> _hasInternetConnection() async {
    logger.d('_hasInternetConnection starting');
    try {
      final result = await InternetAddress.lookup('example.com');
      bool hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      logger.d('_hasInternetConnection completed with result: $hasConnection');
      return hasConnection;
    } catch (_) {
      logger.e('_hasInternetConnection failed');
      return false;
    }
  }

  // UI: Build Connection Status Indicator
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isConnected
                  ? Colors.green
                  : const Color.fromARGB(255, 201, 230, 255),
              width: 2.0,
            ),
          ),
          child: Text(
            isConnected ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
