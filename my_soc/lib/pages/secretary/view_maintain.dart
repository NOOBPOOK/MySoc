import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ViewMainatainenanceJob extends StatefulWidget {
  const ViewMainatainenanceJob({super.key});

  @override
  State<ViewMainatainenanceJob> createState() => _ViewMainatainenanceJobState();
}

class _ViewMainatainenanceJobState extends State<ViewMainatainenanceJob> {
  // Load the args sent from home page
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('View Maintainance Jobs'),
      ),
      body: Stack(
        children: [
          StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('buildings')
                  .doc(build_details.id)
                  .collection('maintainenace_job')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // print(snapshot.error.toString());
                  return Center(
                    child: Text(
                      'Error loading Maintainenace Jobs',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Maintainenance Job found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
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

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text("Job ID: "),
                                      Text(job.id),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("From Date: "),
                                      Text(startDateString),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("End Date: "),
                                      Text(endDateString),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Due Date: "),
                                      Text(dueDateString),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Charges: "),
                                      Text(job['charges'].toString()),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Documents Created: "),
                                      Text(job['docs_created'].toString()),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Paid Count: "),
                                      Text(job['paidCount'].toString()),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Unpaid Count: "),
                                      Text((job['docs_created'] -
                                              job['paidCount'])
                                          .toString()),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Errow while correcting Docs: "),
                                      Text(job['docs_error'].toString()),
                                    ],
                                  )
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/viewDocDetails',
                                  arguments: {
                                    'buildingDetails': build_details.id,
                                    'jobDetails': job.id,
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    });
              }),
          Positioned(
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/generatePDF', arguments: {
                      'userDetails': user_details,
                      'buildingDetails': build_details,
                    });
                  },
                  child: Icon(Icons.add)),
            ),
          )
        ],
      ),
    ));
  }
}

class ViewAllDocDetails extends StatefulWidget {
  const ViewAllDocDetails({super.key});

  @override
  State<ViewAllDocDetails> createState() => _ViewAllDocDetailsState();
}

class _ViewAllDocDetailsState extends State<ViewAllDocDetails> {
  late Map args;
  String jobTitle = '';
  late String doc_id;

  void download_pdf(String url, String file_name) async {
    try {
      Dio dio = Dio();

      final dir = Directory('/storage/emulated/0/Download');
      String path = "${dir.path}/$file_name.pdf";

      await dio.download(url, path, onReceiveProgress: (rec, total) {
        print('Rec: $rec, Total: $total');
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 2),
          content: Text("Downloaded the invoice")));
    } catch (e) {
      print("Download Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    jobTitle = args['jobDetails'];
    doc_id = args['buildingDetails'];

    return Scaffold(
        appBar: AppBar(
          title: Text(jobTitle),
        ),
        body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('buildings')
                .doc(doc_id)
                .collection('maintainenace')
                .where('job_id', isEqualTo: jobTitle)
                .orderBy('status')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // print(snapshot.error.toString());
                return Center(
                  child: Text(
                    'Error loading Maintainenace Documents',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Maintainenace Documents found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];

                    String dueDateString = 'Within Due Date';
                    var due = DateTime.parse(doc['dueDate']);

                    if (due.isBefore(DateTime.now())) {
                      dueDateString = 'Over Due Date';
                    }

                    return ListTile(
                      // leading: Text("${doc['wing']} - ${doc['flatNumber']}"),
                      onLongPress: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String formatDue = DateFormat('MMMM dd, yyyy')
                                  .format(due)
                                  .toString();

                              return AlertDialog(
                                title: Text(
                                    "${doc['wing']} - ${doc['flatNumber']}"),
                                content: Container(
                                  height: 150,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Email: ${doc['residentEmail']}"),
                                      Text("Due Date: ${formatDue}"),
                                      Text("Amount: ${doc['amount']}"),
                                      Text("Paid: ${doc['status']}"),
                                      Text(
                                          "Amount Paid + Dues: ${doc['paidAmount']}"),
                                      Text("Paid on: ${doc['paid_on']}"),
                                    ],
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        download_pdf(doc['pdfLink'], doc.id);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                duration: Duration(seconds: 2),
                                                content: Text(
                                                    "Downloading the invoice ..")));
                                      },
                                      child: Text("Download Invoice")),
                                ],
                              );
                            });
                      },
                      trailing: doc['status']
                          ? Icon(Icons.done)
                          : Icon(Icons.pending_actions),
                      title: Text("${doc['wing']} - ${doc['flatNumber']}"),
                      subtitle: Text(
                          "Maintainenace due of ${doc['amount']} \$ \n ${dueDateString}"),
                    );
                  });
            }));
  }
}
