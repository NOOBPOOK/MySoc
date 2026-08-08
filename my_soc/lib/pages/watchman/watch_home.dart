import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

class WatchmanHome extends ConsumerStatefulWidget {
  const WatchmanHome({super.key});

  @override
  ConsumerState<WatchmanHome> createState() => _WatchmanHomeState();
}

class _WatchmanHomeState extends ConsumerState<WatchmanHome> {
  // Backend: Sign out watchman
  Future<void> _handleSignOut() async {
    logger.i('_handleSignOut starting');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pop();
    logger.i('_handleSignOut completed successfully');
  }

  // UI: Show visitor dialog
  void _showVisitorDialog() {
    showDialog(
      context: context,
      builder: (context) => const VisitorDialog(),
    );
  }

  // UI: Show courrier dialog
  void _showCourrierDialog() {
    showDialog(
      context: context,
      builder: (context) => const CourrierDialog(),
    );
  }

  // UI: Build the bottom action bar
  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      bottom: 0,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _handleSignOut,
                  child: const Text("Sign Out"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _showVisitorDialog,
                  child: const Text("Add Visitor info"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _showCourrierDialog,
                  child: const Text("Add Courier Information"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchmanState = ref.watch(watchmanProvider);
    if (watchmanState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final logsAsyncValue = ref.watch(watchmanLogsProvider);

    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: logsAsyncValue.when(
                  data: (snapshot) => DisplayRecords(logs: snapshot.docs),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) {
                    logger.e('Error loading logs: $error');
                    return Center(child: Text("Something went Wrong $error"));
                  },
                ),
              ),
              _buildBottomActionBar(),
              const ConnectionStatus(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// UI Component: VisitorDialog
// ---------------------------------------------------------
class VisitorDialog extends ConsumerStatefulWidget {
  const VisitorDialog({super.key});

  @override
  ConsumerState<VisitorDialog> createState() => _VisitorDialogState();
}

class _VisitorDialogState extends ConsumerState<VisitorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _countController =
      TextEditingController(text: "1");
  final TextEditingController _flatNumber = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _selectedWing;
  bool _forBuilding = false;
  List _wings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(watchmanProvider);
      if (state != null) {
        _wings = state.wings;
        if (_wings.isEmpty) {
          _wings = ["A", "B", "C"];
        }
        setState(() {
          _selectedWing =
              _wings[0] is Map ? _wings[0]['wingName'] : _wings[0].toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    _countController.dispose();
    _flatNumber.dispose();
    _description.dispose();
    super.dispose();
  }

  // Backend: Records visitor details to Firestore
  Future<void> _recordDetails() async {
    logger.i(
        '_recordDetails starting for name: ${_nameController.text.trim()}, forBuilding: $_forBuilding');

    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) {
      logger.e('Watchman state is null when recording visitor');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(watchmanState.buildId)
          .collection('logs')
          .add({
        'name': _nameController.text.trim(),
        'from': _fromController.text.trim(),
        'count': _countController.text.trim(),
        'forBuild': _forBuilding,
        'flat': _forBuilding ? "" : _flatNumber.text.trim(),
        'wing': _forBuilding ? "" : _selectedWing,
        'createdBy': watchmanState.watchName,
        'createdById': watchmanState.watchId,
        'timestamp': Timestamp.now(),
        'reason': _description.text.trim()
      });
      logger.i('_recordDetails completed successfully');
      if (mounted) {
        CustomToast.show(context, type: 1, message: 'Recorded successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error recording visitor details: $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: e.toString());
      }
    }
  }

  // UI: Build generic text field
  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // UI: For building maintenance checkbox
  Widget _buildForBuildingCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _forBuilding,
          onChanged: (bool? newValue) {
            setState(() {
              _forBuilding = newValue ?? false;
            });
          },
        ),
        const Text("For Building's Maintainenace",
            textScaler: TextScaler.linear(0.8))
      ],
    );
  }

  // UI: Wings and Flat selection
  Widget _buildWingAndFlatSelection() {
    if (_forBuilding || _selectedWing == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Wings"),
            ),
            DropdownButton<String>(
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              value: _selectedWing,
              icon: const Icon(Icons.apartment),
              iconSize: 24,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedWing = newValue;
                  });
                }
              },
              items: _wings.map((wing) {
                String wingName =
                    wing is Map ? wing['wingName'] : wing.toString();
                return DropdownMenuItem<String>(
                  value: wingName,
                  child: Text(wingName),
                );
              }).toList(),
            ),
          ],
        ),
        TextField(
          controller: _flatNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            constraints: BoxConstraints(maxWidth: 120),
            labelText: 'Flat Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // UI: Individual reason chip
  Widget _buildReasonChip(String label, Color color, String reasonText) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _description.text = reasonText;
        });
      },
      child: Chip(
        padding: const EdgeInsets.all(0),
        label: Text(label, textScaler: const TextScaler.linear(0.9)),
        backgroundColor: color,
      ),
    );
  }

  // UI: Quick reason chips
  Widget _buildQuickReasonChips() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 0,
          children: [
            _buildReasonChip("Swiggy", const Color.fromARGB(255, 255, 217, 114),
                "Food deleivery by Swiggy"),
            _buildReasonChip("Zomato", const Color.fromARGB(255, 255, 163, 163),
                "Food deleivery by Zomato"),
            _buildReasonChip(
                "Electrician",
                const Color.fromARGB(255, 210, 208, 205),
                "Electrician in the house"),
            _buildReasonChip("Plumber", Colors.blueAccent, "Plumber works"),
            _buildReasonChip(
                "Courriers",
                const Color.fromARGB(255, 250, 185, 168),
                "Courrier by ECommerce Websites"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add a visitor log"),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 10),
              _buildTextField(_fromController, 'From Where'),
              const SizedBox(height: 10),
              _buildTextField(_countController, 'People Count',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildForBuildingCheckbox(),
              _buildWingAndFlatSelection(),
              const SizedBox(height: 10),
              _buildQuickReasonChips(),
              _buildTextField(_description, 'Reason for Visit', maxLines: 3),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _recordDetails,
          child: const Text("Record"),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// UI Component: CourrierDialog
// ---------------------------------------------------------
class CourrierDialog extends ConsumerStatefulWidget {
  const CourrierDialog({super.key});

  @override
  ConsumerState<CourrierDialog> createState() => _CourrierDialogState();
}

class _CourrierDialogState extends ConsumerState<CourrierDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _flatNumber = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _selectedWing;
  List _wings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(watchmanProvider);
      if (state != null) {
        _wings = state.wings;
        if (_wings.isEmpty) {
          _wings = ["A", "B", "C"];
        }
        setState(() {
          _selectedWing =
              _wings[0] is Map ? _wings[0]['wingName'] : _wings[0].toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _flatNumber.dispose();
    _description.dispose();
    super.dispose();
  }

  // Backend: Sends notification to server
  Future<void> _sendNotiToServer(String buildId) async {
    logger.i('_sendNotiToServer starting for courrier buildId: $buildId');
    try {
      QuerySnapshot notifiedUser = await FirebaseFirestore.instance
          .collection('users')
          .where('buildingId', isEqualTo: buildId)
          .where('flatNumber', isEqualTo: _flatNumber.text.trim())
          .where('wing', isEqualTo: _selectedWing)
          .get()
          .timeout(const Duration(seconds: 10));

      if (notifiedUser.docs.isNotEmpty) {
        final url = Uri.parse('http://192.168.29.138:3000/courriers');
        Map<String, String> headers = {'Content-Type': 'application/json'};
        Map<String, String> body = {
          'delivery_name': _nameController.text.trim(),
          'user_id': notifiedUser.docs[0].id.toString(),
          'description': _description.text.trim(),
        };

        final response =
            await http.post(url, headers: headers, body: json.encode(body));
        if (response.statusCode == 201) {
          logger.i('_sendNotiToServer completed successfully (status 201)');
        } else {
          logger.e(
              '_sendNotiToServer failed: ${response.statusCode} ${response.body}');
        }
      } else {
        logger.i(
            '_sendNotiToServer completed: User not found for flat ${_flatNumber.text.trim()} in wing $_selectedWing');
      }
    } catch (e) {
      logger.e('Error in _sendNotiToServer: $e');
    }
  }

  // Backend: Saves courrier info to Firestore
  Future<void> _saveCourrierInfo() async {
    logger.i(
        '_saveCourrierInfo starting for deliveryName: ${_nameController.text.trim()}, flat: ${_flatNumber.text.trim()}, wing: $_selectedWing');

    final watchmanState = ref.read(watchmanProvider);
    if (watchmanState == null) {
      logger.e('Watchman state is null when saving courrier');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(watchmanState.buildId)
          .collection('courriers')
          .add({
        'deliveryName': _nameController.text.trim(),
        'flat': _flatNumber.text.trim(),
        'wing': _selectedWing,
        'description': _description.text.trim(),
        'recievedAt': Timestamp.now(),
        'recievedName': watchmanState.watchName,
        'recievedBy': watchmanState.watchId,
        'status': false
      });
      logger.i('_saveCourrierInfo saved document successfully');

      // Send notification in background
      _sendNotiToServer(watchmanState.buildId);

      logger.i('_saveCourrierInfo completed successfully');
      if (mounted) {
        CustomToast.show(context,
            type: 1, message: 'Data recorded successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      logger.e('Error in _saveCourrierInfo: $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: e.toString());
      }
    }
  }

  // UI: Build generic text field
  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // UI: Wings and Flat selection
  Widget _buildWingAndFlatSelection() {
    if (_selectedWing == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Wings"),
            ),
            DropdownButton<String>(
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
              value: _selectedWing,
              icon: const Icon(Icons.apartment),
              iconSize: 24,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedWing = newValue;
                  });
                }
              },
              items: _wings.map((wing) {
                String wingName =
                    wing is Map ? wing['wingName'] : wing.toString();
                return DropdownMenuItem<String>(
                  value: wingName,
                  child: Text(wingName),
                );
              }).toList(),
            ),
          ],
        ),
        TextField(
          controller: _flatNumber,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            constraints: BoxConstraints(maxWidth: 120),
            labelText: 'Flat Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // UI: Individual reason chip
  Widget _buildReasonChip(String label, Color color, String reasonText) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _description.text = reasonText;
        });
      },
      child: Chip(
        padding: const EdgeInsets.all(0),
        label: Text(label, textScaler: const TextScaler.linear(0.9)),
        backgroundColor: color,
      ),
    );
  }

  // UI: Quick reason chips
  Widget _buildQuickReasonChips() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 0,
          children: [
            _buildReasonChip("Amazon", const Color.fromARGB(255, 255, 217, 114),
                "Package Recieved from Amazon"),
            _buildReasonChip(
                "Flipkart",
                const Color.fromARGB(255, 255, 163, 163),
                "Package Recieved from Flipkart"),
            _buildReasonChip(
                "Courriers",
                const Color.fromARGB(255, 210, 208, 205),
                "A courrier is recieved. Please collect from base"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Notify About Packages"),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              _buildTextField(_nameController, 'From General Name'),
              const SizedBox(height: 10),
              _buildWingAndFlatSelection(),
              const SizedBox(height: 10),
              _buildQuickReasonChips(),
              _buildTextField(
                  _description, 'Custom Description for Notification',
                  maxLines: 3),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCourrierInfo,
          child: const Text("Record"),
        ),
      ],
    );
  }
}

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

// ---------------------------------------------------------
// Component: DisplayRecords
// ---------------------------------------------------------
class DisplayRecords extends StatelessWidget {
  final List<QueryDocumentSnapshot> logs;

  const DisplayRecords({super.key, required this.logs});

  // UI: Build an individual log record tile
  Widget _buildLogTile(BuildContext context, int index) {
    var logData = logs[index].data() as Map<String, dynamic>;
    DateTime date = (logData['timestamp'] as Timestamp).toDate();
    String finalDate = DateFormat('yyyy-MM-dd HH:mm').format(date);

    print(logData);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 4.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(logData['name'] ?? 'Unknown'),
            subtitle: logData['forBuild'] == true
                ? const Text("Building Maintainenace")
                : Text('${logData['wing']}-${logData['flat']}'),
            trailing: Text(finalDate),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(logs.length);

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: _buildLogTile,
    );
  }
}
