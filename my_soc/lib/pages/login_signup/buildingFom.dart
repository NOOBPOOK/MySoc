import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_soc/pages/login_signup/chooseMap.dart';
import 'package:my_soc/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WingDetails {
  String wingName;

  WingDetails({
    required this.wingName,
  });

  Map<String, dynamic> toMap() {
    return {
      'wingName': wingName,
    };
  }
}

class BuildingRegistrationPage extends StatefulWidget {
  const BuildingRegistrationPage({super.key});

  @override
  _BuildingRegistrationPageState createState() =>
      _BuildingRegistrationPageState();
}

class _BuildingRegistrationPageState extends State<BuildingRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController streetNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController constructionYearController =
      TextEditingController();
  final TextEditingController totalFlatsController = TextEditingController();
  final TextEditingController totalWingsController = TextEditingController();
  final TextEditingController buildingAreaController = TextEditingController();
  final TextEditingController maintenanceContactController =
      TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
  final TextEditingController parkingSpacesController = TextEditingController();
  final TextEditingController numberOfWingsController = TextEditingController();
  List<WingDetails> wings = [];
  bool isSubmitting = false;

  // Colors for theme styling
  static final Color primaryColor = Colors.blue;
  static final Color backgroundColor = Colors.blue[50]!;

  // Files and Images
  List<File> _buildingImages = [];
  List<String> _buildingImagesURL = [];
  String? _registrationDoc;
  String? _occupancyCertificate;
  String? _registrationDocURL;
  String? _occupancyCertificateURL;
  final _picker = ImagePicker();
  late Cloudinary cloudinary;
  // Location
  LatLng current_location = LatLng(37.49, -122.45);
  late GoogleMapController _mapController;

  // Building amenities
  List<String> _amenities = [];
  final List<String> _availableAmenities = [
    'Elevator',
    'Parking',
    'Security',
    'Generator Backup',
    'Fire Safety System',
    'CCTV',
    'Swimming Pool',
    'Gym',
    'Community Hall',
    'Garden',
    'Play Area',
    'Rainwater Harvesting'
  ];
  User? currUser;
  double imageUploadStatus = 0.0;
  double regStatus = 0.0;
  double occStatus = 0.0;

  @override
  void initState() {
    super.initState();

    if (FirebaseAuth.instance.currentUser != null) {
      currUser = FirebaseAuth.instance.currentUser;
    } else {
      print('User is not currently signed in!');
    }

    cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
  }

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

  Future<void> _uploadImages() async {
    try {
      if (_buildingImages.length < 5) {
        throw Exception('Please select atleast 5 images');
      }
      var image_path;
      var c = 0;
      var total = _buildingImages.length;
      for (image_path in _buildingImages) {
        final response = await cloudinary.upload(
            file: image_path.path,
            resourceType: CloudinaryResourceType.image,
            folder: "inheritance_building_images",
            progressCallback: (count, total) {
              print('Uploading image $count/$total');
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

  Future<void> _pickDocument(String docType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        if (docType == 'registration') {
          _registrationDoc = result.files.single.path!;
        } else if (docType == 'occupancy') {
          _occupancyCertificate = result.files.single.path!;
        }
      });
    }
  }

  Future<void> _uploadDocuments() async {
    try {
      if (_registrationDoc == null || _occupancyCertificate == null) {
        throw Exception('Please upload the required documents');
      }
      final regDoc = await cloudinary.upload(
          file: _registrationDoc,
          resourceType: CloudinaryResourceType.auto,
          folder: "inheritance_building_pdfs",
          progressCallback: (count, total) {
            setState(() {
              regStatus = count / total;
            });
          });
      if (regDoc.isSuccessful) {
        _registrationDocURL = regDoc.secureUrl;
      }

      final ocuCert = await cloudinary.upload(
          file: _occupancyCertificate,
          resourceType: CloudinaryResourceType.auto,
          folder: "inheritance_building_pdfs",
          progressCallback: (count, total) {
            setState(() {
              occStatus = count / total;
            });
          });
      if (ocuCert.isSuccessful) {
        _occupancyCertificateURL = ocuCert.secureUrl;
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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

  Future<void> _storeData() async {
    try {
      // Store building data in Firestore
      List<Map<String, dynamic>> wingData =
          wings.map((wing) => wing.toMap()).toList();
      await FirebaseFirestore.instance.collection('buildings').add({
        'email': currUser?.email,
        'buildingName': buildingNameController.text,
        'streetName': streetNameController.text,
        'city': cityController.text,
        'state': stateController.text,
        'landmark': landmarkController.text,
        'constructionYear': int.tryParse(constructionYearController.text) ?? 0,
        'totalFlats': int.tryParse(totalFlatsController.text) ?? 0,
        'buildingArea': double.tryParse(buildingAreaController.text) ?? 0,
        'maintenanceContact': null,
        'emergencyContact': null,
        'amenities': _amenities,
        'location':
            GeoPoint(current_location.latitude, current_location.longitude),
        'registrationDocPath': _registrationDocURL,
        'occupancyCertificatePath': _occupancyCertificateURL,
        'buildingImagePaths': _buildingImagesURL.toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'wings': wingData,
        'numberOfWings': wings.length,
        'isVerified': false, // Initial verification status
        'verificationDate': null,
        'verifiedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'services': [],
        'isRejected': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Building registered successfully! Awaiting verification.'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 5), () {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(MySocRoutes.loginRoute, (route) => false);
      });

      // Clear form or navigate away
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Widget _buildWingDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Wing Details'),

        TextFormField(
          controller: numberOfWingsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Number of Wings',
            prefixIcon: Icon(Icons.business),
            helperText: 'Enter total number of wings in the building',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of wings';
            }
            if (int.tryParse(value) == null || int.parse(value) <= 0) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) {
            int wingCount = int.tryParse(value) ?? 0;
            setState(() {
              if (wingCount > wings.length) {
                // Add new wings with default alphabetical names
                for (int i = wings.length; i < wingCount; i++) {
                  wings.add(WingDetails(
                    wingName: String.fromCharCode(65 + i), // A, B, C, etc.
                  ));
                }
              } else if (wingCount < wings.length) {
                // Remove wings
                wings = wings.sublist(0, wingCount);
              }
            });
          },
        ),
        SizedBox(height: 20),

        // Display wing name inputs
        ...List.generate(
          wings.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: TextFormField(
              initialValue: wings[index].wingName,
              decoration: InputDecoration(
                labelText: 'Wing ${index + 1} Name',
                prefixIcon: Icon(Icons.drive_file_rename_outline),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              onChanged: (value) {
                setState(() {
                  wings[index].wingName = value;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void movePointer(LatLng newPosition) {
    setState(() {
      current_location = newPosition;
    });
  }

  void getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission ask = await Geolocator.requestPermission();
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition();

      setState(() {
        current_location =
            LatLng(currentPosition.latitude, currentPosition.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Building Registration",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1565C0),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSectionHeader('Basic Information'),

                  TextFormField(
                    controller: buildingNameController,
                    decoration: InputDecoration(
                      labelText: "Building Name",
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter building name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: streetNameController,
                    decoration: InputDecoration(
                      labelText: "Street Name",
                      prefixIcon: Icon(Icons.aod),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter street name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: "City",
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter city';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: InputDecoration(
                            labelText: "State",
                            prefixIcon: Icon(Icons.map),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter state';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  TextFormField(
                    controller: landmarkController,
                    decoration: InputDecoration(
                      labelText: "Landmark (Optional)",
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Building Details'),

                  TextFormField(
                    controller: constructionYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Construction Year",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter construction year';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: totalFlatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Total Flats",
                            prefixIcon: Icon(Icons.stairs),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                    ],
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: buildingAreaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Total Built-up Area (sq ft)",
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter built-up area';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  _buildWingDetailsSection(),
                  _buildSectionHeader('Building Images'),
                  _buildImageGrid(),
                  if (imageUploadStatus != 0.0)
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: LinearProgressIndicator(
                        value: imageUploadStatus,
                      ),
                    ),
                  ElevatedButton(
                      onPressed: _uploadImages, child: Text("Upload Images")),
                  SizedBox(height: 20),

                  _buildSectionHeader('Building Documents'),
                  ElevatedButton.icon(
                    onPressed: () => _pickDocument('registration'),
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Registration Document'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (_registrationDoc != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Registration document uploaded: ',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  if (regStatus != 0.0)
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: LinearProgressIndicator(
                        value: regStatus,
                      ),
                    ),
                  SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () => _pickDocument('occupancy'),
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Occupancy Certificate'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (_occupancyCertificate != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Occupancy certificate uploaded:',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),

                  if (occStatus != 0.0)
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: LinearProgressIndicator(
                        value: occStatus,
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: _uploadDocuments,
                        child: Text("Upload Docs")),
                  ),

                  SizedBox(height: 20),

                  _buildSectionHeader('Facilities & Amenities'),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _amenities.add(amenity);
                            } else {
                              _amenities.remove(amenity);
                            }
                          });
                        },
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  _buildSectionHeader('Location Information'),
                  SizedBox(height: 20),

                  ElevatedButton(
                      onPressed: () async {
                        final location = await Navigator.pushNamed(
                                context, MySocRoutes.formMaps,
                                arguments: {'location': current_location})
                            as LatLng;
                        setState(() {
                          current_location = location;
                        });
                      },
                      child: Text("Current Location $current_location")),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Validation checks
                          if (_buildingImages.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please add at least one building image'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (_registrationDoc == null ||
                              _occupancyCertificate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please upload all required documents'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          _storeData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Submit Building Registration',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
