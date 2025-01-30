import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class BuildingMaps extends StatefulWidget {
  const BuildingMaps({super.key});

  @override
  State<BuildingMaps> createState() => _BuildingMapsState();
}

class _BuildingMapsState extends State<BuildingMaps> {
  List buildMaps = [];
  bool isLoading = true;
  late LatLng current_location;
  Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  late Set<Marker> _markers = {};
  String _selectedBuilding = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get all the verified buildings in the database
      Map args = ModalRoute.of(context)!.settings.arguments as Map;
      GeoPoint geoPoint = args['current'];
      _selectedBuilding = '${geoPoint.latitude}, ${geoPoint.longitude}';
      current_location = LatLng(geoPoint.latitude, geoPoint.longitude);

      QuerySnapshot buildings =
          await FirebaseFirestore.instance.collection('buildings').get();
      buildMaps = buildings.docs;

      isLoading = false;
      setState(() {});
      moveToBuilding(current_location);
    });
  }

  void movePointer(LatLng newPosition) {
    // setState(() {
    //   current_location = newPosition;
    // });
  }

  void _showInfoWindowForMarker(LatLng loc) async {
    Marker marker = _markers.firstWhere((marker) => marker.position == loc,
        orElse: () => throw Exception('No Marker found!'));
    if (marker != null && _mapController != null) {
      final GoogleMapController controller = await _mapController.future;
      controller.showMarkerInfoWindow(marker.markerId);
    }
  }

  void moveToBuilding(LatLng location) async {
    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            bearing: 00.00, target: location, zoom: 15, tilt: 59.00)));
    _showInfoWindowForMarker(location);
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      body: SafeArea(
          child: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: LatLng(0.0, 0.0), zoom: 15),
                  mapType: MapType.satellite,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  onTap: movePointer,
                  markers: _markers,
                ),
          Positioned(
            left: 0,
            top: 0,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  // height: 100,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(214, 250, 246, 1),
                    borderRadius:
                        BorderRadius.circular(15), // Makes the corners rounded
                  ),
                  width: MediaQuery.of(context).size.width - 15,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Text("View Building on Maps!"),
                      value: _selectedBuilding,
                      isExpanded:
                          true, // This will make the dropdown take all available width
                      items: buildMaps
                          .map<DropdownMenuItem<String>>((dynamic item) {
                        GeoPoint loc = item['location'];

                        return DropdownMenuItem<String>(
                          value: '${loc.latitude}, ${loc.longitude}',
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on, // Icon to show in each item
                                color: Colors.blue,
                              ),
                              SizedBox(
                                  width: 8), // Spacing between icon and text
                              Text(item['buildingName']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Split the string by comma
                        List<String> latLngParts = newValue!.split(',');

                        // Parse latitude and longitude as double values
                        double latitude = double.parse(latLngParts[0].trim());
                        double longitude = double.parse(latLngParts[1].trim());
                        _selectedBuilding = newValue;
                        moveToBuilding(LatLng(latitude, longitude));
                      },
                    ),
                  ),
                )),
          )
        ],
      )),
    );
  }
}
