import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/providers/admin_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/admin/building_details.dart';

class AdminMapsView extends ConsumerStatefulWidget {
  final String? defaultBuildingId;
  const AdminMapsView({super.key, this.defaultBuildingId});

  @override
  ConsumerState<AdminMapsView> createState() => _AdminMapsViewState();
}

class _AdminMapsViewState extends ConsumerState<AdminMapsView> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  String? _selectedBuildingId;

  // Default map center (India coords)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4.5,
  );

  @override
  void initState() {
    super.initState();
    _selectedBuildingId = widget.defaultBuildingId;
    logger.i('AdminMapsView initialized');
  }

  // Backend: Navigate camera to specific location
  Future<void> _moveToBuilding(LatLng location) async {
    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: 17, tilt: 45.0),
    ));
  }

  // Backend: Helper to extract LatLng from Firestore GeoPoint
  LatLng _getLatLng(Map<String, dynamic> data) {
    final geoPoint = data['location'] as GeoPoint?;
    if (geoPoint != null) {
      return LatLng(geoPoint.latitude, geoPoint.longitude);
    }
    return const LatLng(0, 0); // Fallback
  }

  // UI: Build Custom Markers
  Set<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final latLng = _getLatLng(data);

      // Determine marker color based on status
      double hue = BitmapDescriptor.hueOrange; // Pending
      if (data['isVerified'] == true) {
        hue = BitmapDescriptor.hueGreen;
      } else if (data['isRejected'] == true) {
        hue = BitmapDescriptor.hueRed;
      }

      return Marker(
        markerId: MarkerId(doc.id),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () {
          setState(() {
            _selectedBuildingId = doc.id;
          });
          _moveToBuilding(latLng);
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Map Layer
          buildingsAsync.when(
            data: (snapshot) {
              return GoogleMap(
                initialCameraPosition: _initialPosition,
                mapType: MapType
                    .normal, // Using normal map for cleaner UI instead of satellite
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _buildMarkers(snapshot.docs),
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);

                  // Automatically load default building or the first one
                  if (snapshot.docs.isNotEmpty) {
                    String targetId = _selectedBuildingId ?? snapshot.docs.first.id;
                    
                    try {
                      final targetDoc = snapshot.docs.firstWhere((d) => d.id == targetId);
                      final latLng = _getLatLng(targetDoc.data() as Map<String, dynamic>);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedBuildingId = targetId;
                          });
                          _moveToBuilding(latLng);
                        }
                      });
                    } catch (_) {}
                  }
                },
                onTap: (_) {
                  // Deselect building when tapping empty map space
                  if (_selectedBuildingId != null) {
                    setState(() => _selectedBuildingId = null);
                  }
                },
              );
            },
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Color(0xFF222A54)),
                  SizedBox(height: 16),
                  Text(
                    "Loading map... we will be just here!",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 16,
                      color: Color(0xFF222A54),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            error: (err, stack) =>
                Center(child: Text('Error loading maps: $err')),
          ),

          // 2. Glassmorphism Search/Dropdown (Top Overlay)
          if (widget.defaultBuildingId == null)
            _buildTopOverlay(buildingsAsync),

          // 3. Floating Bottom Card (Building Details)
          if (_selectedBuildingId != null && buildingsAsync.value != null)
            Builder(builder: (context) {
              try {
                final selectedDoc = buildingsAsync.value!.docs
                    .firstWhere((d) => d.id == _selectedBuildingId);
                final usersCount = ref
                        .watch(allUsersProvider)
                        .value
                        ?.buildingUserCounts[_selectedBuildingId] ??
                    0;
                return _buildBottomDetailCard(
                    selectedDoc.data() as Map<String, dynamic>, usersCount);
              } catch (_) {
                return const SizedBox();
              }
            }),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI: Build the Top Glassmorphism Overlay
  Widget _buildTopOverlay(AsyncValue<QuerySnapshot> buildingsAsync) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 70, // Offset for back button
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: buildingsAsync.when(
              data: (snapshot) {
                // Find currently selected building name
                String currentName = "Search or select a building...";
                if (_selectedBuildingId != null) {
                  try {
                    final doc = snapshot.docs.firstWhere((d) => d.id == _selectedBuildingId);
                    currentName = (doc.data() as Map<String, dynamic>)['buildingName'] ?? 'Unknown';
                  } catch (_) {}
                }

                return GestureDetector(
                  onTap: () => _showSearchableDropdown(context, snapshot.docs),
                  child: Container(
                    color: Colors.transparent, // Ensure hit test works on entire row
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF222A54), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentName,
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF222A54),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF222A54)),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Text("Loading...", style: TextStyle(fontFamily: "Poppins")),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  // UI: Build the sleek floating detail card at the bottom
  Widget _buildBottomDetailCard(Map<String, dynamic> data, int usersCount) {
    final buildingName = data['buildingName'] ?? 'Unknown Building';
    final flats =
        data['totalFlats']?.toString() ?? data['flats']?.toString() ?? '0';
    final usersOnline = usersCount.toString();

    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double val, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - val)),
            child: Opacity(
              opacity: val,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                buildingName,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222A54),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildInfoBadge(
                      Icons.apartment, "Flats: $flats", Colors.blue),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                      Icons.people, "Registered: $usersOnline", Colors.green),
                ],
              ),
              if (widget.defaultBuildingId == null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: const Color(0xFF222A54).withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_selectedBuildingId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuildingDetailsPage(
                              buildingId: _selectedBuildingId!,
                              buildingData: data,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "View Building Details",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        color: Color(0xFF222A54),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // UI: Helper to build information badges for the bottom card
  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // UI: Show the custom top-anchored searchable dropdown
  void _showSearchableDropdown(BuildContext context, List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // Subtle dimming
      builder: (BuildContext dialogContext) {
        return _SearchableDropdownDialog(
          docs: docs,
          onSelected: (String id) {
            Navigator.pop(dialogContext);
            setState(() => _selectedBuildingId = id);
            final selectedDoc = docs.firstWhere((d) => d.id == id);
            _moveToBuilding(_getLatLng(selectedDoc.data() as Map<String, dynamic>));
          },
        );
      },
    );
  }
}

// Backend/UI: Custom Dialog for Searchable Dropdown
class _SearchableDropdownDialog extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final Function(String) onSelected;

  const _SearchableDropdownDialog({required this.docs, required this.onSelected});

  @override
  State<_SearchableDropdownDialog> createState() => _SearchableDropdownDialogState();
}

class _SearchableDropdownDialogState extends State<_SearchableDropdownDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _filteredDocs = [];

  @override
  void initState() {
    super.initState();
    _filteredDocs = widget.docs;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDocs = widget.docs;
      } else {
        _filteredDocs = widget.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['buildingName'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 70, // Just below the glassmorphism bar
          left: 16,
          right: 16,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45, // Constrained height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sticky Search Field
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search building...",
                    hintStyle: const TextStyle(fontFamily: "Poppins", fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF222A54)),
                    ),
                  ),
                  style: const TextStyle(fontFamily: "Poppins", fontSize: 14),
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              
              // Scrollable List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = _filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['buildingName'] ?? 'Unknown';
                    
                    return InkWell(
                      onTap: () => widget.onSelected(doc.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF222A54),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Empty State
              if (_filteredDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "No buildings found matching your search.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "Poppins", color: Colors.grey, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
