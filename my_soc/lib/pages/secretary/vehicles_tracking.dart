import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({Key? key}) : super(key: key);

  @override
  _VehicleTrackingPageState createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterType = 'Vehicle Number';
  List<Map<String, dynamic>> _allVehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final QuerySnapshot buildingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('buildingId', isEqualTo: build_details.id)
          .get();

      List<Map<String, dynamic>> vehicles = [];

      for (var doc in buildingUsers.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData.containsKey('vehicles') && userData['vehicles'] is List) {
          final List<dynamic> userVehicles = userData['vehicles'];
          for (var vehicle in userVehicles) {
            if (vehicle is Map) {
              vehicles.add({
                ...vehicle as Map<String, dynamic>,
                'ownerName':
                    '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                        .trim(),
                'flatNumber': userData['flatNumber'] ?? 'N/A',
                'wing': userData['wing'] ?? 'N/A',
                'phone': userData['phone'] ?? 'N/A',
              });
            }
          }
        }
      }

      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = vehicles;
        _isLoading = false;
        _errorMessage = vehicles.isEmpty ? 'No vehicles found' : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterVehicles(String query) {
    if (query.isEmpty) {
      setState(() => _filteredVehicles = _allVehicles);
      return;
    }

    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        switch (_selectedFilterType) {
          case 'Vehicle Number':
            return vehicle['number']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
          case 'Owner Name':
            return vehicle['ownerName']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
          case 'Flat Number':
            return '${vehicle['wing']}${vehicle['flatNumber']}'
                .toLowerCase()
                .contains(query.toLowerCase());
          default:
            return true;
        }
      }).toList();
    });
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Vehicle Number', 'Owner Name', 'Flat Number']
                  .map((type) => ListTile(
                        title: Text(
                          type,
                          style: TextStyle(
                            color: _selectedFilterType == type
                                ? const Color(0xFFE94560)
                                : Colors.white,
                          ),
                        ),
                        leading: Radio<String>(
                          value: type,
                          groupValue: _selectedFilterType,
                          onChanged: (String? value) {
                            setState(() => _selectedFilterType = value!);
                            _filterVehicles(_searchController.text);
                            Navigator.pop(context);
                          },
                          activeColor: const Color(0xFFE94560),
                        ),
                        onTap: () {
                          setState(() => _selectedFilterType = type);
                          _filterVehicles(_searchController.text);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchSection(),
              _buildVehicleStats(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : AnimationLimiter(
                            child: _buildVehicleList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Column(
        children: [
          AnimatedTextKit(
            animatedTexts: [
              WavyAnimatedText(
                'Vehicle Registry',
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE94560), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search vehicles...',
                      hintStyle:
                          TextStyle(color: Colors.black.withOpacity(0.5)),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.black, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onChanged: _filterVehicles,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list,
                        color: Colors.white, size: 20),
                    onPressed: _showFilterOptions,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              'Filtering by: $_selectedFilterType',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStats() {
    final vehicleCounts = {
      'Cars': _allVehicles.where((v) => v['type'] == 'Car').length,
      'Scooters': _allVehicles.where((v) => v['type'] == 'Scooter').length,
      'Bicycles': _allVehicles.where((v) => v['type'] == 'Bicycle').length,
    };

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vehicleCounts.length,
        itemBuilder: (context, index) {
          final stat = vehicleCounts.entries.toList()[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1B3D), Color(0xFF44318D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat.key == 'Cars'
                      ? Icons.directions_car
                      : stat.key == 'Scooters'
                          ? Icons.two_wheeler
                          : Icons.pedal_bike,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  stat.value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stat.key,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _filteredVehicles[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildVehicleCard(vehicle),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () => _showVehicleDetails(vehicle),
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7B2CBF),
              const Color(0xFF7B2CBF).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2CBF).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                vehicle['type'] == 'Car'
                    ? Icons.directions_car
                    : vehicle['type'] == 'Scooter'
                        ? Icons.two_wheeler
                        : Icons.pedal_bike,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    vehicle['number'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle['wing']}-${vehicle['flatNumber']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B2CBF),
                  const Color(0xFF7B2CBF).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        vehicle['type'] == 'Car'
                            ? Icons.directions_car
                            : vehicle['type'] == 'Scooter'
                                ? Icons.two_wheeler
                                : Icons.pedal_bike,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle['number'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${vehicle['wing']}-${vehicle['flatNumber']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Owner', vehicle['ownerName']),
                _buildDetailRow('Phone', vehicle['phone']),
                _buildDetailRow('Vehicle Type', vehicle['type']),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF7B2CBF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.message, size: 20),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
