import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/app_logger.dart';

class UserCreatePollsPage extends ConsumerStatefulWidget {
  const UserCreatePollsPage({super.key});

  @override
  ConsumerState<UserCreatePollsPage> createState() =>
      _UserCreatePollsPageState();
}

class _UserCreatePollsPageState extends ConsumerState<UserCreatePollsPage> {
  late String userId;
  late String firstName;
  late String lastName;
  late String buildingId;
  int designation = 0;

  bool _initialized = false;
  bool _isSubmitting = false;

  // Form State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Start with 2 empty options by default
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _expiresAt;
  bool _allowMultipleSelections = false;
  bool _isAnonymous = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.i(
          'UserCreatePollsPage: didChangeDependencies started. Extracting navigation arguments.');

      // Architecture Note: Navigator Args vs Riverpod for Small Data
      // For simple, static identifiers (like userId, names, buildingId, designation) that do not change
      // during the lifecycle of this page, passing them via Navigator arguments is significantly more
      // efficient. It avoids unnecessarily subscribing this widget to Riverpod providers, which would
      // needlessly consume memory and cause UI jitters/rebuilds if those providers ever emit unrelated updates.
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        firstName = args['firstName'] ?? '';
        lastName = args['lastName'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
      } else {
        userId = '';
        firstName = '';
        lastName = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          'UserCreatePollsPage: didChangeDependencies completed successfully. User ID: $userId');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // UI: Select Expiry Date & Time
  Future<void> _selectExpiryDateTime() async {
    logger.i('UserCreatePollsPage: _selectExpiryDateTime started.');

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF222A54),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF222A54),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _expiresAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        logger.i(
            'UserCreatePollsPage: _selectExpiryDateTime completed successfully. Expiry set to $_expiresAt.');
      } else {
        logger.i(
            'UserCreatePollsPage: _selectExpiryDateTime completed. Time picking cancelled.');
      }
    } else {
      logger.i(
          'UserCreatePollsPage: _selectExpiryDateTime completed. Date picking cancelled.');
    }
  }

  // Backend: Form Submission Validation
  Future<void> _submitPoll() async {
    logger.i('UserCreatePollsPage: _submitPoll started. Validating inputs.');

    if (_titleController.text.trim().isEmpty) {
      logger.d(
          'UserCreatePollsPage: _submitPoll validation failed - Empty Title.');
      CustomToast.show(context, type: -1, message: 'Please enter a poll title');
      return;
    }

    for (int i = 0; i < _optionControllers.length; i++) {
      if (_optionControllers[i].text.trim().isEmpty) {
        logger.d(
            'UserCreatePollsPage: _submitPoll validation failed - Empty Option ${i + 1}.');
        CustomToast.show(context,
            type: -1, message: 'Option ${i + 1} cannot be empty');
        return;
      }
    }

    final optionTexts =
        _optionControllers.map((c) => c.text.trim().toLowerCase()).toList();
    if (optionTexts.toSet().length != optionTexts.length) {
      logger.d(
          'UserCreatePollsPage: _submitPoll validation failed - Duplicate Options.');
      CustomToast.show(context,
          type: -1, message: 'All options must be unique');
      return;
    }

    if (_expiresAt == null) {
      logger.d(
          'UserCreatePollsPage: _submitPoll validation failed - No Expiry Date.');
      CustomToast.show(context,
          type: -1, message: 'Please select an expiry date and time');
      return;
    }

    if (_expiresAt!.isBefore(DateTime.now())) {
      logger.d(
          'UserCreatePollsPage: _submitPoll validation failed - Expiry in past.');
      CustomToast.show(context,
          type: -1, message: 'Expiry time must be in the future');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      logger.i(
          'UserCreatePollsPage: _submitPoll inputs validated. Formatting data for Firestore.');
      List<Map<String, String>> formattedOptions = [];
      Map<String, int> initialCounts = {};

      for (int i = 0; i < _optionControllers.length; i++) {
        String optionId = 'opt_$i';
        formattedOptions.add({
          'optionId': optionId,
          'text': _optionControllers[i].text.trim(),
        });
        initialCounts[optionId] = 0;
      }

      String capitalize(String s) => s.trim().isEmpty
          ? ''
          : '${s.trim()[0].toUpperCase()}${s.trim().substring(1).toLowerCase()}';
      String createdByName =
          '${capitalize(firstName)} ${capitalize(lastName)}'.trim();

      await FirebaseFirestore.instance.collection('polls').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'buildingId': buildingId,
        'createdBy': userId,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(_expiresAt!),
        'allowMultipleSelections': _allowMultipleSelections,
        'isAnonymous': _isAnonymous,
        'options': formattedOptions,
        'optionCounts': initialCounts,
        'totalVotes': 0,
      });

      if (mounted) {
        logger.i(
            'UserCreatePollsPage: _submitPoll completed successfully. Poll written to Firestore.');
        CustomToast.show(context,
            type: 1, message: 'Poll successfully created!');
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('UserCreatePollsPage: _submitPoll encountered an error - $e');
      if (mounted) {
        CustomToast.show(context,
            type: -1, message: 'Failed to create poll: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // UI: App Bar
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
        "Create Poll",
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
            // TODO: Implement language change
          },
          icon: const Icon(Icons.language, color: Color(0xFF222A54)),
          tooltip: "Change Language",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // UI: Reusable Card Container mimicking admin app design
  Widget _buildCardContainer(
      {required String title, required IconData icon, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF222A54)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222A54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // UI: Shared input field replicating the login screen layout
  Widget _buildCustomTextField({
    String? label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label,
            style: const TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF222A54),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: label != null ? 5 : 0, bottom: 2),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontFamily: "Poppins",
                fontWeight: FontWeight.w300,
                fontSize: 15,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFACACAC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:
                    const BorderSide(color: Color(0xFF222A54), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Core Details Section
  Widget _buildCoreDetailsCard() {
    return _buildCardContainer(
      title: "About Poll",
      icon: Icons.info,
      child: Column(
        children: [
          _buildCustomTextField(
            label: "Poll Title",
            hintText: "e.g., Solar Panel Installation",
            controller: _titleController,
            validator: (value) => null,
          ),
          const SizedBox(height: 10),
          _buildCustomTextField(
            label: "Description (Optional)",
            hintText: "Add context or details to help voters decide...",
            controller: _descriptionController,
            maxLines: 1,
            validator: (value) => null,
          ),
        ],
      ),
    );
  }

  // UI: Dynamic Options Section
  Widget _buildOptionsCard() {
    return _buildCardContainer(
      title: "Poll Options",
      icon: Icons.list_alt,
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _optionControllers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      hintText: "Option ${index + 1}",
                      controller: _optionControllers[index],
                      validator: (value) => null,
                    ),
                  ),
                  if (_optionControllers.length > 2) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () {
                        final controller = _optionControllers[index];
                        setState(() {
                          _optionControllers.removeAt(index);
                        });
                        controller.dispose();
                      },
                    ),
                  ] else ...[
                    // Preserve spacing if there's no remove button
                    const SizedBox(width: 48),
                  ]
                ],
              );
            },
          ),
          // const SizedBox(height: 0),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _optionControllers.add(TextEditingController());
              });
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add_circle,
                color: Color(0xFF222A54), size: 18),
            label: const Text(
              "Add Option",
              style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1,
                color: Color(0xFF222A54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI: Settings & Expiry Section
  Widget _buildSettingsCard() {
    return _buildCardContainer(
      title: "Settings & Expiry",
      icon: Icons.settings,
      child: Column(
        children: [
          // Expiry Picker
          InkWell(
            onTap: _selectExpiryDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFF222A54)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _expiresAt == null
                          ? 'Select Expiry Date & Time'
                          : 'Expires: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_expiresAt!)}',
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: _expiresAt == null
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontWeight: _expiresAt == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Settings Switches
          SwitchListTile(
            title: const Text("Allow Multiple Selections",
                style: TextStyle(fontFamily: "Poppins")),
            subtitle: const Text("Voters can choose more than one option",
                style: TextStyle(fontSize: 12)),
            activeColor: const Color(0xFF222A54),
            contentPadding: EdgeInsets.zero,
            value: _allowMultipleSelections,
            onChanged: (val) => setState(() => _allowMultipleSelections = val),
          ),
          SwitchListTile(
            title: const Text("Anonymous Voting",
                style: TextStyle(fontFamily: "Poppins")),
            subtitle: const Text("Hide voter names from everyone",
                style: TextStyle(fontSize: 12)),
            activeColor: const Color(0xFF222A54),
            contentPadding: EdgeInsets.zero,
            value: _isAnonymous,
            onChanged: (val) => setState(() => _isAnonymous = val),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoreDetailsCard(),
            const SizedBox(height: 8),
            _buildOptionsCard(),
            const SizedBox(height: 8),
            _buildSettingsCard(),
            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPoll,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222A54),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Publish Poll",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
