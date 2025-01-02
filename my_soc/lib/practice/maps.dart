// This file is just a practice implementation of google maps

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapsRender extends StatefulWidget {
  const GoogleMapsRender({super.key});

  @override
  State<GoogleMapsRender> createState() => _GoogleMapsRenderState();
}

class _GoogleMapsRenderState extends State<GoogleMapsRender> {
  LatLng current_location = LatLng(37.49, -122.45);
  late GoogleMapController _mapController;

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
    }
  }

  void movePointer(LatLng newPosition) {
    setState(() {
      current_location = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 400,
            width: 400,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: current_location, zoom: 10),
              mapType: MapType.satellite,
              onMapCreated: (controller) => _mapController = controller,
              onTap: movePointer,
              markers: {
                Marker(
                    markerId: MarkerId('selected-location'),
                    position: current_location)
              },
            ),
          ),
          ElevatedButton(
              onPressed: getCurrentLocation, child: Text("Current Location"))
        ],
      ),
    );
  }
}

