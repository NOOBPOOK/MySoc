import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GenerateMaintenancePDF extends StatefulWidget {
  const GenerateMaintenancePDF({Key? key}) : super(key: key);

  @override
  State<GenerateMaintenancePDF> createState() => _GenerateMaintenancePDFState();
}

class _GenerateMaintenancePDFState extends State<GenerateMaintenancePDF> {
  bool _isLoading = false;
  bool _useCurrentMonth = true;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _maintenanceChargesController = TextEditingController(text: '1000');
  final _serviceChargesController = TextEditingController(text: '500');
  final _repairChargesController = TextEditingController(text: '100');
  final _otherChargesController = TextEditingController(text: '0');
  final _lateChargesController = TextEditingController(text: '0');
  DateTime _selectedDueDate = DateTime.now().copyWith(day: 10);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final now = DateTime.now();
    _yearController.text = now.year.toString();
    _monthController.text = now.month.toString();
    _dueDateController.text = DateFormat('dd/MM/yyyy').format(_selectedDueDate);
  }

  Map<String, int> calculateParkingCharges(List<dynamic> vehicles) {
    int carCharges = 0;
    int bikeCharges = 0;
    int cycleCharges = 0;
    
    for (var vehicle in vehicles) {
      String type = vehicle['type'].toString().toLowerCase();
      if (type == 'car') {
        carCharges += 300;
      } else if (type == 'bike' || type == 'two wheeler' || type == 'scooter') {
        bikeCharges += 150;
      } else if (type == 'cycle' || type == 'bicycle') {
        cycleCharges += 50;
      }
    }

    return {
      'carCharges': carCharges,
      'bikeCharges': bikeCharges,
      'cycleCharges': cycleCharges,
      'totalParkingCharges': carCharges + bikeCharges + cycleCharges,
    };
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _generateMaintenanceRecords() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final buildingDetails = args['buildingDetails'] as DocumentSnapshot;
      final buildingId = buildingDetails.id;

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('buildingId', isEqualTo: buildingId)
          .where('currentlyResiding', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      
      for (var userDoc in usersSnapshot.docs) {
        final vehicles = (userDoc.data() as Map<String, dynamic>)['vehicles'] ?? [];
        final parkingCharges = calculateParkingCharges(vehicles);

        final maintenanceRef = FirebaseFirestore.instance
            .collection('maintenance')
            .doc();

        final baseCharges = {
          'maintenanceCharges': int.parse(_maintenanceChargesController.text),
          'serviceCharges': int.parse(_serviceChargesController.text),
          'repairCharges': int.parse(_repairChargesController.text),
          'otherCharges': int.parse(_otherChargesController.text),
          'lateCharges': int.parse(_lateChargesController.text),
        };

        final totalAmount = baseCharges.values.reduce((a, b) => a + b) + 
                          parkingCharges['totalParkingCharges']!;

        batch.set(maintenanceRef, {
          'userId': userDoc.id,
          'month': _useCurrentMonth ? DateTime.now().month : int.parse(_monthController.text),
          'year': _useCurrentMonth ? DateTime.now().year : int.parse(_yearController.text),
          'dueDate': Timestamp.fromDate(_selectedDueDate),
          ...baseCharges,
          'parkingChargesBreakdown': {
            'car': parkingCharges['carCharges'],
            'bike': parkingCharges['bikeCharges'],
            'cycle': parkingCharges['cycleCharges'],
          },
          'parkingCharges': parkingCharges['totalParkingCharges'],
          'createdAt': Timestamp.now(),
          'buildingId': buildingId,
          'status': 'pending',
          'totalAmount': totalAmount,
          // 'vehicles': vehicles,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance records generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating maintenance records: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Maintenance Records'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month and Year Selection
              SwitchListTile(
                title: const Text('Use Current Month'),
                value: _useCurrentMonth,
                onChanged: (bool value) {
                  setState(() => _useCurrentMonth = value);
                },
              ),
              if (!_useCurrentMonth) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthController,
                        decoration: const InputDecoration(
                          labelText: 'Month (1-12)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final month = int.tryParse(value);
                          if (month == null || month < 1 || month > 12) {
                            return 'Invalid month';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final year = int.tryParse(value);
                          if (year == null || year < 2000 || year > 2100) {
                            return 'Invalid year';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              // Due Date
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDueDate,
              ),

              // Charges
              const SizedBox(height: 16),
              TextFormField(
                controller: _maintenanceChargesController,
                decoration: const InputDecoration(
                  labelText: 'Maintenance Charges',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceChargesController,
                decoration: const InputDecoration(
                  labelText: 'Service Charges',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repairChargesController,
                decoration: const InputDecoration(
                  labelText: 'Repair Charges',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otherChargesController,
                decoration: const InputDecoration(
                  labelText: 'Other Charges',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lateChargesController,
                decoration: const InputDecoration(
                  labelText: 'Late Charges',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _generateMaintenanceRecords,
                        child: const Text('Generate Maintenance Records'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dueDateController.dispose();
    _maintenanceChargesController.dispose();
    _serviceChargesController.dispose();
    _repairChargesController.dispose();
    _otherChargesController.dispose();
    _lateChargesController.dispose();
    super.dispose();
  }
}