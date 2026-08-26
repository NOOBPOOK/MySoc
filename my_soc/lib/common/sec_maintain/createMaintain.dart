import 'package:flutter/material.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/common/sec_maintain/maintain_widgets.dart';
import 'package:my_soc/common/sec_maintain/maintain_period_card.dart';
import 'package:my_soc/common/sec_maintain/maintain_standard_charges_card.dart';
import 'package:my_soc/common/sec_maintain/maintain_custom_charges_card.dart';
import 'package:my_soc/common/sec_maintain/maintain_due_details_card.dart';

// ---------------------------------------------------------
// UI Component: CreateMaintain
// ---------------------------------------------------------
class CreateMaintain extends StatefulWidget {
  const CreateMaintain({super.key});

  @override
  State<CreateMaintain> createState() => _CreateMaintainState();
}

class _CreateMaintainState extends State<CreateMaintain> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for standard amounts
  final TextEditingController _baseAmountController = TextEditingController();
  final TextEditingController _carAmountController = TextEditingController();
  final TextEditingController _bikeAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dynamic custom charges key-value controllers
  final List<Map<String, dynamic>> _customCharges = [];

  DateTime? _fromDate;
  DateTime? _tillDate;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    logger.d('CreateMaintainState dispose triggered');
    _baseAmountController.dispose();
    _carAmountController.dispose();
    _bikeAmountController.dispose();
    _descriptionController.dispose();
    for (var charge in _customCharges) {
      charge['key']?.dispose();
      charge['value']?.dispose();
    }
    super.dispose();
    logger.d('CreateMaintainState dispose completed successfully');
  }

  // Backend: Verify and commit any active custom charge
  bool _tryCommitActiveCharge() {
    logger.i('_tryCommitActiveCharge triggered');
    for (int i = 0; i < _customCharges.length; i++) {
      if (_customCharges[i]['isEditing'] == true) {
        final keyCtrl = _customCharges[i]['key'] as TextEditingController;
        final valCtrl = _customCharges[i]['value'] as TextEditingController;
        
        final keyText = keyCtrl.text.trim();
        final valText = valCtrl.text.trim();

        // Silently discard completely empty edits so they don't block submission
        if (keyText.isEmpty && valText.isEmpty) {
          logger.i('Silently removing empty editing custom charge at index $i');
          setState(() {
            _customCharges[i]['key']?.dispose();
            _customCharges[i]['value']?.dispose();
            _customCharges.removeAt(i);
          });
          return true;
        }

        if (keyText.isEmpty || valText.isEmpty) {
          logger.w('Validation failure: empty fields in custom charge at index $i');
          CustomToast.show(
            context,
            type: -1,
            message: "Please fill in both the Charge Name and Amount fields.",
          );
          return false;
        }

        if (double.tryParse(valText) == null) {
          logger.w('Validation failure: invalid amount in custom charge at index $i');
          CustomToast.show(
            context,
            type: -1,
            message: "Please enter a valid amount.",
          );
          return false;
        }

        setState(() {
          _customCharges[i]['resolvedKey'] = keyText;
          _customCharges[i]['resolvedValue'] = valText;
          _customCharges[i]['isEditing'] = false;
        });
        logger.i('Successfully committed custom charge at index $i: $keyText -> ₹$valText');
      }
    }
    return true;
  }

  // Backend: Add a new custom charge row
  void _addCustomCharge() {
    logger.i('_addCustomCharge triggered');
    
    // First verify if the current editing charge is valid and commit it
    if (!_tryCommitActiveCharge()) {
      return;
    }

    setState(() {
      _customCharges.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
        'isEditing': true,
        'resolvedKey': '',
        'resolvedValue': '',
      });
    });
    logger.i('_addCustomCharge completed successfully. Total custom charges: ${_customCharges.length}');
  }

  // Backend: Remove a custom charge row
  void _removeCustomCharge(int index) {
    logger.i('_removeCustomCharge triggered at index $index');
    setState(() {
      _customCharges[index]['key']?.dispose();
      _customCharges[index]['value']?.dispose();
      _customCharges.removeAt(index);
    });
    logger.i('_removeCustomCharge completed successfully. Remaining custom charges: ${_customCharges.length}');
  }

  // Backend: Date selector for From Date
  Future<void> _selectFromDate(BuildContext context) async {
    logger.i('_selectFromDate picker triggered');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select From Date',
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        // Make sure tillDate is after fromDate
        if (_tillDate != null && _tillDate!.isBefore(_fromDate!)) {
          _tillDate = _fromDate!.add(const Duration(days: 30));
        }
      });
      logger.i('_selectFromDate completed successfully: $_fromDate');
    }
  }

  // Backend: Date selector for Till Date
  Future<void> _selectTillDate(BuildContext context) async {
    logger.i('_selectTillDate picker triggered');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tillDate ?? (_fromDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Till Date',
    );
    if (picked != null && picked != _tillDate) {
      setState(() {
        _tillDate = picked;
      });
      logger.i('_selectTillDate completed successfully: $_tillDate');
    }
  }

  // Backend: Date selector for Due Date
  Future<void> _selectDueDate(BuildContext context) async {
    logger.i('_selectDueDate picker triggered');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Fallback if _dueDate is before today
    DateTime initial = _dueDate ?? today.add(const Duration(days: 15));
    if (initial.isBefore(today)) {
      initial = today;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2030),
      helpText: 'Select Due Date',
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
      logger.i('_selectDueDate completed successfully: $_dueDate');
    }
  }

  // Backend: Submit maintenance creation form
  Future<void> _submitForm(Map<String, dynamic> contextArgs) async {
    logger.i(
        '_submitForm started. Base: ${_baseAmountController.text}, Car: ${_carAmountController.text}, Bike: ${_bikeAmountController.text}');

    // Null checks for From, Till and Due Dates with CustomToast warning triggers
    if (_fromDate == null) {
      logger.w('_submitForm failed: From Date is null');
      CustomToast.show(context, type: -1, message: "Please select From Date.");
      return;
    }
    if (_tillDate == null) {
      logger.w('_submitForm failed: Till Date is null');
      CustomToast.show(context, type: -1, message: "Please select Till Date.");
      return;
    }
    if (_dueDate == null) {
      logger.w('_submitForm failed: Due Date is null');
      CustomToast.show(context, type: -1, message: "Please select Payment Due Date.");
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_dueDate!.isBefore(today)) {
      logger.w('_submitForm failed: Due Date $_dueDate is before today $today');
      CustomToast.show(context, type: -1, message: "Due Date cannot be before today.");
      return;
    }

    // Standard amounts validations with CustomToast warning triggers
    final baseText = _baseAmountController.text.trim();
    final carText = _carAmountController.text.trim();
    final bikeText = _bikeAmountController.text.trim();

    if (baseText.isEmpty || double.tryParse(baseText) == null) {
      logger.w('_submitForm failed: Base maintenance amount is empty or invalid');
      CustomToast.show(context, type: -1, message: "Please enter a valid Base Maintenance amount.");
      return;
    }
    if (carText.isEmpty || double.tryParse(carText) == null) {
      logger.w('_submitForm failed: Car parking amount is empty or invalid');
      CustomToast.show(context, type: -1, message: "Please enter a valid Car Parking amount.");
      return;
    }
    if (bikeText.isEmpty || double.tryParse(bikeText) == null) {
      logger.w('_submitForm failed: Bike parking amount is empty or invalid');
      CustomToast.show(context, type: -1, message: "Please enter a valid Bike Parking amount.");
      return;
    }

    // Backend: Try to commit any active edits first
    if (!_tryCommitActiveCharge()) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      logger.w('_submitForm failed validation');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Prepare custom charges map log
    final Map<String, String> resolvedCustomCharges = {};
    for (var charge in _customCharges) {
      final key = charge['resolvedKey']?.toString().trim() ?? '';
      final val = charge['resolvedValue']?.toString().trim() ?? '';
      if (key.isNotEmpty && val.isNotEmpty) {
        resolvedCustomCharges[key] = val;
      }
    }

    logger.d('Submitting custom charges: $resolvedCustomCharges');

    // Simulate backend Firestore/HTTP network call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

    logger.i('_submitForm completed successfully');
    
    if (mounted) {
      CustomToast.show(context, type: 0, message: "Generating Invoices. Come back later !");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Backend: Retrieve routing arguments passed from previous page
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userId'] ?? 'N/A';
    final buildingId = args['buildingId'] ?? 'N/A';

    logger.d('CreateMaintain build triggered: userId=$userId, buildingId=$buildingId');

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft gray canvas background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62.0),
        child: AppBar(
          toolbarHeight: 62.0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: const Border(
            bottom: BorderSide(
              color: Color(0xFF222A54),
              width: 2.0,
            ),
          ),
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF222A54)),
              onPressed: () {
                logger.i('Back navigation tapped on CreateMaintain');
                Navigator.of(context).pop();
              },
            ),
          ),
          title: const Text(
            "Create Maintenance",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Color(0xFF222A54),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                logger.i('Language change icon tapped in CreateMaintain');
                CustomToast.show(context, type: 0, message: "Language options...");
              },
              icon: const Icon(Icons.language_rounded, color: Color(0xFF222A54)),
              tooltip: "Change Language",
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Generate Bill Invoices",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222A54),
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Bill will be generated for all active flats inside building ID: $buildingId",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 17),

                // Section 1: Period Selection Card
                MaintainPeriodCard(
                  fromDate: _fromDate,
                  tillDate: _tillDate,
                  onSelectFromDate: () => _selectFromDate(context),
                  onSelectTillDate: () => _selectTillDate(context),
                ),
                const SizedBox(height: 17),

                // Section 2: Standard Charges Card
                MaintainStandardChargesCard(
                  baseAmountController: _baseAmountController,
                  carAmountController: _carAmountController,
                  bikeAmountController: _bikeAmountController,
                ),
                const SizedBox(height: 17),

                // Section 3: Custom Dynamic Charges Card
                MaintainCustomChargesCard(
                  customCharges: _customCharges,
                  onAddCustomCharge: _addCustomCharge,
                  onRemoveCustomCharge: _removeCustomCharge,
                ),
                const SizedBox(height: 17),

                // Section 4: Finalization Card
                MaintainDueDetailsCard(
                  dueDate: _dueDate,
                  onSelectDueDate: () => _selectDueDate(context),
                  descriptionController: _descriptionController,
                ),
                const SizedBox(height: 23),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF222A54), Color(0xFF3F4E99)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF222A54).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _submitForm(args),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Generate Bills",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: "Poppins",
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
