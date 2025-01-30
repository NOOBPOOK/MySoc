import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ChooseLocation extends StatefulWidget {
  const ChooseLocation({super.key});

  @override
  State<ChooseLocation> createState() => _ChooseLocationState();
}

class _ChooseLocationState extends State<ChooseLocation> {
  LatLng current_location = LatLng(37.49, -122.45);
  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  bool isLoading = true;
  List buildMaps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get all the verified buildings in the database
      Map args = ModalRoute.of(context)!.settings.arguments as Map;
      current_location = args['location'];
      QuerySnapshot buildings =
          await FirebaseFirestore.instance.collection('buildings').get();
      buildMaps = buildings.docs;
      isLoading = false;
      setState(() {});
    });
  }

  void movePointer(LatLng newPosition, Set<Marker> _markers) {
    setState(() {
      current_location = newPosition;
    });
    // CameraToPointer(newPosition);
  }

  void CameraToPointer(LatLng location) async {
    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            bearing: 00.00, target: location, zoom: 15, tilt: 59.00)));
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1 = point1.latitude * (3.14159265359 / 180);
    final double lat2 = point2.latitude * (3.14159265359 / 180);
    final double deltaLat =
        (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLng =
        (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = (sin(deltaLat / 2) * sin(deltaLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in meters
  }

  bool checkCloseness(Set<Marker> _markers) {
    for (Marker marker in _markers) {
      if (marker.markerId != MarkerId('selected-location')) {
        if (_calculateDistance(current_location, marker.position) <= 20) {
          print(marker.infoWindow.title);
          return false;
        }
      }
    }
    return true;
  }

  void getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission ask = await Geolocator.requestPermission();
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition();

      setState(() {
        current_location =
            LatLng(currentPosition.latitude, currentPosition.longitude);
      });
      CameraToPointer(
          LatLng(currentPosition.latitude, currentPosition.longitude));
    }
  }

  @override
  Widget build(BuildContext context) {
    late Set<Marker> _markers = {};

    for (int i = 0; i < buildMaps.length; i++) {
      GeoPoint geopoint = buildMaps[i]['location'];
      LatLng location = LatLng(geopoint.latitude, geopoint.longitude);
      String status = 'Pending';
      if (buildMaps[i]['isVerified']) {
        status = 'Verified';
      }
      if (buildMaps[i]['isRejected']) {
        status = 'Rejected';
      }
      _markers.add(
        Marker(
            markerId: MarkerId('marker_$i'),
            position: location,
            infoWindow: InfoWindow(
                title: '${buildMaps[i]['buildingName']}', snippet: status)),
      );
    }
    _markers.add(Marker(
        markerId: MarkerId('selected-location'),
        position: current_location,
        infoWindow: InfoWindow(title: 'Your Building')));

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: current_location, zoom: 15),
                    mapType: MapType.satellite,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController.complete(controller);
                    },
                    onTap: (LatLng loc) {
                      movePointer(loc, _markers);
                    },
                    markers: _markers,
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                              onPressed: getCurrentLocation,
                              child: Text("Current Location")),
                          ElevatedButton(
                              onPressed: () {
                                if (checkCloseness(_markers) == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'You are too close to already registered building'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context, current_location);
                                }
                              },
                              child: Text("Confirm Location")),
                        ],
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
