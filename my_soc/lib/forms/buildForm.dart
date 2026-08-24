import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:my_soc/widgets/progressBar.dart';
import 'package:my_soc/widgets/uploadButton.dart';
import 'package:page_transition/page_transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:wave/wave.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class Buildform extends StatefulWidget {
  const Buildform({super.key});

  @override
  State<Buildform> createState() => _BuildformState();
}

class _BuildformState extends State<Buildform> {
  // For form page Handling
  final PageController _pageController = PageController(initialPage: 0);
  bool isBigForm = false;
  int _currentPage = 0;
  double progress = 00;
  final _picker = ImagePicker();

  // For First Page data
  final formkey1 = GlobalKey<FormState>();
  TextEditingController buildName = TextEditingController();
  TextEditingController streetName = TextEditingController();
  TextEditingController cityName = TextEditingController();
  TextEditingController landmarkName = TextEditingController();
  TextEditingController stateName = TextEditingController();

  // For the second Page
  final formkey2 = GlobalKey<FormState>();
  TextEditingController constructionYear = TextEditingController();
  TextEditingController flatsCount = TextEditingController();
  TextEditingController builtUpArea = TextEditingController();
  // About to be replaced in future
  TextEditingController wingDetails = TextEditingController();
  LatLng? location;

  // For the third page
  final PageController _imageController = PageController(viewportFraction: 0.8);
  List<File> _buildingImages = [];
  List<String> _buildingImagesURL = [];

  // For ImageUpload Button
  String imageUploadText = "Upload";
  double imageUploadHeight = 50;
  double imageUploadWidth = 130;
  double imageUploadScale = 20;
  double imageUploadCurve = 25;
  double imageUploadWave = 50;
  double imageUploadPercentage = 0;

  // Values used by both the buttons
  static const _backgroundColor = Color(0xFFF15BB5);
  static const _colors = [
    Color(0xFF00BBF9),
  ];
  static const _durations = [
    3000,
  ];

  // For the Fourth page
  final PageController _facilitiesController =
      PageController(viewportFraction: 0.8);

  List<bool> selectedFacilities = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  List<Map> facilitiesList = [
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/backup.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Backup Generator',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/fire.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Fire Protection Systems',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/garden.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Gradens',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/gym.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Gym and Workouts',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/hall.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Community Halls',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/lift.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Elevators',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/rainwater.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Rain Water Harvesting',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/survillance.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'CCTV and Survilliance',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/swimming.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Swimming Pool',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/playarea.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Play Area',
    },
    {
      'path': 'C:/GithubRepos/MySoc/my_soc/lib/images/parking.jpg',
      'text':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
      'head': 'Parking Facility',
    },
  ];

  List<String> displayFacilities = [
    "",
  ];

  // For the Fifth Page
  File? _registrationCertificate;
  File? _registeredAddress;
  String? _registrationCertificateURL;
  String? _registeredAddressURL;
  UploadTask? _registrationCerfUpload;
  UploadTask? _registrationAddrUpload;
  double? _registartionCertUploadPercentage;
  double? _registrationAddrUploadPercentage;

  // For the Society Registration Certificate
  String SocietybuttonText = "Upload";
  double SocietyButtonHeight = 50;
  double ScoietyButtonWidth = 130;
  double SocietyButtonScale = 20;
  double SocietyButtonCurve = 25;
  double SocietyButtonWave = 50;

  // For the proof of Address Certificate
  String AddressButtonText = "Upload";
  double AddressButtonHeight = 50;
  double AddressButtonWidth = 130;
  double AddressButtonScale = 20;
  double AddressButtonCurve = 25;
  double AddressButtonWave = 50;

  Widget _firstPage() {
    return Form(
        key: formkey1,
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    // height: MediaQuery.of(context).size.height,
                    child: Text(
                      "Building Registration",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFF49548D)),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Building Name",
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
                            return "Please enter your Building Name";
                          }
                          return null;
                        },
                        controller: buildName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.apartment,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Your Building Name",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "Street Name",
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
                            return "Please enter your Street Name";
                          }
                          return null;
                        },
                        controller: streetName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.directions_car,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Your Street Name",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "State",
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
                            return "Please enter your State";
                          }
                          return null;
                        },
                        controller: stateName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.terrain,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Your State",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "City",
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
                            return "Please enter your City Name";
                          }
                          return null;
                        },
                        controller: cityName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_city,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Your City",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                  // This is ignored as there is not enough space for landmark usage
                  // Text(
                  //   "Building Name",
                  //   style: TextStyle(
                  //       fontFamily: 'Poppins',
                  //       fontWeight: FontWeight.w700,
                  //       fontSize: 16,
                  //       color: Color(0xFFB8425F)),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 6.0),
                  //   child: SizedBox(
                  //     height: 61,
                  //     child: TextFormField(
                  //       validator: (value) {
                  //         if (value == null || value.isEmpty) {
                  //           return "Please enter your Building Name";
                  //         }
                  //         return null;
                  //       },
                  //       controller: buildName,
                  //       decoration: InputDecoration(
                  //         prefixIcon: Icon(
                  //           Icons.apartment,
                  //           color: Color(0xFF49548D),
                  //         ),
                  //         helperText: " ",
                  //         hintText: "Your Building Name",
                  //         hintStyle: TextStyle(
                  //             color: Colors.grey,
                  //             fontFamily: "Poppins",
                  //             fontWeight: FontWeight.w300,
                  //             fontSize: 15),
                  //         contentPadding: EdgeInsets.symmetric(
                  //             vertical: 12, horizontal: 16),
                  //         enabledBorder: OutlineInputBorder(
                  //           borderRadius:
                  //               BorderRadius.circular(13), // Rounded border
                  //           borderSide: BorderSide(color: Color(0xFFACACAC)),
                  //         ),
                  //         focusedBorder: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(13),
                  //           borderSide: BorderSide(
                  //               color: Colors.red,
                  //               width: 2), // Blue border when focused
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formkey1.currentState!.validate()) {
                          setState(() {
                            isBigForm = true;
                            progress += 20;
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
        ));
  }

  Widget _secondPage() {
    return Form(
        key: formkey2,
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    // height: MediaQuery.of(context).size.height,
                    child: Text(
                      "Building Details",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Color(0xFF49548D)),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Construction Year",
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
                            return "This field is required!";
                          }
                          return null;
                        },
                        controller: constructionYear,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.construction_outlined,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Year of Construction",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "Number of Registered Flats",
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
                            return "This field is required!";
                          }
                          return null;
                        },
                        controller: flatsCount,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.house,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Number of Flats",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "Total Built Up Area",
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
                            return "This field is required";
                          }
                          return null;
                        },
                        controller: builtUpArea,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.area_chart,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Area covered (Sq.m)",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "Wing Details",
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
                            return "This field is required";
                          }
                          return null;
                        },
                        controller: wingDetails,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.apartment,
                            color: Color(0xFF49548D),
                          ),
                          helperText: " ",
                          hintText: "Number of Wings",
                          hintStyle: TextStyle(
                              color: Colors.grey,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                    "Building Location",
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFFB8425F)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () async {
                        print("Hello");
                        LatLng chosenLocation =
                            await context.pushNamedTransition(
                          routeName: '/chooseLocation',
                          type: PageTransitionType.fade,
                          duration: Duration(milliseconds: 500),
                        );
                        setState(() {
                          location = chosenLocation;
                        });
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.amber),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 150,
                                child: Image.asset(
                                    fit: BoxFit.fitHeight,
                                    'C:/GithubRepos/MySoc/my_soc/lib/images/maps.jpg'),
                              ),
                              Container(
                                height: double.infinity,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      size: 40,
                                      Icons.pin_drop,
                                      color: Colors.lightBlue,
                                    ),
                                    Text(
                                      "Tap to enter your location.",
                                      style: TextStyle(
                                          color: Colors.lightBlueAccent),
                                    ),
                                    if (location != null)
                                      Text(
                                        "Latitude: ${location!.latitude.toStringAsFixed(3)}",
                                        style: TextStyle(
                                            color: Colors.lightBlueAccent),
                                      ),
                                    if (location != null)
                                      Text(
                                        "Longitude: ${location!.longitude.toStringAsFixed(3)}",
                                        style: TextStyle(
                                            color: Colors.lightBlueAccent),
                                      )
                                  ],
                                ),
                              )
                            ],
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
                        // For testing purpose the form input valiation is disabled by default
                        if (!formkey2.currentState!.validate() &&
                            location != null) {
                          setState(() {
                            isBigForm = true;
                            progress += 20;
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
        ));
  }

  Widget _thirdPage() {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              // height: MediaQuery.of(context).size.height,
              child: Text(
                "Upload Images",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF49548D)),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 150,
              // color: Colors.lightBlueAccent,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "1. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
                        style: TextStyle(
                            color: Color(0xFF5C6699),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w300,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "2. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
                        style: TextStyle(
                            color: Color(0xFF5C6699),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w300,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "3. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
                        style: TextStyle(
                            color: Color(0xFF5C6699),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w300,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "4. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
                        style: TextStyle(
                            color: Color(0xFF5C6699),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w300,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "5. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ",
                        style: TextStyle(
                            color: Color(0xFF5C6699),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w300,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              height: 300,
              child: PageView.builder(
                  controller: _imageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: max(_buildingImages.length, 1),
                  itemBuilder: (context, index) {
                    if (_buildingImages.length < 5 && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            _pickBuildingImages();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromARGB(255, 223, 234, 255)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                        'C:/GithubRepos/MySoc/my_soc/lib/images/imageIcon.png'),
                                  ),
                                ),
                                // SizedBox(
                                //   height: 5,
                                // ),
                                Text(
                                  "Click to upload\n or \ndrag and drop",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blueGrey),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "JPG, JPEG, PNG less than 1MB",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: const Color.fromARGB(
                                          255, 113, 147, 164)),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (_buildingImages.isNotEmpty) {
                      return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              Container(
                                height: double.infinity,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Color.fromARGB(255, 223, 234, 255)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    _buildingImages[index],
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              if (imageUploadText == 'Upload')
                                Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          _buildingImages.removeAt(index);
                                          setState(() {});
                                        },
                                        child: Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )),
                            ],
                          ));
                    }
                    return null;
                  }),
            ),
            SizedBox(
              height: 10,
            ),
            _imageUploadButton(),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: ElevatedButton(
                onPressed: () async {
                  // For testing purpose the form input valiation is disabled by default
                  if (_buildingImagesURL.length != 5) {
                    setState(() {
                      isBigForm = true;
                      progress += 20;
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
    );
  }

  Widget _imageUploadButton() {
    return Center(
      child: Center(
        child: GestureDetector(
          onTap: () async {
            if (_buildingImages.length == 5 &&
                _buildingImagesURL.length != 5 &&
                imageUploadText != 'Uploading...') {
              setState(() {
                if (imageUploadText == 'Upload') {
                  imageUploadHeight +=
                      imageUploadHeight * imageUploadScale / 100;
                  imageUploadWidth += imageUploadWidth * imageUploadScale / 100;
                  imageUploadCurve = imageUploadHeight / 2;
                  imageUploadText = 'Uploading...';
                }
              });

              print("Uploading Images without Compression");
              int count = 0;
              for (File image in _buildingImages) {
                try {
                  final storage = 'BuildingImages/';
                  const uuid = Uuid();
                  final fileExtension = image.path.split('.').last;
                  final uniquename = '${uuid.v4()}.$fileExtension';
                  final ref = FirebaseStorage.instance
                      .ref()
                      .child('$storage/$uniquename');
                  UploadTask _imageUpload = ref.putFile(image);
                  final snapshot = await _imageUpload.whenComplete(() {});
                  // For showing updation of the graph
                  String url = await snapshot.ref.getDownloadURL();
                  _buildingImagesURL.add(url);
                  count += 1;
                  setState(() {
                    imageUploadPercentage = count / 5 * 100;
                    imageUploadWave = imageUploadHeight -
                        (imageUploadPercentage * imageUploadHeight / 100);
                  });
                  print("A image done");
                } catch (e) {
                  print('Encountered error while uplaoding ${image.path}');
                  print('The error is $e');
                }
              }
              if (_buildingImagesURL.length == 5) {
                imageUploadText = 'Uploaded';
              } else {
                print('An error occured. Please try again');
              }
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 500),
            height: imageUploadHeight,
            width: imageUploadWidth,
            curve: Curves.bounceOut,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(imageUploadCurve),
                color: Colors.amber),
            child: Stack(
              children: [
                if (imageUploadText == 'Uploading...')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(imageUploadCurve),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          color: Colors.amber,
                          height: imageUploadWave,
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
                    if (imageUploadText == "Uploaded")
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.check_circle_rounded),
                      ),
                    Text(imageUploadText),
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBuildingImages() async {
    final pickedFiles = await _picker.pickMultiImage(
      imageQuality: 80,
    );
    setState(() {
      if (pickedFiles.isNotEmpty) {
        for (int i = 0; i < min(5, pickedFiles.length); i++) {
          if (_buildingImages.length < 5) {
            _buildingImages.add(File(pickedFiles[i].path));
          }
        }
      }
    });
  }

  Widget _fourthPage() {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              // height: MediaQuery.of(context).size.height,
              child: Text(
                "Facilities & Amenities",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF49548D)),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            // Assuming we have 12 default Facilities
            SizedBox(
              height: 250,
              child: PageView.builder(
                  controller: _facilitiesController,
                  itemCount: facilitiesList.length,
                  itemBuilder: (context, index) {
                    String ImageUrl = facilitiesList[index]['path'];
                    String text = facilitiesList[index]['text'];
                    String Heading = facilitiesList[index]['head'];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedFacilities[index] == false) {
                              selectedFacilities[index] = true;
                              displayFacilities.insert(0, Heading);
                              // displayFacilities.remove(Heading);
                            } else {
                              selectedFacilities[index] = false;
                              displayFacilities.remove(Heading);
                            }
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              height: double.infinity,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  ImageUrl,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                            Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              width: double.infinity,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    Heading,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 30),
                                  ),
                                  Divider(
                                    thickness: 2,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    text,
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                            if (selectedFacilities[index])
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                      child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.amber,
                                  )),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  }),
            ),
            SizedBox(
              height: 20,
            ),
            Divider(
              thickness: 2,
              color: Color(0xFFBFBFBF),
            ),
            SizedBox(
              width: double.infinity,
              // height: MediaQuery.of(context).size.height,
              child: Text(
                "Selected Facilities",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF49548D)),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: (MediaQuery.of(context).size.height / 3),
              // width: MediaQuery.of(context).size.width,
              // color: Colors.amber,
              child: Stack(
                children: [
                  ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: displayFacilities.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                displayFacilities[index],
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Color(0xFF49548D)),
                              )
                            ],
                          ),
                        );
                      }),
                  Positioned(
                    // width: double.infinity,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: Colors.white
                              .withOpacity(0.7), // Adjust opacity as needed
                          offset: const Offset(
                              0, -3), // Negative y-offset for top shadow
                          blurRadius: 10, // Adjust blur radius as needed
                          spreadRadius: 5, // Adjust spread radius as needed
                        )
                      ]),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            // For testing purpose the form input valiation is disabled by default
                            if (_buildingImagesURL.length != 5) {
                              setState(() {
                                isBigForm = true;
                                progress += 20;
                              });
                              _pageController.nextPage(
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeIn);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              shadowColor: Colors.white,
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fifthPage() {
    return SizedBox(
      // height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
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
                  _pickFile('_registrationCertificate');
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                                "Society Registration Certificate (PDF)",
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF49548D)),
                              ),
                              if (_registrationCertificate != null)
                                Text(
                                  p.basename(_registrationCertificate!.path),
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
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildSocietyButton()),
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
                  _pickFile('_registeredAddress');
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                                "Proof of Registered Address (PDF)",
                                style: TextStyle(
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF49548D)),
                              ),
                              if (_registeredAddress != null)
                                Text(
                                  p.basename(_registeredAddress!.path),
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildAdressButton(),
              ),
              SizedBox(
                height: 80,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // For now checking disabled
                    if (_registrationCertificateURL == null &&
                        _registeredAddressURL == null) {
                      setState(() {
                        progress += 20;
                        isBigForm = true;
                      });
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    } else {
                      // Please upload the necessary documents first to proceed ahead
                      print("Hello");
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

  Widget _buildSocietyButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          print("Noted");
          if (_registrationCertificate != null &&
              _registrationCertificateURL == null) {
            setState(() {
              if (SocietybuttonText == 'Upload') {
                SocietyButtonHeight +=
                    SocietyButtonHeight * SocietyButtonScale / 100;
                ScoietyButtonWidth +=
                    ScoietyButtonWidth * SocietyButtonScale / 100;
                SocietyButtonCurve = SocietyButtonHeight / 2;
                SocietybuttonText = 'Uploading...';
              }
            });
            print("Hello");
            // Uploading the file to the Google Stoarge
            try {
              final store = 'BuildingDocs/';
              const uuid = Uuid();
              final fileExtension =
                  _registrationCertificate!.path.split('.').last;
              final uniquename = '${uuid.v4()}.$fileExtension';
              final ref =
                  FirebaseStorage.instance.ref().child('$store/$uniquename');
              _registrationCerfUpload = ref.putFile(_registrationCertificate!);

              // For showing Updation of the progress made
              _registrationCerfUpload!.snapshotEvents.listen(
                  (TaskSnapshot snapshot) {
                setState(() {
                  _registartionCertUploadPercentage =
                      (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                  SocietyButtonWave = SocietyButtonHeight -
                      (_registartionCertUploadPercentage! *
                          SocietyButtonHeight /
                          100);
                  print(_registartionCertUploadPercentage);
                });
              }, onError: (error) {
                print(error);
              }, onDone: () {
                setState(() async {
                  SocietybuttonText = "Uploaded";
                  _registrationCertificateURL = await ref.getDownloadURL();
                  print('Download is $_registrationCertificateURL');
                });
              });
            } catch (e) {
              print('Encountered an error $e');
            }
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: SocietyButtonHeight,
          width: ScoietyButtonWidth,
          curve: Curves.bounceOut,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SocietyButtonCurve),
              color: Colors.amber),
          child: Stack(
            children: [
              if (SocietybuttonText == 'Uploading...')
                ClipRRect(
                  borderRadius: BorderRadius.circular(SocietyButtonCurve),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        color: Colors.amber,
                        height: SocietyButtonWave,
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
                  if (SocietybuttonText == "Uploaded")
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded),
                    ),
                  Text(SocietybuttonText),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdressButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (_registeredAddress != null && _registeredAddressURL == null) {
            setState(() {
              if (AddressButtonText == 'Upload') {
                AddressButtonHeight +=
                    AddressButtonHeight * AddressButtonScale / 100;
                AddressButtonWidth +=
                    AddressButtonWidth * AddressButtonScale / 100;
                AddressButtonCurve = AddressButtonHeight / 2;
                AddressButtonText = 'Uploading...';
              }
            });
            print("Hello");
            // Uploading the file to the Google Stoarge
            try {
              final store = 'UserDocs/';
              const uuid = Uuid();
              final fileExtension = _registeredAddress!.path.split('.').last;
              final uniquename = '${uuid.v4()}.$fileExtension';
              final ref =
                  FirebaseStorage.instance.ref().child('$store/$uniquename');
              _registrationAddrUpload = ref.putFile(_registeredAddress!);

              // For showing Updation of the progress made
              _registrationAddrUpload!.snapshotEvents.listen(
                  (TaskSnapshot snapshot) {
                setState(() {
                  _registrationAddrUploadPercentage =
                      (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                  AddressButtonWave = AddressButtonHeight -
                      (_registrationAddrUploadPercentage! *
                          AddressButtonHeight /
                          100);
                  print(_registrationAddrUploadPercentage);
                });
              }, onError: (error) {
                print(error);
              }, onDone: () {
                setState(() async {
                  AddressButtonText = "Uploaded";
                  _registeredAddressURL = await ref.getDownloadURL();
                  print('Download is $_registeredAddressURL');
                });
              });
            } catch (e) {
              print('Encountered an error $e');
            }
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: AddressButtonHeight,
          width: AddressButtonWidth,
          curve: Curves.bounceOut,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AddressButtonCurve),
              color: Colors.amber),
          child: Stack(
            children: [
              if (AddressButtonText == 'Uploading...')
                ClipRRect(
                  borderRadius: BorderRadius.circular(AddressButtonCurve),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        color: Colors.amber,
                        height: AddressButtonWave,
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
                  if (AddressButtonText == "Uploaded")
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.check_circle_rounded),
                    ),
                  Text(AddressButtonText),
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
        if (fileType == '_registrationCertificate') {
          _registrationCertificate = File(result.files.single.path!);
          _registrationCertificateURL = null;
          SocietybuttonText = "Upload";
          SocietyButtonHeight = 50;
          ScoietyButtonWidth = 130;
          SocietyButtonScale = 20;
          SocietyButtonCurve = 25;
          SocietyButtonWave = 50;
        } else if (fileType == '_registeredAddress') {
          _registeredAddress = File(result.files.single.path!);
          _registeredAddressURL = null;
          AddressButtonText = "Upload";
          AddressButtonHeight = 50;
          AddressButtonWidth = 130;
          AddressButtonScale = 20;
          AddressButtonCurve = 25;
          AddressButtonWave = 50;
        }
      });
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
            SizedBox(
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
                // duration: Duration(microseconds: 100),
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
                                  progress -= 20;
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
                                  bar: 20,
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
                                  _firstPage(),
                                  _secondPage(),
                                  _thirdPage(),
                                  _fourthPage(),
                                  _fifthPage(),
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
