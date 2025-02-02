import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ViewMainatainenanceJob extends StatefulWidget {
  const ViewMainatainenanceJob({super.key});

  @override
  State<ViewMainatainenanceJob> createState() => _ViewMainatainenanceJobState();
}

class _ViewMainatainenanceJobState extends State<ViewMainatainenanceJob> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

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
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Maintenance Jobs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('buildings')
                      .doc(build_details.id)
                      .collection('maintainenace_job')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading Maintenance Jobs',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                        color: Color(0xFFE94560),
                      ));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: const Color(0xFFE94560),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Maintenance Jobs found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var job = snapshot.data!.docs[index];

                          var startDate = DateTime.parse(job['startDate']);
                          String startDateString = DateFormat('MMMM dd, yyyy')
                              .format(startDate)
                              .toString();

                          var endDate = DateTime.parse(job['endDate']);
                          String endDateString = DateFormat('MMMM dd, yyyy')
                              .format(endDate)
                              .toString();

                          var dueDate = DateTime.parse(job['dueDate']);
                          String dueDateString = DateFormat('MMMM dd, yyyy')
                              .format(dueDate)
                              .toString();

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/viewDocDetails',
                                            arguments: {
                                              'buildingDetails':
                                                  build_details.id,
                                              'jobDetails': job.id,
                                            },
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoRow("Job ID:", job.id),
                                              _buildInfoRow("From Date:",
                                                  startDateString),
                                              _buildInfoRow(
                                                  "End Date:", endDateString),
                                              _buildInfoRow(
                                                  "Due Date:", dueDateString),
                                              _buildInfoRow("Charges:",
                                                  "\$${job['charges']}"),
                                              _buildInfoRow(
                                                  "Documents Created:",
                                                  job['docs_created']
                                                      .toString()),
                                              _buildInfoRow("Paid Count:",
                                                  job['paidCount'].toString()),
                                              _buildInfoRow(
                                                  "Unpaid Count:",
                                                  (job['docs_created'] -
                                                          job['paidCount'])
                                                      .toString()),
                                              _buildInfoRow("Errors:",
                                                  job['docs_error'].toString()),
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
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE94560),
        onPressed: () {
          Navigator.pushNamed(context, '/generatePDF', arguments: {
            'userDetails': user_details,
            'buildingDetails': build_details,
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
