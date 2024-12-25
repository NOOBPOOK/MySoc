import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_soc/routes.dart';

class UserRegistrationPage extends StatefulWidget {
  const UserRegistrationPage({super.key});

  @override
  _UserRegistrationPageState createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otherPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController flatNumberController = TextEditingController();
  final TextEditingController floorNumberController = TextEditingController();
  final TextEditingController wingController = TextEditingController();
  final TextEditingController familyMembersController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController secondaryAddressController =
      TextEditingController();
  final TextEditingController buildingIdController = TextEditingController();
  bool _currentlyResiding = true;

  File? _profilePhoto;
  dynamic _profilePhotoURL;
  final _picker = ImagePicker();

  File? _possessionCertificate;
  File? _utilityBill;
  String? _possessionCertificateURL;
  String? _utilityBillURL;
  bool _hasVehicle = false;
  List<Map<String, String>> _vehicles = [];
  String? _selectedVehicleType;
  int _vehicleCount = 0;

  bool isValidBuilding = false;
  late Map buildData;

  // Theme Variables
  static final Color primaryColor = Colors.blue;
  static final Color backgroundColor = Colors.blue[50]!;

  User? currUser;
  late Cloudinary cloudinary;

  // For dynamic uplaod status
  double possStatus = 0.0;
  double utiStatus = 0.0;

  @override
  void initState() {
    super.initState();

    if (FirebaseAuth.instance.currentUser != null) {
      currUser = FirebaseAuth.instance.currentUser;
    } else {
      print('User is not currently signed in!');
    }

    cloudinary = Cloudinary.signedConfig(
      apiKey: "119748286486841",
      apiSecret: "GS4oqjmKsv4eZ0Q8jX3-R-PjcsI",
      cloudName: "doobgg47q",
    );
  }

  // Enhanced phone number validation
  String? validatePhoneNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Please enter phone number' : null;
    }

    // Remove any spaces or special characters
    String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanNumber)) {
      return 'Please enter a valid Indian mobile number';
    }

    return null;
  }

  Future<void> _pickProfilePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _profilePhoto = File(pickedFile.path);
      });
    }
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Profile Photo'),
        Center(
          child: GestureDetector(
            onTap: _pickProfilePhoto,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _profilePhoto != null
                  ? ClipOval(
                      child: Image.file(
                        _profilePhoto!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: primaryColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_profilePhoto != null)
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _profilePhoto = null;
                  _profilePhotoURL = null;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Remove Photo'),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        if (fileType == 'possession') {
          _possessionCertificate = File(result.files.single.path!);
        } else if (fileType == 'utility') {
          _utilityBill = File(result.files.single.path!);
        }
      });
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

  Widget _buildFileUploadButton(String title, File? file, Function() onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Colors.blue[700]),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (file != null)
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              'File selected: ${file.path.split('/').last}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _storeData() async {
    try {
      // Validate numeric inputs
      final floorNum = int.tryParse(floorNumberController.text) ?? 0;
      final familyMembers = int.tryParse(familyMembersController.text) ?? 0;

      bool isSec = false;

      //Check if building is valid
      if (isValidBuilding == false) {
        throw Exception('Please refer to a valid building');
      }

      if (floorNum <= 0 || familyMembers <= 0) {
        throw FormatException('Please enter valid numeric values');
      }

      if (currUser?.email == buildData['email']) {
        isSec = true;
      }

      await FirebaseFirestore.instance.collection('users').add({
        'buildingId': buildingIdController.text,
        'currentlyResiding': _currentlyResiding,
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'phone': phoneController.text,
        'otherPhone': otherPhoneController.text.isNotEmpty
            ? otherPhoneController.text
            : null,
        'email': currUser?.email,
        'flatNumber': flatNumberController.text,
        'floorNumber': int.parse(floorNumberController.text),
        'wing': wingController.text,
        'familyMembers': int.parse(familyMembersController.text),
        'possessionCertificate': _possessionCertificateURL,
        'utilityBill': _utilityBillURL,
        'vehicles': _vehicles,
        'profilePhotoPath': _profilePhotoURL,
        'aadharNumber':
            aadharController.text.isNotEmpty ? aadharController.text : null,
        'secondaryAddress': secondaryAddressController.text.isNotEmpty
            ? secondaryAddressController.text
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedBy': "Admin",
        'verifiedDate': FieldValue.serverTimestamp(),
        'isVerified': isSec ? true : false,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isSecretary': isSec ? true : false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(Duration(seconds: 5), () {
        Navigator.pushNamedAndRemoveUntil(
            context, MySocRoutes.loginRoute, (route) => false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> uploadProfilePhoto() async {
    try {
      if (_profilePhoto == null) {
        throw Exception('Please choose a photo first');
      }
      final response = await cloudinary.upload(
          file: _profilePhoto!.path,
          resourceType: CloudinaryResourceType.image,
          folder: "inheritance_user_images",
          progressCallback: (count, total) {
            print('Uploading image $count/$total');
          });

      if (response.isSuccessful) {
        _profilePhotoURL = response.secureUrl.toString();
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

  Future<void> uploadUserDocs() async {
    try {
      if (_possessionCertificate == null || _utilityBill == null) {
        throw Exception('Please upload the necessary pfs');
      }
      final possDoc = await cloudinary.upload(
          file: _possessionCertificate?.path,
          resourceType: CloudinaryResourceType.auto,
          folder: "inheritance_user_pdfs",
          progressCallback: (count, total) {
            setState(() {
              print(count);
              possStatus = count / total;
              print(possStatus);
            });
          });
      if (possDoc.isSuccessful) {
        _possessionCertificateURL = possDoc.secureUrl.toString();
      }

      final utiCert = await cloudinary.upload(
          file: _utilityBill?.path,
          resourceType: CloudinaryResourceType.auto,
          folder: "inheritance_user_pdfs",
          progressCallback: (count, total) {
            setState(() {
              print(count);
              utiStatus = count / total;
            });
          });
      if (utiCert.isSuccessful) {
        _utilityBillURL = utiCert.secureUrl.toString();
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

  Future<void> validateBuilding() async {
    try {
      DocumentSnapshot build = await FirebaseFirestore.instance
          .collection("buildings")
          .doc(buildingIdController.text.trim())
          .get();
      if (build.exists) {
        buildData = build.data() as Map<String, dynamic>;
        if (buildData['isVerified'] == false) {
          throw Exception('Builiding is yet to be verified!');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your Building name is ${buildData['buildingName']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isValidBuilding = true;
        });
      } else {
        throw Exception('Invalid Building ID');
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
    print(_profilePhotoURL);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "MySoc Registration",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1565C0), // Custom blue color
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
                  _buildProfilePhotoSection(),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: ElevatedButton(
                              onPressed: uploadProfilePhoto,
                              child: Text("Upload Photo")),
                        ),
                        if (_profilePhotoURL != null) Icon(Icons.done),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  TextFormField(
                    enabled: isValidBuilding ? false : true,
                    controller: buildingIdController,
                    decoration: InputDecoration(
                      labelText: "Building ID",
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter building ID';
                      }
                      return null;
                    },
                  ),

                  ElevatedButton(
                      onPressed: validateBuilding,
                      child: Text("Validate Building")),

                  SizedBox(height: 16),

                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: "First Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: "Last Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(Icons.phone),
                      helperText: 'Enter 10-digit mobile number',
                      counterText: "", // Hides the built-in counter
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length != 10) {
                        return 'Phone number must be 10 digits';
                      }
                      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                        return 'Please enter a valid Indian mobile number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Alternative phone number (optional)
                  TextFormField(
                    controller: otherPhoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Alternative Phone Number (Optional)",
                      prefixIcon: Icon(Icons.phone_android),
                      helperText: 'Enter 10-digit mobile number',
                      counterText: "", // Hides the built-in counter
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                          return 'Please enter a valid Indian mobile number';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Currently Residing:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _currentlyResiding,
                                activeColor: Colors.blue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _currentlyResiding = value!;
                                  });
                                },
                              ),
                              Text('Yes'),
                              SizedBox(width: 20),
                              Radio<bool>(
                                value: false,
                                groupValue: _currentlyResiding,
                                activeColor: Colors.blue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _currentlyResiding = value!;
                                  });
                                },
                              ),
                              Text('No'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSectionHeader('Residence Details'),

                  TextFormField(
                    controller: flatNumberController,
                    decoration: InputDecoration(
                      labelText: "Flat Number",
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter flat number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: floorNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Floor Number",
                      prefixIcon: Icon(Icons.stairs),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter floor number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: wingController,
                    decoration: InputDecoration(
                      labelText: "Wing",
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter wing';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: secondaryAddressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Secondary Address (Optional)",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: familyMembersController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Family Members",
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the number of family members';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  TextFormField(
                    controller: aadharController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: "Aadhaar Number (Optional)",
                      prefixIcon: Icon(Icons.credit_card),
                      helperText: 'Enter 12-digit Aadhaar number',
                      counterText: "", // Hides the built-in counter
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 12) {
                          return 'Aadhaar number must be 12 digits';
                        }
                        if (!RegExp(r'^[0-9]{12}$').hasMatch(value)) {
                          return 'Please enter a valid Aadhaar number';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Owner Documents'),

                  _buildFileUploadButton(
                    'Upload Possession Certificate (PDF)',
                    _possessionCertificate,
                    () => _pickFile('possession'),
                  ),
                  if (possStatus != 0)
                    LinearProgressIndicator(
                      value: possStatus,
                    ),
                  SizedBox(height: 10),

                  _buildFileUploadButton(
                    'Upload Utility Bill (PDF)',
                    _utilityBill,
                    () => _pickFile('utility'),
                  ),
                  if (utiStatus != 0)
                    LinearProgressIndicator(
                      value: utiStatus,
                    ),

                  SizedBox(height: 20),

                  ElevatedButton(
                      onPressed: uploadUserDocs,
                      child: Text("Upload Documents")),

                  SizedBox(height: 20),

                  _buildSectionHeader('Vehicle Information'),

                  SwitchListTile(
                    title: Text('Do you have a vehicle?'),
                    value: _hasVehicle,
                    onChanged: (bool value) {
                      setState(() {
                        _hasVehicle = value;
                        if (!value) {
                          _vehicles.clear();
                          _vehicleCount = 0;
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),

                  if (_hasVehicle && _vehicleCount < 3) ...[
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedVehicleType,
                              decoration: InputDecoration(
                                labelText: 'Vehicle Type',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Car', 'Scooter', 'Bicycle']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedVehicleType = value;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: vehicleNumberController,
                              decoration: InputDecoration(
                                labelText: 'Vehicle Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (vehicleNumberController.text.isNotEmpty &&
                                    _selectedVehicleType != null) {
                                  setState(() {
                                    _vehicles.add({
                                      'type': _selectedVehicleType!,
                                      'number': vehicleNumberController.text,
                                    });
                                    vehicleNumberController.clear();
                                    _selectedVehicleType = null;
                                    _vehicleCount++;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please fill in all vehicle details'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Add Vehicle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Display added vehicles
                  if (_vehicles.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Added Vehicles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _vehicles[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Icon(
                              vehicle['type'] == 'Car'
                                  ? Icons.directions_car
                                  : vehicle['type'] == 'Scooter'
                                      ? Icons.two_wheeler
                                      : Icons.pedal_bike,
                              color: Colors.blue,
                            ),
                            title: Text('${vehicle['type']}'),
                            subtitle: Text('${vehicle['number']}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _vehicles.removeAt(index);
                                  _vehicleCount--;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Check if required documents are uploaded
                          if (_possessionCertificateURL == null ||
                              _utilityBillURL == null) {
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
                          'Submit Registration',
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
