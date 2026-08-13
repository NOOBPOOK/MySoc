import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/pages/secretary/view_permissions.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/app_logger.dart';

// IMPORTANT NOTE
// Currently Valid Vehicle types -. ['car', 'scooter', 'bicycle']

class VehicleRegistryPage extends ConsumerStatefulWidget {
  final String buildingId;
  const VehicleRegistryPage({super.key, required this.buildingId});

  @override
  ConsumerState<VehicleRegistryPage> createState() => _VehicleRegistryPageState();
}

class _VehicleRegistryPageState extends ConsumerState<VehicleRegistryPage> {
  String _searchCriteria = 'Vehicle Number';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    logger.i('VehicleRegistryPage: initState - buildingId: ${widget.buildingId}');
  }

  @override
  void dispose() {
    logger.i('VehicleRegistryPage: dispose');
    super.dispose();
  }

  // Backend: Calculate counts for vehicles
  Map<String, int> _getVehicleCounts(List<Map<String, dynamic>> vehicles) {
    logger.d('_getVehicleCounts: Calculating counts for ${vehicles.length} vehicles');
    int carCount = 0;
    int scooterCount = 0;
    int bicycleCount = 0;

    for (var v in vehicles) {
      final type = v['type']?.toString().toLowerCase();
      if (type == 'car') {
        carCount++;
      } else if (type == 'scooter') {
        scooterCount++;
      } else if (type == 'bicycle') {
        bicycleCount++;
      }
    }
    logger.d('_getVehicleCounts: Completed (Cars: $carCount, Scooters: $scooterCount, Bicycles: $bicycleCount)');
    return {
      'car': carCount,
      'scooter': scooterCount,
      'bicycle': bicycleCount,
    };
  }

  // Backend: Filter vehicles based on search criteria
  List<Map<String, dynamic>> _getFilteredVehicles(List<Map<String, dynamic>> vehicles) {
    logger.d('_getFilteredVehicles: Filtering ${vehicles.length} vehicles with criteria: $_searchCriteria, query: "$_searchQuery"');
    if (_searchQuery.trim().isEmpty) {
      return vehicles;
    }

    final query = _searchQuery.trim().toLowerCase();
    final filtered = vehicles.where((v) {
      if (_searchCriteria == 'Vehicle Number') {
        return (v['number'] ?? '').toString().toLowerCase().contains(query);
      } else if (_searchCriteria == 'OwnerName') {
        return (v['ownerName'] ?? '').toString().toLowerCase().contains(query);
      } else if (_searchCriteria == 'FlatNumber') {
        final combinedFlat = '${v['wing']}-${v['flatNumber']}'.toLowerCase();
        final combinedFlatSpace = '${v['wing']} ${v['flatNumber']}'.toLowerCase();
        final flat = (v['flatNumber'] ?? '').toString().toLowerCase();
        final wing = (v['wing'] ?? '').toString().toLowerCase();
        return combinedFlat.contains(query) ||
               combinedFlatSpace.contains(query) ||
               flat.contains(query) ||
               wing.contains(query);
      }
      return true;
    }).toList();
    
    logger.i('_getFilteredVehicles: Result count: ${filtered.length}');
    return filtered;
  }

  // Backend: Handle search query change
  void _onSearchQueryChanged(String value) {
    logger.d('_onSearchQueryChanged: $value');
    setState(() {
      _searchQuery = value;
    });
  }

  // Backend: Handle search criteria change
  void _onSearchCriteriaChanged(String value) {
    logger.i('_onSearchCriteriaChanged: criteria changed to $value');
    setState(() {
      _searchCriteria = value;
    });
  }

  // UI: Build the main AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 62.0,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF222A54), width: 2.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF222A54)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        "Vehicle Registry",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w700,
          fontSize: 25,
          color: Color(0xFF222A54),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            logger.i('Language change triggered');
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // UI: Build the search section (search bar + filter dropdown)
  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: _onSearchQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search by ${_searchCriteria == 'OwnerName' ? 'Owner Name' : _searchCriteria == 'FlatNumber' ? 'Flat Number' : 'Vehicle Number'}...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF222A54)),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF222A54),
            borderRadius: BorderRadius.circular(56),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF222A54).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _searchCriteria,
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            tooltip: "Filter Search",
            onSelected: _onSearchCriteriaChanged,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Vehicle Number',
                child: Text('Vehicle Number',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _searchCriteria == 'Vehicle Number' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _searchCriteria == 'Vehicle Number' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'OwnerName',
                child: Text('Owner Name',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _searchCriteria == 'OwnerName' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _searchCriteria == 'OwnerName' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              PopupMenuItem<String>(
                value: 'FlatNumber',
                child: Text('Flat Number',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: _searchCriteria == 'FlatNumber' ? const Color(0xFF222A54) : Colors.black87,
                      fontWeight: _searchCriteria == 'FlatNumber' ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // UI: Build the filtered list view
  Widget _buildVehicleList(List<Map<String, dynamic>> filteredVehicles) {
    return Expanded(
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 24, top: 6),
          itemCount: filteredVehicles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return VehicleCard(vehicle: filteredVehicles[index]);
          },
        ),
      ),
    );
  }

  // UI: Build the successful data state
  Widget _buildDataState(List<Map<String, dynamic>> allVehicles) {
    final counts = _getVehicleCounts(allVehicles);
    final filteredVehicles = _getFilteredVehicles(allVehicles);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: VehicleCountCard(
                  title: 'Cars',
                  count: counts['car'].toString(),
                  color: const Color(0xFF222A54),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VehicleCountCard(
                  title: 'Scooters',
                  count: counts['scooter'].toString(),
                  color: const Color(0xFF222A54),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VehicleCountCard(
                  title: 'Bicycles',
                  count: counts['bicycle'].toString(),
                  color: const Color(0xFF222A54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchSection(),
          const SizedBox(height: 12),
          _buildVehicleList(filteredVehicles),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(buildingVehiclesProvider(widget.buildingId));

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF222A54))),
        error: (err, stack) => Center(child: Text("Error loading vehicles: $err", style: const TextStyle(color: Colors.red))),
        data: (vehicles) => _buildDataState(vehicles),
      ),
    );
  }
}

// Extracted independent stateless widget for Vehicle Count Card
class VehicleCountCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const VehicleCountCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted independent stateless widget for the Vehicle Card List Item
class VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleCard({
    super.key,
    required this.vehicle,
  });

  // Backend: Handle copying phone number to clipboard
  Future<void> _copyPhoneNumber(BuildContext context) async {
    final phone = vehicle['phone'];
    if (phone == null || phone == 'N/A') return;
    
    logger.i('_copyPhoneNumber: Copying $phone to clipboard');
    await Clipboard.setData(ClipboardData(text: phone.toString()));
    if (context.mounted) {
      CustomToast.show(context, type: 1, message: 'Phone number copied to clipboard!');
      logger.i('_copyPhoneNumber: Successfully copied and showed toast');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF222A54).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                vehicle['type']?.toString().toLowerCase() == 'car'
                    ? Icons.directions_car
                    : vehicle['type']?.toString().toLowerCase() == 'scooter'
                        ? Icons.two_wheeler
                        : Icons.pedal_bike,
                color: const Color(0xFF222A54),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vehicle['type']?.toString() ?? 'Unknown',
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222A54),
              ),
            ),
          ],
        ),
        title: Text(
          vehicle['number'] ?? 'Unknown',
          style: const TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF222A54),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Owner: ${vehicle['ownerName']}',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Phone: ${vehicle['phone']}',
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (vehicle['phone'] != null && vehicle['phone'] != 'N/A')
                    GestureDetector(
                      onTap: () => _copyPhoneNumber(context),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF222A54),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Flat",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            Text(
              '${vehicle['wing']}-${vehicle['flatNumber']}',
              style: const TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF222A54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
