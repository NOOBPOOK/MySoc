//add_announcements.dart page
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddAnnouncement extends StatefulWidget {
  final user_data;
  final build_data;
  const AddAnnouncement({super.key, this.user_data, this.build_data});

  @override
  State<AddAnnouncement> createState() => _AddAnnouncementState();
}

class _AddAnnouncementState extends State<AddAnnouncement> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _fileUrl;
  bool _isLoading = false;
  double uploadProgress = 0.0;
  late Cloudinary cloudinary;

  @override
  void initState() {
    super.initState();
    // Initialize Cloudinary with your credentials
    cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> uploadFile() async {
    try {
      if (_selectedFile == null) {
        throw Exception('Please choose a file first');
      }

      final fileExtension = _selectedFile!.path.split('.').last.toLowerCase();
      final resourceType = (fileExtension == 'pdf')
          ? CloudinaryResourceType.raw
          : CloudinaryResourceType.image;

      final response = await cloudinary.upload(
          file: _selectedFile!.path,
          resourceType: resourceType,
          folder: "announcements",
          progressCallback: (count, total) {
            setState(() {
              uploadProgress = count / total;
            });
          });

      if (response.isSuccessful) {
        setState(() {
          _fileUrl = response.secureUrl;
          uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_selectedFile != null && _fileUrl == null) {
          await uploadFile();
        }

        String currentUser =
            '${widget.user_data['firstName']} ${widget.user_data['lastName']}';
        final fileExtension = _selectedFile?.path.split('.').last.toLowerCase();

        await FirebaseFirestore.instance
            .collection('buildings')
            .doc(widget.build_data.id)
            .collection('announcements')
            .add({
          'subject': _subjectController.text,
          'description': _descriptionController.text,
          'fileUrl': _fileUrl,
          'fileName': _selectedFile?.path.split('/').last,
          'fileType': fileExtension,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser,
          'createdByDesignation': widget.user_data[
              'designation'], // Map the designations accordingly as per the schema
          'createdById': widget.user_data.id.toString(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Announcement',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1565C0),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.subject),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a subject';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _pickFile,
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.upload_file,
                                    color: Colors.blue[700]),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    _selectedFile != null
                                        ? 'File selected: ${_selectedFile!.path.split('/').last}'
                                        : 'Upload Photo/PDF',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: uploadFile,
                            child: Text("Upload File"),
                          ),
                          if (uploadProgress > 0 && uploadProgress < 1)
                            LinearProgressIndicator(value: uploadProgress),
                          if (_fileUrl != null)
                            Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Announcement',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
