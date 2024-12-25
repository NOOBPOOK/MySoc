//This file is just a practice implementation of uploading images onto the cloud

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:file_picker/file_picker.dart';

class PcImages extends StatefulWidget {
  const PcImages({super.key});

  @override
  State<PcImages> createState() => _PcImagesState();
}

class _PcImagesState extends State<PcImages> {
  final _picker = ImagePicker();
  late Cloudinary cloudinary;
  List _buildingImages = [];
  late String? pdfFile;

  Future<void> _pickBuildingImages() async {
    FilePickerResult? pdf = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    _buildingImages.add(pdf?.files.single.path!);
  }

  @override
  void initState() {
    super.initState();

    cloudinary = Cloudinary.signedConfig(
      apiKey: "119748286486841",
      apiSecret: "GS4oqjmKsv4eZ0Q8jX3-R-PjcsI",
      cloudName: "doobgg47q",
    );
  }

  Future<void> _uploadingImages() async {
    var images;
    int counter = 1;
    for (images in _buildingImages) {
      final response = await cloudinary.upload(
          file: images,
          resourceType: CloudinaryResourceType.auto,
          fileName: "Vedant's Building $counter",
          folder: "inheritance_building/Nazir Apts",
          progressCallback: (count, total) {
            print('Uploading image $count/$total');
          });
      counter++;

      if (response.isSuccessful) {
        print('Get your image from with ${response.secureUrl}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
              onPressed: _pickBuildingImages, child: Text("Select IMages")),
          ElevatedButton(
              onPressed: _uploadingImages, child: Text("Uploading Images"))
        ],
      ),
    );
  }
}
