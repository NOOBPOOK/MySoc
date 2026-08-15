import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/app_logger.dart';

class CreateAnnouncementPage extends ConsumerStatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  ConsumerState<CreateAnnouncementPage> createState() =>
      _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState
    extends ConsumerState<CreateAnnouncementPage> {
  late String userId;
  late String userName;
  late String buildingId;
  int designation = 0;

  bool _initialized = false;
  bool _isSubmitting = false;

  // Form State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tagsController.addListener(_formatTags);
  }

  void _formatTags() {
    final text = _tagsController.text;
    if (text.isEmpty) return;

    if (text.endsWith(' ')) {
      List<String> words = text.trim().split(' ');
      bool tagsAdded = false;

      for (var word in words) {
        if (word.isNotEmpty) {
          if (!word.startsWith('#')) word = '#$word';
          if (!_tags.contains(word)) {
            _tags.add(word);
            tagsAdded = true;
          }
        }
      }

      if (tagsAdded) {
        setState(() {});
      }
      _tagsController.clear();
      return;
    }

    int cursorPosition = _tagsController.selection.baseOffset;
    if (cursorPosition < 0) {
      cursorPosition = text.length;
    }

    List<String> words = text.split(' ');
    bool changed = false;

    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty && !words[i].startsWith('#')) {
        words[i] = '#${words[i]}';
        changed = true;
      }
    }

    if (changed) {
      String newText = words.join(' ');

      int offset = cursorPosition + (newText.length - text.length);

      _tagsController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: offset.clamp(0, newText.length),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Backend: Form Submission Validation
  Future<void> _submitAnnouncement() async {
    logger.i('CreateAnnouncementPage: _submitAnnouncement started. Validating inputs.');

    if (_titleController.text.trim().isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter a title');
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter a subject');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      CustomToast.show(context, type: -1, message: 'Please enter content');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      logger.i('CreateAnnouncementPage: Inputs validated. Formatting data for Firestore.');
      
      // Grab any tags left in the controller that the user didn't space-separate
      List<String> finalTags = List.from(_tags);
      String lastTag = _tagsController.text.trim();
      if (lastTag.isNotEmpty) {
        if (!lastTag.startsWith('#')) lastTag = '#$lastTag';
        if (!finalTags.contains(lastTag)) {
          finalTags.add(lastTag);
        }
      }

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('announcements')
          .add({
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'content': _contentController.text.trim(),
        'tags': finalTags,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
        'createdByName': userName,
      });

      if (mounted) {
        logger.i('CreateAnnouncementPage: _submitAnnouncement completed successfully.');
        CustomToast.show(context, type: 1, message: 'Announcement successfully published!');
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e('CreateAnnouncementPage: _submitAnnouncement encountered an error - $e');
      if (mounted) {
        CustomToast.show(context, type: -1, message: 'Failed to publish announcement: $e');
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
        "Create Announcement",
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

  // UI: Announcement Details Section
  Widget _buildAnnouncementDetailsCard() {
    return _buildCardContainer(
      title: "Announcement Details",
      icon: Icons.campaign,
      child: Column(
        children: [
          _buildCustomTextField(
            label: "Title",
            hintText: "e.g., Water Supply Interruption",
            controller: _titleController,
            validator: (value) => null,
          ),
          const SizedBox(height: 10),
          _buildCustomTextField(
            label: "Subject",
            hintText: "e.g., Maintenance Work",
            controller: _subjectController,
            validator: (value) => null,
          ),
          const SizedBox(height: 10),
          _buildCustomTextField(
            label: "Content",
            hintText: "Enter the full announcement details here...",
            controller: _contentController,
            maxLines: 7,
            validator: (value) => null,
          ),
          const SizedBox(height: 10),
          _buildTagsField(),
        ],
      ),
    );
  }

  // UI: Tags Field with Chips
  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tags",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF222A54),
          ),
        ),
        const SizedBox(height: 5),
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  backgroundColor: const Color(0xFF222A54),
                  deleteIconColor: Colors.white,
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        TextFormField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: "Type a tag and press space...",
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
              borderSide: const BorderSide(color: Color(0xFF222A54), width: 2),
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
      ],
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
            _buildAnnouncementDetailsCard(),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnnouncement,
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
                        "Publish Announcement",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
