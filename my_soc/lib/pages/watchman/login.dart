// admin_login_page.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class WatchmanLogin extends StatefulWidget {
  const WatchmanLogin({super.key});

  @override
  State<WatchmanLogin> createState() => _WatchmanLoginState();
}

class _WatchmanLoginState extends State<WatchmanLogin> {
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
  bool isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? subscription;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadStoredValue();
    });
    startListening();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  void startListening() {
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        setState(() => isConnected = false);
      } else {
        final hasInternet = await _hasInternetConnection();
        if (hasInternet) {
          setState(() => isConnected = true);
        } else {
          setState(() => isConnected = false);
        }
      }
    });
  }

  void stopListening() {
    subscription?.cancel();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadStoredValue() async {
    prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";

    if (token != "") {
      try {
        final jwt = JWT.verify(token, SecretKey('hellovedu'));

        Navigator.pushReplacementNamed(context, MySocRoutes.watchmanHome,
            arguments: {
              'watch_name': jwt.payload['watchmanName'],
              'watch_id': jwt.payload['watchmanId'],
              'wings': jwt.payload['wings'],
              'build_id': jwt.payload['buildId'].toString(),
            });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool updatePassword({String pass = ""}) {
    try {
      FirebaseFirestore.instance
          .collection('buildings')
          .doc(_buildingId.text.trim())
          .collection('watchmen')
          .doc(querySnapshot.docs[0].id)
          .update({'password': pass, 'isFirst': false});
      return true;
    } catch (e) {
      print("Something went wrong");
      return false;
    }
  }

  Future<void> _login() async {
    if (isConnected == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No token exists, Please connect to a network'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
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
          setState(() {
            _isLoading = false;
          });

          if (querySnapshot.docs.isNotEmpty) {
            if (querySnapshot.docs[0]['isDisabled']) {
              throw Exception("User is disabled by the Secretary");
            }

            bool goAhead = true;

            if (querySnapshot.docs[0]['isFirst']) {
              goAhead = false;
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
                            onPressed: () {
                              if (_pass1.text.trim() != _pass2.text.trim()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Both the password should be same'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                if (updatePassword(pass: _pass2.text.trim())) {
                                  setState(() {
                                    goAhead = true;
                                  });
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            child: Text("Reset"))
                      ],
                    );
                  });
            }

            else {
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

              Future.delayed(Duration(seconds: 3), () {
                Map watch_details;
                watch_details = querySnapshot.docs[0].data() as Map;
                watch_details['id'] = querySnapshot.docs[0].id;

                Navigator.pushReplacementNamed(
                    context, MySocRoutes.watchmanHome,
                    arguments: {
                      'watch_name': watch_details['name'],
                      'watch_id': watch_details['id'],
                      'wings': building['wings'],
                      'build_id': building.id,
                    });
              });

              throw Exception("You have logged in Succesfully");
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid credentials'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> validateBuild() async {
    try {
      building = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_buildingId.text.trim())
          .get();
      if (building.exists) {
        var buildData = building.data() as Map<String, dynamic>;
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
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AnimationLimiter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 800),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFFE94560),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE94560).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_circle,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeInAnimation(
                          child: const Text(
                            'Watchman Login',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimationConfiguration.synchronized(
                          duration: const Duration(milliseconds: 1000),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      enabled: isValidBuilding ? false : true,
                                      controller: _buildingId,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: "Enter Building ID",
                                        hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        labelText: "Building ID",
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.home,
                                          color: Color(0xFFE94560),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE94560),
                                            width: 2,
                                          ),
                                        ),
                                        fillColor: Colors.white.withOpacity(0.8),
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter Building ID';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await validateBuild();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE94560),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        shadowColor: const Color(0xFFE94560).withOpacity(0.5),
                                      ),
                                      child: const Text(
                                        "Validate Building",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _usernameController,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: "Enter Username",
                                        hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        labelText: "Username",
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person,
                                          color: Color(0xFFE94560),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE94560),
                                            width: 2,
                                          ),
                                        ),
                                        fillColor: Colors.white.withOpacity(0.8),
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: "Enter Password",
                                        hintStyle: TextStyle(
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        labelText: "Password",
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock,
                                          color: Color(0xFFE94560),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: const Color(0xFFE94560),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE94560),
                                            width: 2,
                                          ),
                                        ),
                                        fillColor: Colors.white.withOpacity(0.8),
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter password';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFE94560).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
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