import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'package:my_soc/providers/user_provider.dart';
import 'package:my_soc/widgets/custom_toast.dart';

class IssuePenaltyFormPage extends ConsumerStatefulWidget {
  const IssuePenaltyFormPage({super.key});

  @override
  ConsumerState<IssuePenaltyFormPage> createState() =>
      _IssuePenaltyFormPageState();
}

class _IssuePenaltyFormPageState extends ConsumerState<IssuePenaltyFormPage> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dropdownSearchController = TextEditingController();

  late String userId;
  late String userName;
  late String buildingId;
  int designation = 0;
  bool _initialized = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? _selectedUser;
  bool _isDropdownExpanded = false;
  String _dropdownSearchQuery = '';
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    logger.d('_IssuePenaltyFormPageState: disposing controllers');
    _reasonController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _dropdownSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      logger.d(
          '_IssuePenaltyFormPageState: didChangeDependencies started initialization');
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userId = args['userId'] ?? '';
        userName = args['userName'] ?? '';
        buildingId = args['buildingId'] ?? '';
        designation = args['designation'] ?? 0;
      } else {
        userId = '';
        userName = '';
        buildingId = '';
        designation = 0;
      }
      _initialized = true;
      logger.i(
          '_IssuePenaltyFormPageState: didChangeDependencies completed initialization with buildingId: $buildingId, userId: $userId, userName: $userName, designation: $designation');
    }
  }

  // Backend: Open DatePicker for due date selection
  Future<void> _selectDueDate(BuildContext context) async {
    logger.d('_IssuePenaltyFormPageState: _selectDueDate started');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
      logger.i('_IssuePenaltyFormPageState: Due date selected: $picked');
    }
  }

  // Backend: Validate and submit penalty mock implementation
  Future<void> _submitPenalty() async {
    logger.i('_IssuePenaltyFormPageState: _submitPenalty started');
    
    // User Selection validation
    if (_selectedUser == null) {
      CustomToast.show(context, type: -1, message: 'Please select a resident');
      return;
    }

    final reason = _reasonController.text.trim();
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    // Reason validation
    if (reason.isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter a penalty title / reason');
      return;
    }

    // Amount validation
    if (amountText.isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter penalty amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      CustomToast.show(context, type: -1, message: 'Please enter a valid amount');
      return;
    }

    // Description validation
    if (description.isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter penalty description');
      return;
    }

    // Due Date validation
    if (_selectedDueDate == null) {
      CustomToast.show(context, type: -1, message: 'Please select a due date');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final selectedUserFName = _capitalize(_selectedUser!['firstName']?.toString() ?? '');
      final selectedUserLName = _capitalize(_selectedUser!['lastName']?.toString() ?? '');
      final selectedUserFullName = '$selectedUserFName $selectedUserLName'.trim();

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('penalties')
          .add({
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userName,
        'createdById': userId,
        'dueDate': Timestamp.fromDate(_selectedDueDate!),
        'flatNumber': _selectedUser!['flatNumber'] ?? 'N/A',
        'pay_id': 'None',
        'proofImage': [],
        'reason': reason,
        'description': description,
        'residentId': _selectedUser!['id'],
        'residentName': selectedUserFullName,
        'status': false,
        'wing': _selectedUser!['wing'] ?? 'N/A',
      });

      logger.i('_IssuePenaltyFormPageState: Penalty issued successfully to ${_selectedUser!['id']}');
      
      if (mounted) {
        CustomToast.show(
          context,
          type: 1,
          message: 'Penalty successfully issued!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('_IssuePenaltyFormPageState: Error submitting penalty - $e');
      if (mounted) {
        CustomToast.show(
          context,
          type: -1,
          message: 'Failed to issue penalty: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Backend: Helper to capitalize and trim name parts
  String _capitalize(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return '';
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  // UI: App Bar
  PreferredSizeWidget _buildAppBar() {
    logger.d('_IssuePenaltyFormPageState: _buildAppBar called');
    final appBar = AppBar(
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
        "Issue Penalty",
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
    logger.d('_IssuePenaltyFormPageState: _buildAppBar completed');
    return appBar;
  }

  // UI: Reusable Card Container mimicking complaints page layout
  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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

  // UI: Custom text field styled matching the complaints form
  Widget _buildCustomTextField({
    String? label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
              fontSize: 14,
              color: Color(0xFF222A54),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: label != null ? 5 : 0, bottom: 2),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
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

  // UI: Build clickable input field (used for Due Date)
  Widget _buildClickableField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF222A54),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(top: 5, bottom: 2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFACACAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 15,
                    color: _selectedDueDate != null ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
                Icon(icon, size: 18, color: const Color(0xFF222A54)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // UI: Build Custom User Dropdown Selector
  Widget _buildUserDropdown(AsyncValue<List<Map<String, dynamic>>> usersAsync) {
    logger.d('_IssuePenaltyFormPageState: _buildUserDropdown started');
    
    final dropdownContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownExpanded = !_isDropdownExpanded;
            });
            logger.d('_IssuePenaltyFormPageState: Dropdown toggle state: $_isDropdownExpanded');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDropdownExpanded ? const Color(0xFF222A54) : Colors.grey.shade200,
                width: _isDropdownExpanded ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF222A54).withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedUser != null
                      ? '${_capitalize(_selectedUser!['firstName']?.toString() ?? '')} ${_capitalize(_selectedUser!['lastName']?.toString() ?? '')}'.trim()
                      : 'Choose Resident...',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 15,
                    color: _selectedUser != null ? Colors.black87 : Colors.grey.shade500,
                    fontWeight: _selectedUser != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Icon(
                  _isDropdownExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF222A54),
                ),
              ],
            ),
          ),
        ),
        if (_isDropdownExpanded) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: TextField(
                    controller: _dropdownSearchController,
                    onChanged: (val) {
                      setState(() {
                        _dropdownSearchQuery = val.trim().toLowerCase();
                      });
                      logger.d('_IssuePenaltyFormPageState: dropdown search query: $_dropdownSearchQuery');
                    },
                    decoration: InputDecoration(
                      hintText: "Search resident by name or email...",
                      hintStyle: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF222A54)),
                      suffixIcon: _dropdownSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _dropdownSearchController.clear();
                                setState(() {
                                  _dropdownSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF222A54), width: 1.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: usersAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Color(0xFF222A54)),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(fontFamily: "Poppins", color: Colors.red),
                        ),
                      ),
                    ),
                    data: (users) {
                      final filteredUsers = users.where((user) {
                        if (_dropdownSearchQuery.isEmpty) return true;
                        final fName = (user['firstName'] ?? '').toString().toLowerCase();
                        final lName = (user['lastName'] ?? '').toString().toLowerCase();
                        final email = (user['email'] ?? '').toString().toLowerCase();
                        final fullName = '$fName $lName';
                        return fullName.contains(_dropdownSearchQuery) || email.contains(_dropdownSearchQuery);
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No resident matched',
                              style: TextStyle(fontFamily: "Poppins", color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final fName = _capitalize(user['firstName']?.toString() ?? '');
                          final lName = _capitalize(user['lastName']?.toString() ?? '');
                          final fullName = '$fName $lName'.trim();
                          final email = user['email'] ?? 'No Email';
                          final wing = user['wing'] ?? 'N/A';
                          final flat = user['flatNumber'] ?? 'N/A';

                          final isSelected = _selectedUser != null && _selectedUser!['id'] == user['id'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                                _isDropdownExpanded = false;
                                _dropdownSearchController.clear();
                                _dropdownSearchQuery = '';
                              });
                              logger.i('_IssuePenaltyFormPageState: Selected user: ${user['id']} ($fullName)');
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF222A54).withOpacity(0.04) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF222A54) : Colors.grey.shade100,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF222A54)),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: TextStyle(
                                                  fontFamily: "Poppins",
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.home_outlined, size: 12, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$wing - $flat",
                                            style: TextStyle(
                                              fontFamily: "Poppins",
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    logger.d('_IssuePenaltyFormPageState: _buildUserDropdown completed');
    return dropdownContent;
  }

  @override
  Widget build(BuildContext context) {
    logger.d('_IssuePenaltyFormPageState: build method started');
    final verifiedUsersAsync = ref.watch(verifiedBuildingUsersFutureProvider(buildingId));

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardContainer(
              title: "Resident Details",
              icon: Icons.person,
              child: _buildUserDropdown(verifiedUsersAsync),
            ),
            const SizedBox(height: 8),
            _buildCardContainer(
              title: "Penalty Details",
              icon: Icons.gavel,
              child: Column(
                children: [
                  _buildCustomTextField(
                    label: "Title / Reason",
                    hintText: "e.g., Late Maintenance Fee Payment",
                    controller: _reasonController,
                  ),
                  const SizedBox(height: 10),
                  _buildCustomTextField(
                    label: "Penalty Amount (₹)",
                    hintText: "e.g., 500",
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  _buildClickableField(
                    label: "Due Date",
                    value: _selectedDueDate != null
                        ? "${_selectedDueDate!.day.toString().padLeft(2, '0')}/${_selectedDueDate!.month.toString().padLeft(2, '0')}/${_selectedDueDate!.year}"
                        : "Select Due Date...",
                    icon: Icons.calendar_today,
                    onTap: () => _selectDueDate(context),
                  ),
                  const SizedBox(height: 10),
                  _buildCustomTextField(
                    label: "Description",
                    hintText: "Enter the details explaining why the penalty is issued...",
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Space for floating action button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPenalty,
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
                  "Issue Penalty",
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
    logger.d('_IssuePenaltyFormPageState: build method completed');
    return scaffold;
  }
}
