import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPenalty extends StatefulWidget {
  final user_data;
  final build_data;
  const AddPenalty({super.key, this.user_data, this.build_data});

  @override
  _AddPenaltyState createState() => _AddPenaltyState();
}

class _AddPenaltyState extends State<AddPenalty> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _flatNumberController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedWing;
  List<String> _wings = [];
  String? _residentName;
  String? _residentId;
  String? _buildingName;
  String? _buildingId;
  DateTime? _dueDate;
  File? _proofImage;
  String? _imageUrl;
  bool _isLoading = false;
  double uploadProgress = 0.0;
  late Cloudinary cloudinary;
  List<QueryDocumentSnapshot> _residents = [];

  @override
  void initState() {
    super.initState();
    cloudinary = Cloudinary.signedConfig(
      apiKey: dotenv.env['CloudinaryApiKey'] ?? "",
      apiSecret: dotenv.env['ColudinaryApiSecret'] ?? "",
      cloudName: dotenv.env['ColudinaryCloudName'] ?? "",
    );
    _fetchBuildingAndResidents();
  }

  Future<void> _fetchBuildingAndResidents() async {
    setState(() => _isLoading = true);
    try {
      List<String> wings = (widget.build_data['wings'] as List<dynamic>?)
              ?.map((wing) => wing['wingName'] as String)
              .toList() ??
          [];

      setState(() {
        _buildingName = widget.build_data['buildingName'];
        _buildingId = widget.build_data.id;
        _wings = wings;
      });
      await _fetchResidents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResidents() async {
    if (_buildingId == null) return;

    final residentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: _buildingId)
        .get();

    setState(() => _residents = residentsSnapshot.docs);
  }

  Future<void> _searchResident() async {
    if (_selectedWing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wing')),
      );
      return;
    }

    final flatNumber = _flatNumberController.text.trim();
    if (flatNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a flat number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      QueryDocumentSnapshot? resident;

      for (var doc in _residents) {
        if (doc['wing'] == _selectedWing && doc['flatNumber'] == flatNumber) {
          resident = doc;
          break;
        }
      }

      setState(() {
        if (resident != null) {
          _residentName = '${resident['firstName']} ${resident['lastName']}';
          _residentId = resident.id.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resident found: $_residentName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _residentName = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No resident found in Wing $_selectedWing, Flat $flatNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching resident: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _proofImage = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (_proofImage == null) throw Exception('Please choose an image first');

      final response = await cloudinary.upload(
          file: _proofImage!.path,
          resourceType: CloudinaryResourceType.image,
          folder: "penalties",
          progressCallback: (count, total) {
            setState(() => uploadProgress = count / total);
          });

      if (response.isSuccessful) {
        setState(() {
          _imageUrl = response.secureUrl;
          uploadProgress = 0.0;
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  sendPenaltyNoti(
      {desingation = 0,
      amount = 0,
      reason = "",
      residentName = "",
      userId = ""}) async {
    try {
      final url = Uri.parse('http://192.168.29.138:3000/penalty');

      List arr = [
        'Member',
        'Committee Member',
        'Treasurer',
        'Chairperon',
        'Secretary'
      ];

      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      Map<String, dynamic> body = {
        'user_id': userId,
        'designator': arr[desingation],
        'amount': amount,
        'reason': reason,
        'residentName': residentName,
      };
      String jsonBody = json.encode(body);
      final response = await http.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
      } else {
        print("User has not registered yet with the application");
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _submitPenalty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }
    if (_residentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please search and select a valid resident')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_proofImage != null && _imageUrl == null) {
        await _uploadImage();
      }

      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.build_data.id)
          .collection('penalties')
          .add({
        'wing': _selectedWing,
        'flatNumber': _flatNumberController.text.trim(),
        'residentName': _residentName,
        'residentId': _residentId,
        'reason': _reasonController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'proofImage': _imageUrl,
        'createdAt': Timestamp.now(),
        'createdBy':
            '${widget.user_data['firstName']} ${widget.user_data['lastName']}',
        'createdById': widget.user_data.id.toString(),
        'createdByDesignation': widget.user_data[
            'designation'], //While displaying the designation map it to suitable pronouns
        'dueDate': _dueDate?.toIso8601String(),
        'status': false,
        'pay_id': ""
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penalty added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();

      sendPenaltyNoti(
        residentName: _residentName,
        userId: _residentId,
        desingation: widget.user_data['designation'],
        reason: _reasonController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _formKey.currentState?.reset();
    _flatNumberController.clear();
    _reasonController.clear();
    _amountController.clear();
    setState(() {
      _selectedWing = null;
      _residentName = null;
      _proofImage = null;
      _imageUrl = null;
      _dueDate = null;
      uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Penalty', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
      ),
      body: _isLoading && _residents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[50]!, Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_buildingName != null)
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Building: $_buildingName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedWing,
                                decoration: const InputDecoration(
                                  labelText: 'Wing',
                                  border: OutlineInputBorder(),
                                ),
                                items: _wings.map((wing) {
                                  return DropdownMenuItem(
                                    value: wing,
                                    child: Text(wing),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedWing = value;
                                    _residentName = null;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a wing';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _flatNumberController,
                                      decoration: const InputDecoration(
                                        labelText: 'Flat Number',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a flat number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _searchResident,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.search),
                                    label: const Text('Search'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_residentName != null) ...[
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.green),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Resident: $_residentName',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for Penalty',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a reason';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Penalty Amount',
                                  border: OutlineInputBorder(),
                                  prefixText: '₹ ',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date: ${_dueDate?.toString().split(' ')[0] ?? 'Not selected'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _selectDueDate,
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Select Due Date'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.image,
                                          color: Colors.blue[700]),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          _proofImage != null
                                              ? 'Image selected: ${_proofImage!.path.split('/').last}'
                                              : 'Upload Proof (Image)',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_proofImage != null) ...[
                                const SizedBox(height: 10),
                                Image.file(_proofImage!, height: 150),
                                const SizedBox(height: 10),
                                if (_imageUrl == null) ...[
                                  ElevatedButton(
                                    onPressed: _uploadImage,
                                    child: const Text("Upload Image"),
                                  ),
                                  if (uploadProgress > 0 && uploadProgress < 1)
                                    LinearProgressIndicator(
                                        value: uploadProgress),
                                ] else
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitPenalty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Penalty',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _flatNumberController.dispose();
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
