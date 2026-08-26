import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/providers/watchman_provider.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';

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
