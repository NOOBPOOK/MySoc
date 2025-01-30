// This page assumes that you are viewing it as a secretary.

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/pages/secretary/add_penalty.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class WatchmanForm extends StatefulWidget {
  final build_data;
  final user_data;
  const WatchmanForm({super.key, this.build_data, this.user_data});

  @override
  _WatchmanFormState createState() => _WatchmanFormState();
}

class _WatchmanFormState extends State<WatchmanForm> {
  final _formKey = GlobalKey<FormState>();
  File? _photo;
  File? _document;

  late String _photoUrl;
  late String _documentUrl;

  String? _selectedShift;
  final _shifts = [
    'Morning (8:00 AM - 8:00 PM)',
    'Night (8:00 PM - 8:00 AM)',
  ];

  // Controllers for validation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shiftsController = TextEditingController();
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

  Future<void> uploadProfilePhoto() async {
    try {
      if (_photo == null) {
        throw Exception('Please choose a photo first');
      }
      final response = await cloudinary.upload(
          file: _photo!.path,
          resourceType: CloudinaryResourceType.image,
          folder: "inheritance_user_images",
          progressCallback: (count, total) {
            profileStatus = count / total;
          });

      if (response.isSuccessful) {
        _photoUrl = response.secureUrl.toString();
      } else {
        print("Error loading the profile photo");
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> uploadDocs() async {
    try {
      if (_document == null) {
        throw Exception('Please upload the necessary pfs');
      }
      final possDoc = await cloudinary.upload(
          file: _document?.path,
          resourceType: CloudinaryResourceType.auto,
          folder: "inheritance_user_pdfs",
          progressCallback: (count, total) {
            setState(() {
              // print(count);
              docStatus = count / total;
              // print(possStatus);
            });
          });
      if (possDoc.isSuccessful) {
        _documentUrl = possDoc.secureUrl.toString();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> submitWatchman() async {
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
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pop(context);
      });
      throw Exception("Watchman object has been created successfully");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watchman Details Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
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
                          _photoUrl = "";
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text('Remove Photo'),
                    ),
                  ),
                SizedBox(height: 16),

                if (profileStatus != 0.0)
                  LinearProgressIndicator(
                    value: profileStatus,
                  ),

                Center(
                  child: ElevatedButton(
                      onPressed: () {
                        uploadProfilePhoto();
                      },
                      child: Text("Upload Photo")),
                ),
                SizedBox(height: 16),

                // Watchman Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Watchman Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'Watchman Name'),
                ),
                SizedBox(height: 16),

                // Document Upload
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickDocument,
                    icon: Icon(Icons.upload_file),
                    label: Text('Proof of Working'),
                  ),
                ),
                if (_document != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                        'Uploaded Document: ${_document!.path.split('/').last}'),
                  ),
                if (docStatus != 0.0)
                  LinearProgressIndicator(
                    value: docStatus,
                  ),
                Center(
                    child: ElevatedButton(
                        onPressed: () {
                          uploadDocs();
                        },
                        child: Text("Upload Docs"))),
                SizedBox(height: 16),

                // Default Shift
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Shift (Default)',
                    border: OutlineInputBorder(),
                  ),
                  items: _shifts
                      .map((shift) => DropdownMenuItem(
                            value: shift,
                            child: Text(shift),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedShift = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a shift' : null,
                ),
                SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateRequired(value, 'Username'),
                ),
                SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: _validatePhoneNumber,
                ),
                SizedBox(height: 16),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      submitWatchman();
                    },
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
