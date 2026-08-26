import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_soc/utils/app_logger.dart';

// ---------------------------------------------------------
// UI Component: ChooseLocation (Map selector for society location)
// ---------------------------------------------------------
class ChooseLocation extends StatefulWidget {
  const ChooseLocation({super.key});

  @override
  State<ChooseLocation> createState() => _ChooseLocationState();
}

class _ChooseLocationState extends State<ChooseLocation> {
  LatLng current_location = const LatLng(37.49, -122.45);
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  bool isLoading = true;
  List buildMaps = [];

  // Backend: Initialize data and fetch verified buildings
  @override
  void initState() {
    logger.d('ChooseLocationState: initState started');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      logger.i('ChooseLocationState: fetching buildings list from Firestore');
      try {
        QuerySnapshot buildings =
            await FirebaseFirestore.instance.collection('buildings').get();
        buildMaps = buildings.docs;
        logger.i('ChooseLocationState: successfully fetched ${buildMaps.length} buildings');
      } catch (e) {
        logger.e('ChooseLocationState: failed to fetch buildings', error: e);
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    });
    logger.d('ChooseLocationState: initState completed');
  }

  // Backend: Update selected coordinates
  void movePointer(LatLng newPosition, Set<Marker> markers) {
    logger.d('ChooseLocationState: movePointer called with position: $newPosition');
    setState(() {
      current_location = newPosition;
    });
    logger.d('ChooseLocationState: movePointer updated location state');
  }

  // Backend: Center and zoom camera on chosen coordinates
  void CameraToPointer(LatLng location) async {
    logger.d('ChooseLocationState: CameraToPointer started for: $location');
    try {
      final GoogleMapController controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              bearing: 00.00, target: location, zoom: 15, tilt: 59.00)));
      logger.d('ChooseLocationState: CameraToPointer animation complete');
    } catch (e) {
      logger.e('ChooseLocationState: CameraToPointer failed to animate camera', error: e);
    }
  }

  // Backend: Calculate distance between LatLng coords using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    logger.d('ChooseLocationState: _calculateDistance comparing $point1 with $point2');
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1 = point1.latitude * (pi / 180);
    final double lat2 = point2.latitude * (pi / 180);
    final double deltaLat =
        (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLng =
        (point2.longitude - point1.longitude) * (pi / 180);

    final double a = (sin(deltaLat / 2) * sin(deltaLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final double result = earthRadius * c;
    logger.d('ChooseLocationState: _calculateDistance result is $result meters');
    return result;
  }

  // Backend: Validate that the selected position is not too close to registered markers
  bool checkCloseness(Set<Marker> markers) {
    logger.d('ChooseLocationState: checkCloseness started');
    for (Marker marker in markers) {
      if (marker.markerId != const MarkerId('selected-location')) {
        final distance = _calculateDistance(current_location, marker.position);
        if (distance <= 20) {
          logger.w('ChooseLocationState: Too close to registered building: "${marker.infoWindow.title}" (distance: $distance meters)');
          return false;
        }
      }
    }
    logger.d('ChooseLocationState: checkCloseness check passed');
    return true;
  }

  // Backend: Obtain GPS coordinates of current device
  void getCurrentLocation() async {
    logger.i('ChooseLocationState: getCurrentLocation started');
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        logger.w('ChooseLocationState: Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable GPS on your device.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        logger.i('ChooseLocationState: Requesting geolocator permission');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        logger.w('ChooseLocationState: Location permissions were denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are required to fetch your current position.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      Position currentPosition = await Geolocator.getCurrentPosition();
      final newLoc = LatLng(currentPosition.latitude, currentPosition.longitude);
      logger.i('ChooseLocationState: Location fetched successfully: $newLoc');

      setState(() {
        current_location = newLoc;
      });
      CameraToPointer(newLoc);
    } catch (e) {
      logger.e('ChooseLocationState: Failed to get current coordinates', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get coordinates: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    logger.i('ChooseLocationState: getCurrentLocation completed');
  }

  // UI: Loading placeholder
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // UI: Google Map view wrapper
  Widget _buildGoogleMap(Set<Marker> markers) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: current_location, zoom: 15),
      mapType: MapType.satellite,
      onMapCreated: (GoogleMapController controller) {
        logger.d('ChooseLocationState: GoogleMapController hook created');
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
      onTap: (LatLng loc) {
        movePointer(loc, markers);
      },
      markers: markers,
    );
  }

  // UI: Floating overlay controller buttons
  Widget _buildControlButtons(Set<Marker> markers) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: getCurrentLocation,
              child: const Text("Current Location"),
            ),
            ElevatedButton(
              onPressed: () {
                logger.i('ChooseLocationState: Confirm location pressed');
                if (checkCloseness(markers) == false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are too close to already registered building'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  logger.i('ChooseLocationState: Selection valid, popping coordinates: $current_location');
                  Navigator.pop(context, current_location);
                }
              },
              child: const Text("Confirm Location"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.d('ChooseLocationState: build triggered');
    final Set<Marker> markers = {};

    // Map database building documents to Map markers
    for (int i = 0; i < buildMaps.length; i++) {
      try {
        final GeoPoint geopoint = buildMaps[i]['location'];
        final LatLng location = LatLng(geopoint.latitude, geopoint.longitude);
        String status = 'Pending';
        if (buildMaps[i]['isVerified'] == true) {
          status = 'Verified';
        }
        if (buildMaps[i]['isRejected'] == true) {
          status = 'Rejected';
        }
        markers.add(
          Marker(
            markerId: MarkerId('marker_$i'),
            position: location,
            infoWindow: InfoWindow(
              title: '${buildMaps[i]['buildingName']}',
              snippet: status,
            ),
          ),
        );
      } catch (e) {
        logger.e('ChooseLocationState: Failed parsing database building coordinate entry at index $i', error: e);
      }
    }
    
    // Add current selection pointer marker
    markers.add(
      Marker(
        markerId: const MarkerId('selected-location'),
        position: current_location,
        infoWindow: const InfoWindow(title: 'Your Building'),
      ),
    );

    final Widget layout = Scaffold(
      body: SafeArea(
        child: isLoading
            ? _buildLoadingIndicator()
            : Stack(
                children: [
                  _buildGoogleMap(markers),
                  _buildControlButtons(markers),
                ],
              ),
      ),
    );
    logger.d('ChooseLocationState: build completed successfully');
    return layout;
  }
}
