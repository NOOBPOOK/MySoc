// This page is for every verified user who wants to make a complaint in his building

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_soc/routes.dart';
import 'package:cloudinary/cloudinary.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddComplaints extends StatefulWidget {
  const AddComplaints({super.key});

  @override
  State<AddComplaints> createState() => _AddComplaintsState();
}

class _AddComplaintsState extends State<AddComplaints> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  // Concerned for images working
  List<File> _buildingImages = [];
  List<String> _buildingImagesURL = [];
  final _picker = ImagePicker();
  double imageUploadStatus = 0.0;
  late Cloudinary cloudinary;

  // true is private false is public
  bool isSelected = true;

  // Getting the arguments from previous pages
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  @override
  void initState() {
    super.initState();

    cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
  }

  Future<void> addComplaint() async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(build_details.id)
          .collection('complaints')
          .add({
        'owner': '${user_details['firstName']} ${user_details['lastName']}',
        'owner_id': user_details.id.toString(),
        'subject': _subjectController.text.trim(),
        'description': _problemController.text.trim(),
        'images': _buildingImagesURL,
        'isPrivate': isSelected,
        'upvotes': [],
        'devotes': [],
        'addedAt': FieldValue.serverTimestamp(),
        'status':
            0, // 0 -> issue raised, 1 -> Noted by secretary, 2 -> Under Work to solve, 3 -> Issue Resolved
      });

      throw Exception('Complaint has been raised successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 5),
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  // Concerned with image widget and functionality
  Future<void> _pickBuildingImages() async {
    final pickedFiles = await _picker.pickMultiImage(
      imageQuality: 80,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _buildingImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  // Concerned with image widget and functionality
  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _buildingImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _buildingImages.length) {
          return InkWell(
            onTap: _pickBuildingImages,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_a_photo, color: Colors.blue),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _buildingImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _buildingImages = [];
                    _buildingImagesURL = [];
                    imageUploadStatus = 0.0;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Concerned with image widget and functionality
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload Images Optional",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          Divider(color: Colors.blue[800], thickness: 1),
        ],
      ),
    );
  }

  // Concerned with image widget and functionality
  Future<void> _uploadImages() async {
    try {
      var image_path;
      var c = 0;
      var total = _buildingImages.length;
      for (image_path in _buildingImages) {
        final response = await cloudinary.upload(
            file: image_path.path,
            resourceType: CloudinaryResourceType.image,
            folder: "inheritance_building_images",
            progressCallback: (count, total) {
              // print('Uploading image $count/$total');
            });

        if (response.isSuccessful) {
          c += 1;
          _buildingImagesURL.add(response.secureUrl.toString());
          setState(() {
            imageUploadStatus = c / total;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text("Register a Complaint"),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Field
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Problem Field
                      TextFormField(
                        controller: _problemController,
                        decoration: InputDecoration(
                          labelText: 'Problem',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe the problem';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Image Display and Upload
                      SizedBox(height: 16),
                      _buildSectionHeader(),
                      _buildImageGrid(),
                      if (imageUploadStatus != 0.0)
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: LinearProgressIndicator(
                            value: imageUploadStatus,
                          ),
                        ),
                      SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _uploadImages,
                          child: Text("Upload Images")),
                      SizedBox(height: 16),

                      // For choosing  Private/Public Complaint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                              child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isSelected = true;
                              });
                            },
                            child: Container(
                              color: isSelected ? Colors.grey : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(child: Text("Private")),
                              ),
                            ),
                          )),
                          Expanded(
                              child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isSelected = false;
                              });
                            },
                            child: Container(
                              color: isSelected ? Colors.white : Colors.grey,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(child: Text("Public")),
                              ),
                            ),
                          )),
                        ],
                      ),

                      // Submit Button
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            addComplaint();
                          },
                          child: Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}
