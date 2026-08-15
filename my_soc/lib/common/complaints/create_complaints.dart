import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/app_logger.dart';

class CreateComplaintsPage extends ConsumerStatefulWidget {
  final Map args;

  const CreateComplaintsPage({super.key, required this.args});

  @override
  ConsumerState<CreateComplaintsPage> createState() =>
      _CreateComplaintsPageState();
}

class _CreateComplaintsPageState extends ConsumerState<CreateComplaintsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPrivate = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Backend: Form Submission Validation
  Future<void> _submitComplaint() async {
    logger.i(
        'CreateComplaintsPage: _submitComplaint started. Validating inputs.');

    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter a title');
      return;
    }

    if (subject.isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter a subject');
      return;
    }

    if (description.isEmpty) {
      CustomToast.show(context,
          type: -1, message: 'Please enter a description');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = widget.args['userId'] ?? '';
      final createdByName = widget.args['ownerName'] ?? '';
      final buildingId = widget.args['buildingId'] ?? '';

      await FirebaseFirestore.instance.collection('complaints').add({
        'createdAt': FieldValue.serverTimestamp(),
        'title': title,
        'subject': subject,
        'description': description,
        'isPrivate': _isPrivate,
        'createdBy': userId,
        'createdByName': createdByName,
        'status': 0,
        'buildId': buildingId,
        'upvoteCount': 0,
      });

      if (mounted) {
        logger.i('Complaint Submitted successfully: $title');
        CustomToast.show(context,
            type: 1, message: 'Complaint successfully created!');
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('Error submitting complaint: $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: 'Failed to create complaint: $e');
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
        "Raise a Complaint",
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

  // UI: Complaint Details Section
  Widget _buildDetailsCard() {
    return _buildCardContainer(
      title: "Complaint Details",
      icon: Icons.report_problem,
      child: Column(
        children: [
          _buildCustomTextField(
            label: "Title",
            hintText: "e.g., Water Leakage",
            controller: _titleController,
          ),
          const SizedBox(height: 10),
          _buildCustomTextField(
            label: "Subject",
            hintText: "e.g., Maintenance Issue",
            controller: _subjectController,
          ),
          const SizedBox(height: 10),
          _buildCustomTextField(
            label: "Description",
            hintText: "Describe the issue in detail...",
            controller: _descriptionController,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // UI: Settings Section
  Widget _buildSettingsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: SwitchListTile(
          dense: true,
          title: const Text("Private Complaint",
              style: TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          subtitle: const Text("Only admins can view this complaint",
              style: TextStyle(fontSize: 12)),
          activeColor: const Color(0xFF222A54),
          contentPadding: EdgeInsets.zero,
          value: _isPrivate,
          onChanged: (val) => setState(() => _isPrivate = val),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailsCard(),
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
          onPressed: _isSubmitting ? null : _submitComplaint,
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
                  "Raise Complaint",
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
