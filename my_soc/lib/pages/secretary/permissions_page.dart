import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PermissionsPage extends StatefulWidget {
  @override
  _PermissionsPageState createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final amenityController = TextEditingController();
  final purposeController = TextEditingController();
  final numberOfPeopleController = TextEditingController();
  final additionalNotesController = TextEditingController();
  final organizerNameController = TextEditingController();
  final organizerPhoneController = TextEditingController();
  bool acceptedTerms = false;
  bool isLoading = true;
  List<String> availableAmenities = [];
  String? buildingId;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userDoc.docs.isEmpty) return;

      buildingId = userDoc.docs.first['buildingId'];
      userId = userDoc.docs.first.id;

      final buildingDoc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .get();

      if (buildingDoc.exists) {
        setState(() {
          availableAmenities =
              List<String>.from(buildingDoc['amenities'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading amenities: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _validateTimeRange() {
    if (startDate == null || startTime == null || endTime == null) {
      return false;
    }

    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      startTime!.hour,
      startTime!.minute,
    );

    final end = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      endTime!.hour,
      endTime!.minute,
    );

    return end.isAfter(start);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() ||
        !_validateTimeRange() ||
        !acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !acceptedTerms
                ? 'Please accept the terms and conditions'
                : 'Please fill all required fields and ensure end time is after start time',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final startDateTime = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      final endDateTime = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        endTime!.hour,
        endTime!.minute,
      );

      // Check for booking conflicts
      final existingBookings = await FirebaseFirestore.instance
          .collection('permissions')
          .where('buildingId', isEqualTo: buildingId)
          .where('startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime))
          .where('startDateTime',
              isLessThanOrEqualTo: Timestamp.fromDate(endDateTime))
          .where('status', isEqualTo: 'approved')
          .get();

      if (existingBookings.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This time slot conflicts with an existing booking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      for (var doc in existingBookings.docs) {
        final existingStart = (doc['startDateTime'] as Timestamp).toDate();
        final existingEnd = (doc['endDateTime'] as Timestamp).toDate();

        if ((startDateTime.isAfter(existingStart) &&
                startDateTime.isBefore(existingEnd)) ||
            (endDateTime.isAfter(existingStart) &&
                endDateTime.isBefore(existingEnd)) ||
            (startDateTime.isBefore(existingStart) &&
                endDateTime.isAfter(existingEnd))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('This time slot conflicts with an existing booking'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      await FirebaseFirestore.instance.collection('permissions').add({
        'userId': userId,
        'buildingId': buildingId,
        'amenityName': amenityController.text,
        'purpose': purposeController.text,
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
        'numberOfPeople': int.parse(numberOfPeopleController.text),
        'organizerName': organizerNameController.text,
        'organizerPhone': organizerPhoneController.text,
        'additionalNotes': additionalNotesController.text,
        'acceptedTerms': acceptedTerms,
        'requestedAt': Timestamp.now(),
        'status': 'pending',
        'remarks': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        startDate = null;
        startTime = null;
        endTime = null;
        acceptedTerms = false;
        amenityController.clear();
        purposeController.clear();
        numberOfPeopleController.clear();
        additionalNotesController.clear();
        organizerNameController.clear();
        organizerPhoneController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRequestForm() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
        : AnimationLimiter(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildSectionHeader('Organizer Information'),
                      _buildTextField(
                        controller: organizerNameController,
                        label: 'Organizer Name',
                        icon: Icons.person,
                      ),
                      _buildTextField(
                        controller: organizerPhoneController,
                        label: 'Contact Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildSectionHeader('Booking Details'),
                      _buildTextField(
                        controller: amenityController,
                        label: 'Amenity You want to book',
                        icon: Icons.place,
                      ),
                      _buildTextField(
                        controller: purposeController,
                        label: 'Purpose of Booking',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      _buildTextField(
                        controller: numberOfPeopleController,
                        label: 'Number of People',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                      ),
                      _buildSectionHeader('Date and Time'),
                      _buildDateTimePicker(),
                      _buildTextField(
                        controller: additionalNotesController,
                        label: 'Additional Notes (Optional)',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                      _buildTermsAndConditions(),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Color(0xFFE94560)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE94560), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) =>
            value?.isEmpty ?? true ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  startDate == null
                      ? 'Start Date'
                      : DateFormat('dd/MM/yyyy').format(startDate!),
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(Icons.calendar_today, color: Color(0xFFE94560)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  startTime == null ? 'Start Time' : startTime!.format(context),
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(Icons.access_time, color: Color(0xFFE94560)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => startTime = time);
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text(
                  endTime == null ? 'End Time' : endTime!.format(context),
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(Icons.access_time, color: Color(0xFFE94560)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => endTime = time);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms and Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '1. The amenity must be used only for the stated purpose\n'
            '2. The number of people must not exceed the stated count\n'
            '3. Any damage to the facility will be charged\n'
            '4. Cancellation must be made at least 24 hours in advance\n'
            '5. The premises must be cleared and cleaned after use',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          Row(
            children: [
              Checkbox(
                value: acceptedTerms,
                onChanged: (value) {
                  setState(() => acceptedTerms = value ?? false);
                },
                activeColor: Color(0xFFE94560),
              ),
              Expanded(
                child: Text(
                  'I accept all terms and conditions and agree to comply with the rules and regulations',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFE94560),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Submit Request',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Custom header similar to announcements.dart
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .assignment, // Use an appropriate icon for permissions
                            color: Color(0xFFE94560),
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Permissions',
                                textStyle: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                speed: const Duration(milliseconds: 100),
                              ),
                            ],
                            isRepeatingAnimation: false,
                            totalRepeatCount: 1,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
                // TabBar and TabBarView
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Color(0xFFE94560),
                        tabs: [
                          Tab(text: 'Request Permission'),
                          Tab(text: 'My Requests'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildRequestForm(),
                            _buildUserRequests(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('permissions')
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No permission requests found',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: requests.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;

              // Handle null values for required fields
              final amenityName = data['amenityName'] ?? 'Unknown Amenity';
              final purpose = data['purpose'] ?? 'Not Specified';
              final status = data['status'] ?? 'unknown';
              final startDateTime = data['startDateTime'] != null
                  ? (data['startDateTime'] as Timestamp).toDate()
                  : null;
              final endDateTime = data['endDateTime'] != null
                  ? (data['endDateTime'] as Timestamp).toDate()
                  : null;
              final numberOfPeople = data['numberOfPeople'] ?? 'N/A';
              final organizerName = data['organizerName'] ?? 'N/A';
              final organizerPhone = data['organizerPhone'] ?? 'N/A';
              final additionalNotes =
                  data['additionalNotes'] ?? 'No additional notes';
              final remarks = data['remarks'] ?? 'No remarks';

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 600),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        title: Text(
                          amenityName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Purpose: $purpose',
                                style: TextStyle(color: Colors.white70)),
                            if (startDateTime != null)
                              Text(
                                  'Start: ${DateFormat('dd/MM/yyyy HH:mm').format(startDateTime)}',
                                  style: TextStyle(color: Colors.white70)),
                            if (endDateTime != null)
                              Text(
                                  'End: ${DateFormat('dd/MM/yyyy HH:mm').format(endDateTime)}',
                                  style: TextStyle(color: Colors.white70)),
                            if (startDateTime == null || endDateTime == null)
                              Text('Time: Not Specified',
                                  style: TextStyle(color: Colors.white70)),
                            Text('Number of People: $numberOfPeople',
                                style: TextStyle(color: Colors.white70)),
                            Text('Organizer: $organizerName',
                                style: TextStyle(color: Colors.white70)),
                            Text('Contact: $organizerPhone',
                                style: TextStyle(color: Colors.white70)),
                            if (additionalNotes.isNotEmpty)
                              Text('Notes: $additionalNotes',
                                  style: TextStyle(color: Colors.white70)),
                            Text(
                              'Status: ${status[0].toUpperCase() + status.substring(1)}',
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (remarks.isNotEmpty)
                              Text('Remarks: $remarks',
                                  style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
