import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_soc/widgets/custom_toast.dart';
import 'package:my_soc/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_soc/providers/watchman_provider.dart';

class WatchmanLogin extends ConsumerStatefulWidget {
  const WatchmanLogin({super.key});

  @override
  ConsumerState<WatchmanLogin> createState() => _WatchmanLoginState();
}

class _WatchmanLoginState extends ConsumerState<WatchmanLogin> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _buildingId = TextEditingController();
  bool _isLoading = false;
  bool isValidBuilding = false;
  late QuerySnapshot querySnapshot;
  late DocumentSnapshot building;
  late String token;
  late SharedPreferences prefs;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    logger.i('WatchmanLogin: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadStoredValue();
    });
  }

  @override
  void dispose() {
    logger.i('WatchmanLogin: dispose called');
    _usernameController.dispose();
    _passwordController.dispose();
    _buildingId.dispose();
    super.dispose();
  }

  // Backend: Redirects to watchman home if jwt-token is present and valid
  Future<void> _loadStoredValue() async {
    logger.i('WatchmanLogin: _loadStoredValue called');
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";

    if (token != "") {
      try {
        final jwt = JWT.verify(token, SecretKey('hellovedu'));

        ref.read(watchmanProvider.notifier).setWatchmanData(
          watchName: jwt.payload['watchmanName'],
          watchId: jwt.payload['watchmanId'],
          buildId: jwt.payload['buildId'].toString(),
          wings: jwt.payload['wings'] ?? [],
        );
        logger.i('WatchmanLogin: _loadStoredValue successful, navigating to home');
        Navigator.pushReplacementNamed(context, MySocRoutes.watchmanHome);
        return;
      } catch (e) {
        CustomToast.show(context, type: -1, message: '$e');
      }
    }
    logger.i('WatchmanLogin: _loadStoredValue completed - No valid token found');
  }

  // Backend: Resets password
  Future<bool> updatePassword({String pass = ""}) async {
    logger.i('WatchmanLogin: updatePassword called');
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_buildingId.text.trim())
          .collection('watchmen')
          .doc(querySnapshot.docs[0].id)
          .update({'password': pass, 'isFirst': false});
      logger.i('WatchmanLogin: updatePassword completed successfully');
      return true;
    } catch (e) {
      logger.e("Something went wrong: $e");
      return false;
    }
  }

  // Backend: Log in to watchman account
  Future<void> _login() async {
    logger.i(
        'WatchmanLogin: _login called with username: ${_usernameController.text.trim()}, building: ${_buildingId.text.trim()}');
    if (_formKey.currentState!.validate() && isValidBuilding) {
      setState(() {
        _isLoading = true;
      });

      try {
        querySnapshot = await FirebaseFirestore.instance
            .collection('buildings')
            .doc(_buildingId.text.trim())
            .collection('watchmen')
            .where('username', isEqualTo: _usernameController.text.trim())
            .where('password', isEqualTo: _passwordController.text.trim())
            .get();

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (querySnapshot.docs.isNotEmpty) {
          if (querySnapshot.docs[0]['isDisabled']) {
            throw Exception("User is disabled by the Secretary");
          }

          if (querySnapshot.docs[0]['isFirst']) {
            showDialog(
                context: context,
                builder: (context) {
                  TextEditingController _pass1 = TextEditingController();
                  TextEditingController _pass2 = TextEditingController();

                  return AlertDialog(
                    title: const Text("Reset Your Password"),
                    content: SingleChildScrollView(
                      child: Column(children: [
                        TextFormField(
                          controller: _pass1,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              if (value!.length < 6) {
                                return "Password must be atleast 6 characters";
                              }
                              return 'Please enter username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _pass2,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              if (value!.length < 6) {
                                return "Password must be atleast 6 characters";
                              }
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                      ]),
                    ),
                    actions: [
                      ElevatedButton(
                          onPressed: () async {
                            if (_pass1.text.trim() != _pass2.text.trim()) {
                              CustomToast.show(context,
                                  type: -1,
                                  message: 'Both the password should be same');
                            } else {
                              if (await updatePassword(
                                  pass: _pass2.text.trim())) {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  CustomToast.show(context,
                                      type: 1,
                                      message:
                                          'Password updated! Please login again.');
                                }
                              }
                            }
                          },
                          child: const Text("Reset"))
                    ],
                  );
                });
          } else {
            Map watchman = querySnapshot.docs[0].data() as Map;
            watchman['id'] = querySnapshot.docs[0].id;

            final jwt = JWT({
              'username': _usernameController.text.trim(),
              'watchmanName': watchman['name'],
              'watchmanId': watchman['id'],
              'password': _passwordController.text.trim(),
              'buildId': _buildingId.text.trim(),
              'wings': building['wings'],
            });

            final token = jwt.sign(SecretKey("hellovedu"));

            await prefs.setString('token', token.toString());

            Future.delayed(const Duration(seconds: 3), () {
              Map watch_details;
              watch_details = querySnapshot.docs[0].data() as Map;
              watch_details['id'] = querySnapshot.docs[0].id;

              ref.read(watchmanProvider.notifier).setWatchmanData(
                watchName: watch_details['name'],
                watchId: watch_details['id'],
                buildId: building.id,
                wings: building['wings'] ?? [],
              );
              logger.i('WatchmanLogin: _login delayed navigation successful');
              Navigator.pushReplacementNamed(context, MySocRoutes.watchmanHome);
            });

            // throw Exception("You have logged in Succesfully");
            CustomToast.show(context,
                type: 1, message: 'You have logged in Succesfully');
            logger.i('WatchmanLogin: _login completed successfully - User logged in');
          }
        } else {
          CustomToast.show(context, type: -1, message: 'Invalid credentials');
          logger.i('WatchmanLogin: _login failed - Invalid credentials');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        logger.e(e);
        CustomToast.show(context, type: -1, message: '$e');
        logger.i('WatchmanLogin: _login completed with exception');
      }
    }
  }

  // Backend: Validates building ID
  Future<void> validateBuild() async {
    logger.i(
        'WatchmanLogin: validateBuild called for building ID: ${_buildingId.text.trim()}');
    try {
      building = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_buildingId.text.trim())
          .get();

      if (!mounted) return;

      if (building.exists) {
        var buildData = building.data() as Map<String, dynamic>;
        if (buildData['isVerified'] == false) {
          throw Exception('Builiding is yet to be verified!');
        }
        CustomToast.show(context,
            type: 1,
            message: 'Your Building name is ${buildData['buildingName']}');
        setState(() {
          isValidBuilding = true;
        });
        logger.i('WatchmanLogin: validateBuild completed successfully - valid building');
      } else {
        throw Exception('Invalid Building ID');
      }
    } catch (e) {
      CustomToast.show(context, type: -1, message: e.toString());
      logger.i('WatchmanLogin: validateBuild completed with error - invalid building');
    }
  }

  // UI Components matching login.dart

  // UI: App title section.
  Widget _buildTitleSection() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      child: Center(
        child: const Text(
          "MySoc",
          style: TextStyle(
            fontFamily: "Readex Pro",
            fontWeight: FontWeight.w700,
            fontSize: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // UI: Login form header.
  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Watchman Login",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: "Readex Pro",
            color: Color(0xFF222A54),
          ),
        ),
        Text(
          "Sign in to your account",
          style: TextStyle(
            fontFamily: "Readex Pro",
            fontWeight: FontWeight.w300,
            fontSize: 14,
            color: Color(0xFFACACAC),
          ),
        ),
      ],
    );
  }

  // UI: Shared input decoration
  InputDecoration _buildInputDecoration(
    String hintText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      helperText: " ",
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontFamily: "Poppins",
        fontWeight: FontWeight.w300,
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFACACAC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }

  // UI: Building ID field.
  Widget _buildBuildingIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Building ID",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 2),
          child: SizedBox(
            height: 60,
            child: TextFormField(
              enabled: !isValidBuilding,
              controller: _buildingId,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter Building ID";
                }
                return null;
              },
              decoration: _buildInputDecoration("Enter Building ID"),
            ),
          ),
        ),
        if (!isValidBuilding)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await validateBuild();
              },
              child: const Text(
                "Validate Building",
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // UI: Username input field.
  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Username",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 2),
          child: SizedBox(
            height: 60,
            child: TextFormField(
              controller: _usernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter username";
                }
                return null;
              },
              decoration: _buildInputDecoration("Enter your username"),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Password input field.
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            height: 60,
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter password";
                }
                return null;
              },
              decoration: _buildInputDecoration(
                "Enter your password",
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Login button.
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(280, 40),
        backgroundColor: const Color(0xFF222A54),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              "Login",
              style: TextStyle(
                fontFamily: "Poppins",
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
    );
  }

  // UI: Action section
  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 7),
            _buildLoginButton(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // UI: Main login form card.
  Widget _buildFormCard() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormHeader(),
                const SizedBox(height: 20),
                _buildBuildingIdField(),
                const SizedBox(height: 5),
                _buildUsernameField(),
                const SizedBox(height: 5),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildActionSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  // UI: Root login page layout.
  Widget build(BuildContext context) {
    logger.d('WatchmanLogin: build called');
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF222A54), Color(0xFFCE798E)],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                _buildTitleSection(),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
