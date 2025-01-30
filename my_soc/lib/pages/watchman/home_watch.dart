import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class WatchmanHome extends StatefulWidget {
  const WatchmanHome({super.key});

  @override
  State<WatchmanHome> createState() => _WatchmanHomeState();
}

class _WatchmanHomeState extends State<WatchmanHome> {
  late String watch_name;
  late String watch_id;
  late List wings;
  late String build_id;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();
    });
  }

  void addVisitorInfo(context) async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _fromController = TextEditingController();
    TextEditingController _countController = TextEditingController(text: "1");
    TextEditingController _flatNumber = TextEditingController();
    String _selectedWing = wings[0]['wingName'];
    bool forBuilding = false;
    TextEditingController _description = TextEditingController();

    // print(wings);
    recordDetails() async {
      try {
        FirebaseFirestore.instance
            .collection('buildings')
            .doc(build_id)
            .collection('logs')
            .add({
          'name': _nameController.text.trim(),
          'from': _fromController.text.trim(),
          'count': _countController.text.trim(),
          'forBuild': forBuilding,
          'flat': forBuilding ? "" : _flatNumber.text.trim().toString(),
          'wing': forBuilding ? "" : _selectedWing,
          'createdBy': watch_name,
          'createdById': watch_id,
          'timestamp': Timestamp.now(),
          'reason': _description.text.trim()
        });
        print("Recorded Successfully");
        Navigator.of(context).pop();
        throw Exception('Recorded succesfully');
      } catch (e) {
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text("Add a visitor log"),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          labelText: 'From Where',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'People Count',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment,
                        children: [
                          Checkbox(
                              value: forBuilding,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  forBuilding = newValue ?? false;
                                });
                              }),
                          Text(
                            "For Building's Maintainenace",
                            textScaler: TextScaler.linear(0.8),
                          )
                        ],
                      ),
                      if (!forBuilding)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Wings"),
                                ),
                                DropdownButton(
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                  // isExpanded: true,
                                  value: _selectedWing,
                                  icon: Icon(Icons.apartment),
                                  iconSize: 24,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedWing = newValue!;
                                      // print(_selectedWing);
                                    });
                                  },
                                  items: wings.map((wing) {
                                    return DropdownMenuItem(
                                      value: wing['wingName'] as String,
                                      child: Text(wing['wingName'] as String),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            TextField(
                              controller: _flatNumber,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                constraints: BoxConstraints(maxWidth: 120),
                                labelText: 'Flat Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 0,
                            children: [
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Swiggy",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 217, 114),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Food deleivery by Swiggy");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Zomato",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 163, 163),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Food deleivery by Zomato");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Electrician",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 210, 208, 205),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Electrician in the house");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Plumber",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Plumber works");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Courriers",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 250, 185, 168),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Courrier by ECommerce Websites");
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        // keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Reason for Visit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: () {
                      recordDetails();
                    },
                    child: Text("Record"))
              ],
            );
          });
        });
  }

  void sendCourrierNoti(context) async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _fromController = TextEditingController();
    TextEditingController _countController = TextEditingController(text: "1");
    TextEditingController _flatNumber = TextEditingController();
    String _selectedWing = wings[0]['wingName'];
    bool forBuilding = false;
    TextEditingController _description = TextEditingController();

    sendNotiToServer() async {
      try {
        print("SendNoti is called");
        QuerySnapshot notified_user = await FirebaseFirestore.instance
            .collection('users')
            .where('buildingId', isEqualTo: build_id)
            .where('flatNumber', isEqualTo: _flatNumber.text.trim().toString())
            .where('wing', isEqualTo: _selectedWing)
            .get()
            .timeout(const Duration(seconds: 10));
        print(notified_user);
        if (notified_user.docs.isNotEmpty) {
          final url = Uri.parse('http://192.168.29.138:3000/courriers');

          Map<String, String> headers = {
            'Content-Type': 'application/json',
          };
          Map<String, String> body = {
            'delivery_name': _nameController.text.trim().toString(),
            'user_id': notified_user.docs[0].id.toString(),
            'description': _description.text.trim().toString(),
          };
          String jsonBody = json.encode(body);
          final response =
              await http.post(url, headers: headers, body: jsonBody);

          if (response.statusCode == 201) {
            var data = json.decode(response.body);
          }
        } else {
          print("User has not registered yet with the application");
        }
      } catch (e) {
        print(e.toString());
        print("Error in sending notification");
      }
    }

    saveCourrierInfo() async {
      try {
        FirebaseFirestore.instance
            .collection('buildings')
            .doc(build_id)
            .collection('courriers')
            .add({
          'deliveryName': _nameController.text.trim(),
          'flat': _flatNumber.text.trim(),
          'wing': _selectedWing.toString(),
          'description': _description.text.trim(),
          'recievedAt': Timestamp.now(),
          'recievedName': watch_name,
          'recievedBy': watch_id,
          'status':
              false // false means not picked up, true means picked up from watchman
        });

        // Send notification to user if possible
        sendNotiToServer();

        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });
        throw Exception('Data recorded successfully');
      } catch (e) {
        print(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text("Notify About Packages"),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'From General Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Wings"),
                              ),
                              DropdownButton(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16),
                                // isExpanded: true,
                                value: _selectedWing,
                                icon: Icon(Icons.apartment),
                                iconSize: 24,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedWing = newValue!;
                                    // print(_selectedWing);
                                  });
                                },
                                items: wings.map((wing) {
                                  return DropdownMenuItem(
                                    value: wing['wingName'] as String,
                                    child: Text(wing['wingName'] as String),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _flatNumber,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              constraints: BoxConstraints(maxWidth: 120),
                              labelText: 'Flat Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 0,
                            children: [
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Amazon",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 217, 114),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Package Recieved from Amazon");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Flipkart",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 163, 163),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text: "Package Recieved from Flipkart");
                                  });
                                },
                              ),
                              GestureDetector(
                                child: Chip(
                                  padding: EdgeInsets.all(0),
                                  label: Text(
                                    "Courriers",
                                    textScaler: TextScaler.linear(0.9),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 210, 208, 205),
                                ),
                                onTap: () {
                                  setState(() {
                                    _description = TextEditingController(
                                        text:
                                            "A courrier is recieved. Please collect from base");
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        // keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Custom Description for Notification',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: () {
                      saveCourrierInfo();
                    },
                    child: Text("Record"))
              ],
            );
          });
        });
  }

  Widget build(BuildContext context) {
    // print("This is getting rebuild");

    Map data = ModalRoute.of(context)!.settings.arguments as Map;
    wings = data['wings'];
    watch_name = data['watch_name'];
    watch_id = data['watch_id'];
    build_id = data['build_id'];

    Stream getLogs() {
      DateTime now = Timestamp.now().toDate();
      DateTime previous = now.subtract(Duration(days: 7));
      Timestamp prev = Timestamp.fromDate(previous);

      return FirebaseFirestore.instance
          .collection('buildings')
          .doc(build_id)
          .collection('logs')
          .where('timestamp', isGreaterThan: prev)
          .snapshots();
    }

    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: StreamBuilder(
                stream: getLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Something went Wrong ${snapshot.error}"),
                    );
                  }
                  if (snapshot.hasData) {
                    return DisplayRecords(
                      logs: snapshot.data!.docs,
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () async {
                            await prefs.clear();
                            Navigator.of(context).pop();
                          },
                          child: Text("Sign Out")),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            addVisitorInfo(context);
                          },
                          child: Text("Add Visitor info")),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            sendCourrierNoti(context);
                          },
                          child: Text("Add Courier Information")),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ConnectionStatus()
        ],
      ),
    ));
  }
}

class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool isConnected = false;
  StreamSubscription<List<ConnectivityResult>>? subscription;

  @override
  void initState() {
    super.initState();
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
      // Process the list of ConnectivityResult values
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        setState(() => isConnected = false);
      } else {
        // Check if the device has access to the internet
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
        right: 0,
        top: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              border: Border.all(
                color: isConnected
                    ? Colors.green
                    : const Color.fromARGB(255, 201, 230, 255),
                width: 2.0,
              ),
            ),
            child: Text(
              isConnected ? "Online" : "Offline",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
        ));
  }
}

class DisplayRecords extends StatefulWidget {
  final logs;
  DisplayRecords({super.key, this.logs});

  @override
  State<DisplayRecords> createState() => _DisplayRecordsState();
}

class _DisplayRecordsState extends State<DisplayRecords> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.logs.length,
        itemBuilder: (context, index) {
          DateTime date = widget.logs[index]['timestamp'].toDate();
          String final_date = DateFormat('yyyy-MM-dd HH:mm').format(date);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20), // Rounded corners
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 0, 0), // Border color
                  width: 4.0, // Border width
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(widget.logs[index]['name']),
                  subtitle: widget.logs[index]['forBuild']
                      ? Text("Building Maintainenace")
                      : Text(
                          '${widget.logs[index]['wing']}-${widget.logs[index]['flat']}'),
                  trailing: Text(final_date.toString()),
                ),
              ),
            ),
          );
        });
  }
}
