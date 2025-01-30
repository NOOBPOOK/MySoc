import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AdminPayments extends StatefulWidget {
  const AdminPayments({super.key});

  @override
  State<AdminPayments> createState() => _AdminPaymentsState();
}

class _AdminPaymentsState extends State<AdminPayments> {
  // Displays Extra information about content

  Future _showExtraInfo(context, payment) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          Map data = {};
          bool isLoading = true;
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
            void loadData(String desc, build, doc_id) async {
              print("Call");
              try {
                String type = "";
                // Check whether its a penalty
                if (desc.contains('penalties')) {
                  type = 'penalties';
                }

                // Maintenance implementation to be done later
                if (desc.contains('maintainenance')) {
                  type = 'maintainenance';
                }

                DocumentSnapshot result = await FirebaseFirestore.instance
                    .collection('buildings')
                    .doc(build)
                    .collection(type)
                    .doc(doc_id)
                    .get();
                data['data'] = result.data() as Map;
                isLoading = false;
                setDialogState(() {});
              } catch (e) {
                print(e);
                // Navigator.of(context).pop();
                data['message'] = 'No data available';
                isLoading = false;
                setDialogState(() {});
              }
            }

            if (isLoading) {
              loadData(payment['description'], payment['build_id'],
                  payment['doc_id']);
              // For testing purpose delay
              // Future.delayed(Duration(seconds: 3), () {
              //   loadData(payment['description'], payment['build_id'],
              //       payment['doc_id']);
              // });
            }

            return AlertDialog(
              title: Text(payment['description']),
              content: Container(
                height: 300,
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['message'] == 'No data available')
                              Center(
                                child: Text("No data available"),
                              )
                            else
                              ...data['data'].entries.map((entry) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    // mainAxisAlignment:
                                    //     MainAxisAlignment.start,
                                    // crossAxisAlignment:
                                    //     CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.key}: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(entry.value.toString()),
                                    ],
                                  ),
                                );
                              }).toList(), // Spread operator here to convert Iterable to individual widgets
                          ],
                        ),
                      ),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data.toString()));
                      Future.delayed(Duration(seconds: 1), () {
                        Navigator.of(context).pop();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text('Copied to clipboard'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: Text("Copy data")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Close")),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print(snapshot.error.toString());
              return Center(
                child: Text(
                  'Error loading payments',
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
                      'No payments found',
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
                  var payment = snapshot.data!.docs[index];

                  // Convert Firebase Timestamp to DateTime
                  DateTime dateTimeFromSeconds =
                      DateTime.fromMillisecondsSinceEpoch(
                          payment['time'] * 1000);

                  // Format DateTime using intl package
                  String formattedDate = DateFormat('yyyy-MM-dd HH:mm')
                      .format(dateTimeFromSeconds);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.cyanAccent,
                      child: GestureDetector(
                        onTap: () {
                          _showExtraInfo(context, payment);
                        },
                        child: Column(
                          children: [
                            Text('Payment id ${payment['payment_id']}'),
                            Text('Order id ${payment['order_id']}'),
                            Text('Date is ${formattedDate}'),
                            Text('Building id ${payment['build_id']}'),
                            Text('Amount is ${payment['amount'] / 100}'),
                            Text('Method is ${payment['method']}'),
                            Text('description ${payment['description']}'),
                            ElevatedButton(
                                onPressed: () {
                                  _showExtraInfo(context, payment);
                                },
                                child: Text("View Linked Document"))
                          ],
                        ),
                      ),
                    ),
                  );
                });
          }),
    );
  }
}
