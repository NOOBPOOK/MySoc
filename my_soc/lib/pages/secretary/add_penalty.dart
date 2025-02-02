import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

  // Keep all the existing methods for data fetching and processing
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
      _showErrorMessage('Error fetching data: $e');
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
      _showErrorMessage('Please select a wing');
      return;
    }

    final flatNumber = _flatNumberController.text.trim();
    if (flatNumber.isEmpty) {
      _showErrorMessage('Please enter a flat number');
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
          _showSuccessMessage('Resident found: $_residentName');
        } else {
          _residentName = null;
          _showErrorMessage(
              'No resident found in Wing $_selectedWing, Flat $flatNumber');
        }
      });
    } catch (e) {
      _showErrorMessage('Error searching resident: $e');
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
      _showErrorMessage('Error selecting image: $e');
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
      _showErrorMessage('Error uploading image: $e');
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

  Future<void> sendPenaltyNoti({
    desingation = 0,
    amount = 0,
    reason = "",
    residentName = "",
    userId = "",
  }) async {
    try {
      final url = Uri.parse('http://192.168.29.138:3000/penalty');

      List arr = [
        'Member',
        'Committee Member',
        'Treasurer',
        'Chairperon',
        'Secretary'
      ];

      Map<String, String> headers = {'Content-Type': 'application/json'};
      Map<String, dynamic> body = {
        'user_id': userId,
        'designator': arr[desingation],
        'amount': amount,
        'reason': reason,
        'residentName': residentName,
      };
      String jsonBody = json.encode(body);
      final response = await http.post(url, headers: headers, body: jsonBody);

      if (response.statusCode != 201) {
        print("User has not registered yet with the application");
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _submitPenalty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      _showErrorMessage('Please select a due date');
      return;
    }
    if (_residentName == null) {
      _showErrorMessage('Please search and select a valid resident');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_proofImage != null && _imageUrl == null) {
        await _uploadImage();
      }

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
        'createdByDesignation': widget.user_data['designation'],
        'dueDate': _dueDate?.toIso8601String(),
        'status': false,
        'pay_id': ""
      });

      _showSuccessMessage('Penalty added successfully');

      await sendPenaltyNoti(
        residentName: _residentName,
        userId: _residentId,
        desingation: widget.user_data['designation'],
        reason: _reasonController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );

      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 800),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildResidentSearch(),
                            const SizedBox(height: 24),
                            _buildPenaltyDetails(),
                            const SizedBox(height: 24),
                            _buildImageUpload(),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Create Penalty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentSearch() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resident Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedWing,
            decoration: InputDecoration(
              hintText: "Select Wing",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              labelText: "Wing",
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            dropdownColor: const Color(0xFF1A1A2E),
            items: _wings.map((wing) {
              return DropdownMenuItem(
                value: wing,
                child: Text(
                  wing,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWing = value;
                _residentName = null;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _flatNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter flat number",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    labelText: "Flat Number",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE94560), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _searchResident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          if (_residentName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE94560).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Color(0xFFE94560),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _residentName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPenaltyDetails() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penalty Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter reason for penalty",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              labelText: "Reason",
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter penalty amount",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              labelText: "Amount (₹)",
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFFE94560)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _selectDueDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFE94560),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? 'Due Date: ${_dueDate!.toString().split(' ')[0]}'
                        : 'Select Due Date',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proof Image',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE94560).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _proofImage != null ? Icons.check_circle : Icons.cloud_upload,
                    color: const Color(0xFFE94560),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _proofImage != null
                        ? 'Image Selected'
                        : 'Upload Proof Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_proofImage == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tap to browse files',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_proofImage != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _proofImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (uploadProgress > 0 && uploadProgress < 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  value: uploadProgress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPenalty,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLoading ? 'Submitting...' : 'Submit Penalty',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isLoading) ...[
              const SizedBox(width: 8),
              const Icon(Icons.send, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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