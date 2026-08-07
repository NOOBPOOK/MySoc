import 'dart:math';
import 'dart:io';
import 'package:my_soc/utils/compress.dart';
import 'package:wave/wave.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_soc/authentication/login.dart';
import 'package:my_soc/widgets/progressBar.dart';
import 'package:my_soc/widgets/uploadButton.dart';
import 'package:page_transition/page_transition.dart';
// import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_soc/routes.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wave/config.dart';

class DigitLimitFormatter extends TextInputFormatter {
  final int maxLength;

  DigitLimitFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > maxLength) {
      return oldValue;
    }
    return newValue;
  }
}

class Userform extends StatefulWidget {
  const Userform({super.key});

  @override
  State<Userform> createState() => _BuildformState();
}

class _BuildformState extends State<Userform> {
  // bool isSecured = true;
  // bool userAgreement = false;

  // TextEditingController username = TextEditingController();
  // TextEditingController passwd = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  TextEditingController buildId = TextEditingController();

  final _formkey2 = GlobalKey<FormState>();
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  TextEditingController phnNumber = TextEditingController();
  TextEditingController altphnNumber = TextEditingController();
  String? currentlyResiding = '';
  final _Imagepicker = ImagePicker();
  File? profilePhoto;
  UploadTask? profileUpload;
  bool isProfileUploding = false;
  String? profilePhotoURL;

  final _formkey3 = GlobalKey<FormState>();
  TextEditingController flatNumber = TextEditingController();
  TextEditingController secondaryAddress = TextEditingController();
  TextEditingController noFmailyMem = TextEditingController();
  TextEditingController aadharNum = TextEditingController();

  File? _possessionCertificate;
  File? _utilityBill;
  String? _possessionCertificateURL;
  String? _utilityBillURL;
  UploadTask? _possessionUpload;
  UploadTask? _utilityUpload;
  double? _possessionUploadPercentage;
  double? _utilityUploadPercentage;

  double progress = 00;
  bool isValid = false;
  late Map buildData;

  String buildAddress = '';
  String buildEmail = '';
  String buildName = '';

  // For form page Handling
  final PageController _pageController = PageController(initialPage: 0);
  bool isBigForm = false;
  int _currentPage = 0;

  // Variables for handling Possession Upload Button
  String PossessionbuttonText = "Upload";
  double possessionButtonHeight = 50;
  double possessionButtonWidth = 130;
  double possessionButtonScale = 20;
  double possessionButtonCurve = 25;
  double possessionButtonWave = 50;

  // Variables for handling Utility Upload Button
  String utilitybuttonText = "Upload";
  double utilityButtonHeight = 50;
  double utilityButtonWidth = 130;
  double utilityButtonScale = 20;
  double utilityButtonCurve = 25;
  double utilityButtonWave = 50;

  // Values used by both the buttons
  static const _backgroundColor = Color(0xFFF15BB5);
  static const _colors = [
    Color(0xFF00BBF9),
  ];
  static const _durations = [
    3000,
  ];

  // Function for picking images from the gallery
  Future<void> _pickProfilePhoto() async {
    profilePhotoURL = null;
    final pickedFile = await _Imagepicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        profilePhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _profilePhotoUpload() async {
    // Specifying the path where the image is to be stored
    final store = 'Profiles/';

    // Generating a unique file name using UUID
    const uuid = Uuid();
    // final fileExtension = profilePhoto!.path.split('.').last;
    final uniquename = '${uuid.v4()}.jpg';

    final ref = FirebaseStorage.instance.ref().child('$store/$uniquename');
    profileUpload = ref.putFile(profilePhoto!);

    final snapshot = await profileUpload!.whenComplete(() {});
    profilePhotoURL = await snapshot.ref.getDownloadURL();
    print('Dowload Url is $profilePhotoURL');
    isProfileUploding = false;
    setState(() {});
  }

  Widget _buildFirstPage() {
    // print(displayheight);

    return Container(
      // height: ,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            if (!isValid)
              SizedBox(
                height: 60,
              ),
            if (isValid)
              SizedBox(
                height: 20,
              ),
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Color(0xFF5C6699)),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 5,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
              child: Text(
                "Building ID",
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFFB8425F)),
              ),
            ),
            Form(
              key: _formkey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: TextFormField(
                  enabled: !isValid,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your building ID";
                    }
                    return null;
                  },
                  controller: buildId,
                  decoration: InputDecoration(
                    helperText: " ",
                    hintText: "Enter your building ID",
                    hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w300,
                        fontSize: 15),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13), // Rounded border
                      borderSide: BorderSide(color: Color(0xFFACACAC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(
                          color: Colors.red,
                          width: 2), // Blue border when focused
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formkey.currentState!.validate()) {
                      await validateBuilding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(280, 40),
                      backgroundColor: Color(0xFF222A54)),
                  child: Text(
                    "Validate",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
            SizedBox(
              height: 15,
            ),
            if (isValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 227, 237, 255),
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildName,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB8425F)),
                        ),
                        Divider(
                          color: Color.fromARGB(255, 127, 174, 255),
                          thickness: 1,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: Color(0xFF5C6699),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              buildAddress,
                              style: TextStyle(
                                  color: Color(0xFF5C6699),
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Icon(Icons.email, color: Color(0xFF5C6699)),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              buildEmail,
                              style: TextStyle(
                                  color: Color(0xFF5C6699),
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Icon(Icons.verified_outlined,
                                color: Color(0xFF5C6699)),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "MySOC Admin",
                              style: TextStyle(
                                  color: Color(0xFF5C6699),
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (isValid)
              SizedBox(
                height: 20,
              ),
            if (isValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      progress += 25;
                      isBigForm = true;
                    });
                    _pageController.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeIn);
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(280, 40),
                      backgroundColor: Color(0xFF222A54)),
                  child: Text(
                    "Next",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondPage(context) {
    return Form(
      key: _formkey2,
      child: Container(
        // height: 100,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // shrinkWrap: true,
              children: [
                Container(
                  width: double.infinity,
                  // height: MediaQuery.of(context).size.height,
                  child: Text(
                    "Profile Information",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF49548D)),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                _buildProfileSection(),
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  "First Name",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your First Name";
                        }
                        return null;
                      },
                      controller: firstName,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Your First Name",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  "Last Name",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your Last Name";
                        }
                        return null;
                      },
                      controller: lastName,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Your Last Name",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                // SizedBox(
                //   height: 10,
                // ),
                Text(
                  "Phone",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      inputFormatters: [
                        DigitLimitFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your Phone Number";
                        }
                        return null;
                      },
                      controller: phnNumber,
                      keyboardType: TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.call,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Your Phone Number",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Alternate Phone Number",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      inputFormatters: [
                        DigitLimitFormatter(10),
                      ],
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: altphnNumber,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.call,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Alternate Name",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                // SizedBox(
                //   height: 10,
                // ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color.fromARGB(255, 219, 232, 255)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                          child: Text(
                            "Currently Residing",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF222A54),
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Row(
                          children: [
                            Radio(
                                activeColor: Color.fromARGB(255, 191, 121, 156),
                                value: 'Yes',
                                groupValue: currentlyResiding,
                                onChanged: (String? value) {
                                  setState(() {
                                    currentlyResiding = value!;
                                  });
                                }),
                            Text("Yes"),
                            SizedBox(
                              width: 20,
                            ),
                            Radio(
                                activeColor: Color.fromARGB(255, 191, 121, 156),
                                // focusColor: Color.fromARGB(255, 191, 121, 156),
                                value: 'No',
                                groupValue: currentlyResiding,
                                onChanged: (String? value) {
                                  setState(() {
                                    currentlyResiding = value!;
                                  });
                                }),
                            Text("No")
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      // For now Forms Validation is disabled for testing
                      if (!_formkey2.currentState!.validate()) {
                        // Validation manipulated for easy testing
                        if ((currentlyResiding!.isNotEmpty) &&
                            (profilePhotoURL == null)) {
                          setState(() {
                            progress += 25;
                          });
                          _pageController.nextPage(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeIn);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        fixedSize: Size(280, 40),
                        backgroundColor: Color(0xFF222A54)),
                    child: Text(
                      "Next",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (profilePhoto != null && profilePhotoURL == null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: GestureDetector(
                  onTap: () async {
                    isProfileUploding = true;
                    setState(() {});
                    profilePhoto = await compressImage(profilePhoto);
                    _profilePhotoUpload();
                  },
                  child: Container(
                    child: Icon(
                      // weight: 100.00,
                      size: 30,
                      Icons.check,
                      color: Colors.green,
                    ),
                  )),
            ),
          ),
        Center(
          child: GestureDetector(
            onTap: isProfileUploding ? null : _pickProfilePhoto,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Color(0xFFECEFF3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFECEFF3),
                  width: 2,
                ),
              ),
              child: profilePhoto != null
                  ? ClipOval(
                      child: Stack(
                        children: [
                          Image.file(
                            profilePhoto!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                          if (isProfileUploding)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          if (isProfileUploding)
                            Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            )
                        ],
                      ),
                    )
                  : Stack(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Icon(
                            color: Color(0xFFC1C7D0),
                            Icons.person,
                            size: 40,
                            // color: primaryColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (profilePhoto != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: GestureDetector(
                  onTap: () {
                    setState(() {
                      profilePhoto = null;
                      profilePhotoURL = null;
                    });
                  },
                  child: Container(
                    child: Icon(
                      // weight: 90,
                      size: 30,
                      Icons.close,
                      color: Colors.redAccent,
                    ),
                  )),
            ),
          ),
      ],
    );
  }

  Widget _buildThirdPage() {
    return Form(
      key: _formkey3,
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  // height: MediaQuery.of(context).size.height,
                  child: Text(
                    "Resedential Details",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Color(0xFF49548D)),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Flat Number",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your Flat Number";
                        }
                        return null;
                      },
                      controller: flatNumber,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.home,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Your Flat Number",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Wing",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your Wing";
                        }
                        return null;
                      },
                      controller: flatNumber,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.apartment,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Select Your Wing",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Secondary Address",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: TextFormField(
                    controller: secondaryAddress,
                    maxLines: 3,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.home,
                        color: Color(0xFF49548D),
                      ),
                      helperText: " ",
                      hintText: "Secondary Address (Optional)",
                      hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w300,
                          fontSize: 15),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(13), // Rounded border
                        borderSide: BorderSide(color: Color(0xFFACACAC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(
                            color: Colors.red,
                            width: 2), // Blue border when focused
                      ),
                    ),
                  ),
                ),
                Text(
                  "Number of Family Members",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter number of family members";
                        }
                        return null;
                      },
                      controller: noFmailyMem,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.home,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "No of Family Members",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Aadhaar Number",
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFB8425F)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: SizedBox(
                    height: 61,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length != 12) {
                          return "Please enter your 12 digit Aadhar Number";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(),
                      inputFormatters: [DigitLimitFormatter(12)],
                      controller: aadharNum,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.document_scanner,
                          color: Color(0xFF49548D),
                        ),
                        helperText: " ",
                        hintText: "Aadhar Number",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w300,
                            fontSize: 15),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(13), // Rounded border
                          borderSide: BorderSide(color: Color(0xFFACACAC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                              color: Colors.red,
                              width: 2), // Blue border when focused
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      // For now Form Validation is disabled for testing
                      if (!_formkey3.currentState!.validate()) {
                        setState(() {
                          progress += 25;
                        });
                        _pageController.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        fixedSize: Size(280, 40),
                        backgroundColor: Color(0xFF222A54)),
                    child: Text(
                      "Next",
                      style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForthPage() {
    return Container(
      // height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                // height: MediaQuery.of(context).size.height,
                child: Text(
                  "Upload Documents",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Color(0xFF49548D)),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                    color: Color(0xFF5C6699)),
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  _pickFile('possession');
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Shadow color
                          blurRadius: 2, // Softness of the shadow
                          spreadRadius: 2, // How much the shadow should spread
                          offset: Offset(5, 5), // Position of the shadow (X, Y)
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xFFB3CFFF)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Color(0xFF49548D),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Possession Certificate (Pdf)",
                              style: TextStyle(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFF49548D)),
                            ),
                            if (_possessionCertificate != null)
                              Text(
                                p.basename(_possessionCertificate!.path),
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFF49548D)),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildPossessionButton()),
              SizedBox(
                height: 30,
              ),
              Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                    color: Color(0xFF5C6699)),
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  _pickFile('utility');
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Shadow color
                          blurRadius: 2, // Softness of the shadow
                          spreadRadius: 2, // How much the shadow should spread
                          offset: Offset(5, 5), // Position of the shadow (X, Y)
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xFFB3CFFF)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: Color(0xFF49548D),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Utility Bill (Pdf)",
                              style: TextStyle(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFF49548D)),
                            ),
                            if (_utilityBill != null)
                              Text(
                                p.basename(_utilityBill!.path),
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFF49548D)),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildUtilityButton(),
              ),
              SizedBox(
                height: 120,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Validation inverted because of testing
                    if (_possessionCertificateURL == null &&
                        _utilityBillURL == null) {
                      setState(() {
                        progress += 25;
                        isBigForm = true;
                      });
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    } else {
                      // Please upload the necessary documents first to proceed ahead
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(280, 40),
                      backgroundColor: Color(0xFF222A54)),
                  child: Text(
                    "Next",
                    style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPossessionButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (_possessionCertificate != null &&
              _possessionCertificateURL == null) {
            setState(() {
              if (PossessionbuttonText == 'Upload') {
                possessionButtonHeight +=
                    possessionButtonHeight * possessionButtonScale / 100;
                possessionButtonWidth +=
                    possessionButtonWidth * possessionButtonScale / 100;
                possessionButtonCurve = possessionButtonHeight / 2;
                PossessionbuttonText = 'Uploading...';
              }
            });
            print("Hello");
            // Uploading the file to the Google Stoarge
            try {
              final store = 'UserDocs/';
              const uuid = Uuid();
              final fileExtension =
                  _possessionCertificate!.path.split('.').last;
              final uniquename = '${uuid.v4()}.$fileExtension';
              final ref =
                  FirebaseStorage.instance.ref().child('$store/$uniquename');
              _possessionUpload = ref.putFile(_possessionCertificate!);

              // For showing Updation of the progress made
              _possessionUpload!.snapshotEvents.listen((TaskSnapshot snapshot) {
                setState(() {
                  _possessionUploadPercentage =
                      (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                  possessionButtonWave = possessionButtonHeight -
                      (_possessionUploadPercentage! *
                          possessionButtonHeight /
                          100);
                  print(_utilityUploadPercentage);
                });
              }, onError: (error) {
                print(error);
              }, onDone: () {
                setState(() async {
                  PossessionbuttonText = "Uploaded";
                  _possessionCertificateURL = await ref.getDownloadURL();
                  print('Download is $_possessionCertificateURL');
                });
              });
            } catch (e) {
              print('Encountered an error $e');
            }
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: possessionButtonHeight,
          width: possessionButtonWidth,
          curve: Curves.bounceOut,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(possessionButtonCurve),
              color: Colors.amber),
          child: Stack(
            children: [
              if (PossessionbuttonText == 'Uploading...')
                ClipRRect(
                  borderRadius: BorderRadius.circular(possessionButtonCurve),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        color: Colors.amber,
                        height: possessionButtonWave,
                      ),
                      Expanded(
                        child: WaveWidget(
                          config: CustomConfig(
                            colors: _colors,
                            durations: _durations,
                            heightPercentages: [0.05],
                          ),
                          backgroundColor: Colors.amber,
                          size: Size(double.infinity, double.infinity),
                          waveAmplitude: 0.0,
                          waveFrequency: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (PossessionbuttonText == "Uploaded")
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded),
                    ),
                  Text(PossessionbuttonText),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (_utilityBill != null && _utilityBillURL == null) {
            setState(() {
              if (utilitybuttonText == 'Upload') {
                utilityButtonHeight +=
                    utilityButtonHeight * utilityButtonScale / 100;
                utilityButtonWidth +=
                    utilityButtonWidth * utilityButtonScale / 100;
                utilityButtonCurve = utilityButtonHeight / 2;
                utilitybuttonText = 'Uploading...';
              }
            });
            print("Hello");
            // Uploading the file to the Google Stoarge
            try {
              final store = 'UserDocs/';
              const uuid = Uuid();
              final fileExtension = _utilityBill!.path.split('.').last;
              final uniquename = '${uuid.v4()}.$fileExtension';
              final ref =
                  FirebaseStorage.instance.ref().child('$store/$uniquename');
              _utilityUpload = ref.putFile(_utilityBill!);

              // For showing Updation of the progress made
              _utilityUpload!.snapshotEvents.listen((TaskSnapshot snapshot) {
                setState(() {
                  _utilityUploadPercentage =
                      (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                  utilityButtonWave = utilityButtonHeight -
                      (_utilityUploadPercentage! * utilityButtonHeight / 100);
                  print(_utilityUploadPercentage);
                });
              }, onError: (error) {
                print(error);
              }, onDone: () {
                setState(() async {
                  utilitybuttonText = "Uploaded";
                  _utilityBillURL = await ref.getDownloadURL();
                  print('Download is $_utilityBillURL');
                });
              });
            } catch (e) {
              print('Encountered an error $e');
            }
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: utilityButtonHeight,
          width: utilityButtonWidth,
          curve: Curves.bounceOut,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(utilityButtonCurve),
              color: Colors.amber),
          child: Stack(
            children: [
              if (utilitybuttonText == 'Uploading...')
                ClipRRect(
                  borderRadius: BorderRadius.circular(utilityButtonCurve),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        color: Colors.amber,
                        height: utilityButtonWave,
                      ),
                      Expanded(
                        child: WaveWidget(
                          config: CustomConfig(
                            colors: _colors,
                            durations: _durations,
                            heightPercentages: [0.05],
                          ),
                          backgroundColor: Colors.amber,
                          size: Size(double.infinity, double.infinity),
                          waveAmplitude: 0.0,
                          waveFrequency: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (utilitybuttonText == "Uploaded")
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded),
                    ),
                  Text(utilitybuttonText),
                ],
              ))
            ],
          ),
        ),
      ),
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
          _possessionCertificateURL = null;
          possessionButtonHeight = 50;
          possessionButtonWidth = 130;
          possessionButtonScale = 20;
          possessionButtonCurve = 25;
          possessionButtonWave = 50;
          PossessionbuttonText = "Upload";
          _possessionUpload = null;
          _possessionUploadPercentage = null;
        } else if (fileType == 'utility') {
          _utilityBill = File(result.files.single.path!);
          _utilityBillURL = null;
          utilityButtonHeight = 50;
          utilityButtonWidth = 130;
          utilityButtonScale = 20;
          utilityButtonCurve = 25;
          utilityButtonWave = 50;
          _utilityUpload = null;
          utilitybuttonText = "Upload";
          _utilityUploadPercentage = null;
        }
      });
    }
  }

  Future<void> validateBuilding() async {
    try {
      DocumentSnapshot build = await FirebaseFirestore.instance
          .collection("buildings")
          .doc(buildId.text.trim())
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
          buildName = buildData['buildingName'];
          buildAddress = " ${buildData['streetName']} ${buildData['city']}";
          buildEmail = buildData['email'];
          isValid = true;
        });
        // await fetchWingOptions();
      } else {
        throw Exception('Invalid Building ID');
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('$e'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double pageHeight = 50;
    if (!isBigForm) {
      pageHeight = MediaQuery.of(context).size.height * 0.25;
    }

    double currentHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;

    // if (!isBigForm) {
    //   currentHeight -= MediaQuery.of(context).size.height * 0.25;
    // }

    // print(currentHeight);

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: currentHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF222A54), Color(0xFFCE798E)],
          ),
        ),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              child: Center(
                child: Text(
                  "MySoc",
                  style: TextStyle(
                      fontFamily: "Readex Pro",
                      fontWeight: FontWeight.w700,
                      fontSize: 40,
                      color: Colors.white),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 500),
              top: pageHeight,
              curve: Curves.easeIn,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: currentHeight - pageHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 30, left: 20, right: 20, bottom: 20),
                  child: Column(
                    children: [
                      SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_currentPage == 1) {
                                    isBigForm = false;
                                  }
                                  progress -= 25;
                                  if (progress < 0) {
                                    progress = 0;
                                  }
                                  setState(() {});
                                  _pageController.previousPage(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeIn);
                                },
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 30,
                                  color: Color(0xFFB8425F),
                                ),
                              ),
                              Expanded(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: CustomProgressBar(
                                  progress: progress,
                                  bar: 30,
                                ),
                              ))
                            ],
                          )),
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: PageView(
                                onPageChanged: (int page) {
                                  _currentPage = page;
                                },
                                controller: _pageController,
                                physics: NeverScrollableScrollPhysics(),
                                children: [
                                  _buildFirstPage(),
                                  _buildSecondPage(context),
                                  _buildThirdPage(),
                                  _buildForthPage(),
                                ],
                              )))
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
