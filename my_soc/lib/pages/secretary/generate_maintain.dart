import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CreateMaintain extends StatefulWidget {
  const CreateMaintain({super.key});

  @override
  State<CreateMaintain> createState() => _CreateMaintainState();
}

class _CreateMaintainState extends State<CreateMaintain> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  DateTime? dueDate;
  List charges = [];
  List controllers = [];

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

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
          child: SingleChildScrollView(
            child: AnimationLimiter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 800),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const Text(
                        'Create Maintenance',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
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
                              "From Month",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              tileColor: Colors.white.withOpacity(0.1),
                              title: Text(
                                DateFormat('dd/MM/yyyy').format(startDate),
                                style: const TextStyle(color: Colors.white),
                              ),
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFFE94560),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  lastDate:
                                      DateTime.now().add(Duration(days: 120)),
                                  firstDate: DateTime.now()
                                      .subtract(Duration(days: 120)),
                                );
                                if (date != null) {
                                  setState(() => startDate = date);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "To Month",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              tileColor: Colors.white.withOpacity(0.1),
                              title: Text(
                                DateFormat('dd/MM/yyyy').format(endDate),
                                style: const TextStyle(color: Colors.white),
                              ),
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFFE94560),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate.add(Duration(days: 1)),
                                  lastDate:
                                      DateTime.now().add(Duration(days: 90)),
                                  firstDate: DateTime.now()
                                      .subtract(Duration(days: 120)),
                                );
                                if (date != null) {
                                  setState(() => endDate = date);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Due Date for Payment",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              tileColor: Colors.white.withOpacity(0.1),
                              title: Text(
                                dueDate == null
                                    ? 'Select Due Date'
                                    : DateFormat('dd/MM/yyyy').format(dueDate!),
                                style: const TextStyle(color: Colors.white),
                              ),
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFFE94560),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate:
                                      DateTime.now().add(Duration(days: 90)),
                                );
                                if (date != null) {
                                  setState(() => dueDate = date);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
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
                              "Additional Charges",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Parking charges will be added automatically",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...charges,
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  TextEditingController controller =
                                      TextEditingController();
                                  controllers.add(controller);

                                  TextEditingController valueController =
                                      TextEditingController();
                                  controllers.add(valueController);

                                  charges.add(
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: controller,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: 'Charge Name',
                                                hintStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFE94560),
                                                    width: 2,
                                                  ),
                                                ),
                                                fillColor: Colors.white
                                                    .withOpacity(0.1),
                                                filled: true,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: valueController,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: 'Amount',
                                                hintStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFE94560),
                                                    width: 2,
                                                  ),
                                                ),
                                                fillColor: Colors.white
                                                    .withOpacity(0.1),
                                                filled: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE94560),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text("Add Charges"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (startDate.isBefore(endDate) && dueDate != null) {
                            final url = Uri.parse(
                                "http://192.168.29.138:3000/maintainenace");

                            try {
                              Map<String, String> headers = {
                                'Content-Type': 'application/json',
                              };

                              final chargesMap = {};
                              for (int i = 0; i < controllers.length; i += 2) {
                                chargesMap[controllers[i].text.trim()] =
                                    controllers[i + 1].text.trim();
                              }

                              String jsonBody = jsonEncode({
                                'buildingName': build_details['buildingName'],
                                'buildingId': build_details.id,
                                'secId': user_details.id,
                                'startDate': startDate.toIso8601String(),
                                'endDate': endDate.toIso8601String(),
                                'dueDate': dueDate!.toIso8601String(),
                                'charges': chargesMap,
                              });

                              await http.post(url,
                                  headers: headers, body: jsonBody);

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'You will be notified about the Maintenance approval'),
                                backgroundColor: Color(0xFFE94560),
                              ));
                            } catch (e) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Error in creating Maintenance'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Please select valid dates for all fields'),
                              backgroundColor: Colors.red,
                            ));
                          }
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
                          "Create Maintenance",
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
    );
  }
}
