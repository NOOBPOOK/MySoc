import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class WatchmanForm extends StatefulWidget {
  final DocumentSnapshot build_data;
  final QueryDocumentSnapshot user_data;

  const WatchmanForm({
    Key? key,
    required this.build_data,
    required this.user_data,
  }) : super(key: key);

  @override
  _WatchmanFormState createState() => _WatchmanFormState();
}

class _WatchmanFormState extends State<WatchmanForm> {
  final _formKey = GlobalKey<FormState>();
  File? _photo;
  File? _document;
  String? _photoUrl;
  String? _documentUrl;
  String? _selectedShift;
  final _shifts = [
    'Morning (8:00 AM - 8:00 PM)',
    'Night (8:00 PM - 8:00 AM)',
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  double profileStatus = 0.0;
  double docStatus = 0.0;
  late Cloudinary cloudinary;

  @override
  void initState() {
    super.initState();
    cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
  }

  Future<void> _pickPhoto() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _photo = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _document = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadProfilePhoto() async {
    try {
      if (_photo == null) throw Exception('Please choose a photo first');
      final response = await cloudinary.upload(
        file: _photo!.path,
        resourceType: CloudinaryResourceType.image,
        folder: "inheritance_user_images",
        progressCallback: (count, total) {
          setState(() {
            profileStatus = count / total;
          });
        },
      );

      if (response.isSuccessful) {
        _photoUrl = response.secureUrl.toString();
      } else {
        throw Exception('Error uploading profile photo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> uploadDocs() async {
    try {
      if (_document == null)
        throw Exception('Please upload the necessary PDFs');
      final response = await cloudinary.upload(
        file: _document!.path,
        resourceType: CloudinaryResourceType.auto,
        folder: "inheritance_user_pdfs",
        progressCallback: (count, total) {
          setState(() {
            docStatus = count / total;
          });
        },
      );

      if (response.isSuccessful) {
        _documentUrl = response.secureUrl.toString();
      } else {
        throw Exception('Error uploading document');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> submitWatchman() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('buildings')
            .doc(widget.build_data.id)
            .collection('watchmen')
            .add({
          'name': _nameController.text.trim(),
          'shift': _selectedShift,
          'username': _usernameController.text.trim(),
          'password': 'pass123',
          'phone': _phoneNumberController.text.trim(),
          'profile': _photoUrl,
          'doc': _documentUrl,
          'creation': Timestamp.now(),
          'isFirst': true,
          'isDisabled': false,
          'buildingId': widget.build_data.id.toString(),
          'createdBy':
              '${widget.user_data['firstName']} ${widget.user_data['lastName']}',
          'createdById': widget.user_data.id.toString(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watchman added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone Number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 600),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildProfilePhotoSection(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Watchman Name',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 24),
                        _buildDocumentUploadSection(),
                        const SizedBox(height: 24),
                        _buildShiftDropdown(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _phoneNumberController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: AnimatedTextKit(
        animatedTexts: [
          WavyAnimatedText(
            'Add Watchman',
            textStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        isRepeatingAnimation: false,
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: _photo != null ? FileImage(_photo!) : null,
              child: _photo == null
                  ? Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.white.withOpacity(0.7),
                    )
                  : null,
            ),
          ),
        ),
        if (_photo != null)
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  profileStatus = 0.0;
                  _photo = null;
                  _photoUrl = null;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        if (profileStatus != 0.0)
          LinearProgressIndicator(
            value: profileStatus,
            color: const Color(0xFFE94560),
          ),
        Center(
          child: ElevatedButton(
            onPressed: uploadProfilePhoto,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Upload Photo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      children: [
        Center(
          child: ElevatedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.upload_file),
            label: const Text('Proof of Working'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_document != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Uploaded Document: ${_document!.path.split('/').last}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        if (docStatus != 0.0)
          LinearProgressIndicator(
            value: docStatus,
            color: const Color(0xFFE94560),
          ),
        Center(
          child: ElevatedButton(
            onPressed: uploadDocs,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Upload Docs",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Shift (Default)',
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      items: _shifts
          .map((shift) => DropdownMenuItem(
                value: shift,
                child: Text(shift, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedShift = value;
        });
      },
      validator: (value) => value == null ? 'Please select a shift' : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: const Color(0xFFE94560)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      validator: (value) => _validateRequired(value, label),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: submitWatchman,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Submit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
