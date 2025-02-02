import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_soc/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  static final Color primaryColor = Color(0xFFE94560);
  static final Color backgroundColor = Color(0xFF1A1A2E);

  User? currUser;
  late Cloudinary cloudinary;
  List<String> _wingOptions = [];
  bool _loadingWings = true;
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
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
  }

  String? validatePhoneNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Please enter phone number' : null;
    }

    String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanNumber)) {
      return 'Please enter a valid Indian mobile number';
    }

    return null;
  }

  Future<void> fetchWingOptions() async {
    try {
      setState(() {
        _loadingWings = true;
      });

      DocumentSnapshot buildingDoc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingIdController.text.trim())
          .get();

      if (buildingDoc.exists) {
        final data = buildingDoc.data() as Map<String, dynamic>;
        if (data.containsKey('wings')) {
          List<dynamic> wings = data['wings'];
          _wingOptions =
              wings.map((wing) => wing['wingName'] as String).toList();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching wings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loadingWings = false;
      });
    }
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
                color: Colors.white.withOpacity(0.1),
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
              color: Colors.white,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
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
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file, color: Colors.white),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _storeData() async {
    try {
      final floorNum = int.tryParse(floorNumberController.text) ?? 0;
      final familyMembers = int.tryParse(familyMembersController.text) ?? 0;

      bool isSec = false;

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
        'designation': isSec ? 4 : 0,
        'flatNumber': flatNumberController.text.trim(),
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
        'verifiedBy': isSec ? "Admin" : "",
        'verifiedDate': FieldValue.serverTimestamp(),
        'isVerified': isSec ? true : false,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isSecretary': isSec ? true : false,
        'deviceToken': "",
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
              possStatus = count / total;
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
          throw Exception('Building is yet to be verified!');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your Building name is ${buildData['buildingName']}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          isValidBuilding = true;
        });
        await fetchWingOptions();
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
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          animatedTexts: [
            WavyAnimatedText(
              'MySoc Registration',
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          isRepeatingAnimation: false,
        ),
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: AnimationLimiter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildProfilePhotoSection(),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: uploadProfilePhoto,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                child: Text("Upload Photo"),
                              ),
                              if (_profilePhotoURL != null)
                                Icon(Icons.done, color: Colors.white),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          enabled: isValidBuilding ? false : true,
                          controller: buildingIdController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Building ID",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.apartment,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter building ID';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: validateBuilding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text("Validate Building"),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: firstNameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "First Name",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.person,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Last Name",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.person_outline,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.phone,
                                color: Colors.white.withOpacity(0.7)),
                            helperText: 'Enter 10-digit mobile number',
                            counterText: "",
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                        TextFormField(
                          controller: otherPhoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Alternative Phone Number (Optional)",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.phone_android,
                                color: Colors.white.withOpacity(0.7)),
                            helperText: 'Enter 10-digit mobile number',
                            counterText: "",
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                          color: Colors.white.withOpacity(0.1),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Currently Residing:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Radio<bool>(
                                      value: true,
                                      groupValue: _currentlyResiding,
                                      activeColor: primaryColor,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _currentlyResiding = value!;
                                        });
                                      },
                                    ),
                                    Text('Yes',
                                        style: TextStyle(color: Colors.white)),
                                    SizedBox(width: 20),
                                    Radio<bool>(
                                      value: false,
                                      groupValue: _currentlyResiding,
                                      activeColor: primaryColor,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _currentlyResiding = value!;
                                        });
                                      },
                                    ),
                                    Text('No',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildSectionHeader('Residence Details'),
                        TextFormField(
                          controller: flatNumberController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Flat Number",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.home,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Floor Number",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.stairs,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter floor number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: wingController.text.isEmpty
                              ? null
                              : wingController.text,
                          dropdownColor: Color(0xFF1A1A2E),
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Wing",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.business,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          items: _loadingWings
                              ? [
                                  DropdownMenuItem(
                                      value: null,
                                      child: Text("Loading...",
                                          style:
                                              TextStyle(color: Colors.white)))
                                ]
                              : _wingOptions.map((String wing) {
                                  return DropdownMenuItem(
                                    value: wing,
                                    child: Text(wing,
                                        style: TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                          onChanged: isValidBuilding
                              ? (String? newValue) {
                                  setState(() {
                                    wingController.text = newValue ?? '';
                                  });
                                }
                              : null,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a wing';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: secondaryAddressController,
                          maxLines: 3,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Secondary Address (Optional)",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: Colors.white.withOpacity(0.7)),
                            alignLabelWithHint: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: familyMembersController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Number of Family Members",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.family_restroom,
                                color: Colors.white.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Aadhaar Number (Optional)",
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.credit_card,
                                color: Colors.white.withOpacity(0.7)),
                            helperText: 'Enter 12-digit Aadhaar number',
                            counterText: "",
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
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
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: primaryColor,
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
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: primaryColor,
                          ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: uploadUserDocs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text("Upload Documents"),
                        ),
                        SizedBox(height: 20),
                        _buildSectionHeader('Vehicle Information'),
                        SwitchListTile(
                          title: Text('Do you have a vehicle?',
                              style: TextStyle(color: Colors.white)),
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
                          activeColor: primaryColor,
                        ),
                        if (_hasVehicle && _vehicleCount < 3) ...[
                          Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            color: Colors.white.withOpacity(0.1),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedVehicleType,
                                    dropdownColor: Color(0xFF1A1A2E),
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle Type',
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                    ),
                                    items: ['Car', 'Scooter', 'Bicycle']
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type,
                                                  style: TextStyle(
                                                      color: Colors.white)),
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
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Vehicle Number',
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (vehicleNumberController
                                              .text.isNotEmpty &&
                                          _selectedVehicleType != null) {
                                        setState(() {
                                          _vehicles.add({
                                            'type': _selectedVehicleType!,
                                            'number':
                                                vehicleNumberController.text,
                                          });
                                          vehicleNumberController.clear();
                                          _selectedVehicleType = null;
                                          _vehicleCount++;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
                                      backgroundColor: primaryColor,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_vehicles.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            'Added Vehicles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                color: Colors.white.withOpacity(0.1),
                                child: ListTile(
                                  leading: Icon(
                                    vehicle['type'] == 'Car'
                                        ? Icons.directions_car
                                        : vehicle['type'] == 'Scooter'
                                            ? Icons.two_wheeler
                                            : Icons.pedal_bike,
                                    color: primaryColor,
                                  ),
                                  title: Text('${vehicle['type']}',
                                      style: TextStyle(color: Colors.white)),
                                  subtitle: Text('${vehicle['number']}',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.7))),
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
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
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
                              backgroundColor: primaryColor,
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
          ),
        ),
      ),
    );
  }
}
