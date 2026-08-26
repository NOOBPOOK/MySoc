import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

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
      rethrow;
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

      // Send notification in background (non-blocking)
      Future.microtask(() => _sendNotiToServer(watchmanState.buildId))
          .catchError((e) {
        logger.e('Error in background notification task: $e');
      });

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
