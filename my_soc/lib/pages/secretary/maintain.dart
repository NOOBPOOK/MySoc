/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Maintain extends StatefulWidget {
  const Maintain({super.key});

  @override
  State<Maintain> createState() => _MaintainState();
}

class _MaintainState extends State<Maintain> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    // Add all the listeners for payment
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Handle payment success
    print("Payment Successful: ${response.data}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment failure
    print("Payment Failed: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet selection
    print("External Wallet Selected: ${response.walletName}");
  }

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

  Future<String> createOrderId(job_id, maintain_id, amount) async {
    final url =
        Uri.parse("http://192.168.29.138:3000/generate/maintainenace_id");
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      String jsonBody = jsonEncode({'amount': amount, 'id': maintain_id});
      var response = await http.post(url, headers: headers, body: jsonBody);
      var resp_data = json.decode(response.body);
      return resp_data['orderId'];
    } catch (e) {
      print("Error in creating order id: $e");
      return "";
    }
  }

  void handlePayments(maintain) async {
    // Check if the due Date is passed
    DateTime dateTime = DateTime.parse(maintain['dueDate']);
    Timestamp timestamp1 = Timestamp.fromDate(dateTime);

    Timestamp currentTime = Timestamp.now();
    int comp = currentTime.compareTo(timestamp1);

    var amount = maintain['amount'];

    if (comp > 0) {
      int diff = currentTime.seconds - timestamp1.seconds;
      int diffDays = (diff / (60 * 24 * 60)).round();
      print("Number of days $diffDays}");
      // Add 5$ for each day
      amount += (5 * diffDays);

      // Notify the user about the extra charges
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Extra Charges"),
              content: Text(
                  "You are paying ${diffDays} days after due date. \n So after adding 5# after each day. \n The updated amount is ${amount}"),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Close"))
              ],
            );
          });
    }

    final order_id =
        await createOrderId(maintain['job_id'], maintain.id, amount);

    var options = {
      'key': dotenv.env['TEST_RAZORPAY_ID'],
      'amount': amount * 100,
      'order_id': order_id,
      'name': 'Inheritance Project',
      'description': 'Payment for Maintainence',
      'prefill': {
        'contact': user_details['phone'],
        'email': user_details['email'],
      },
      'notes': {
        'arg_id': maintain.id,
        'job_id': maintain['job_id'],
        'build_id': build_details.id,
        'reason': 'maintainenance',
      },
      'external': {
        'wallets': ['paytm', 'gpay']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Your Maintenance'),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('buildings')
              .doc(build_details.id)
              .collection('maintainenace')
              .where('residentId', isEqualTo: user_details.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // print(snapshot.error.toString());
              return Center(
                child: Text(
                  'Error loading Your Maintenance',
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
                      'No Maintainenance found for your account',
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
                  var maintain = snapshot.data!.docs[index];

                  var startDate = DateTime.parse(maintain['startDate']);
                  String startDateString =
                      DateFormat('MMMM dd, yyyy').format(startDate).toString();

                  var tillDate = DateTime.parse(maintain['endDate']);
                  String tillDateString =
                      DateFormat('MMMM dd, yyyy').format(tillDate).toString();

                  var dueDate = DateTime.parse(maintain['dueDate']);
                  String dueDateString =
                      DateFormat('MMMM dd, yyyy').format(dueDate).toString();

                  var create = DateTime.parse(
                      maintain['created_on'].toDate().toString());
                  String createDateString =
                      DateFormat('MMMM dd, yyyy').format(create).toString();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Created on: $createDateString'),
                          Text(
                              '${maintain['wing']} - ${maintain['flatNumber']}'),
                          Text('From: $startDateString'),
                          Text('Till: $tillDateString'),
                          Text('Due Date: $dueDateString'),
                          Text('Job ID group: ${maintain['job_id']}'),
                          Text('Amount: ${maintain['amount']}'),
                          Text('Status: ${maintain['status']}'),
                          ElevatedButton(
                              onPressed: () {
                                download_pdf(maintain['pdfLink'],
                                    maintain.id.toString());
                              },
                              child: Text("Download Invoice")),
                          if (maintain['status'] == true)
                            ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        DateTime paymentDate = DateTime.parse(
                                            maintain['paid_on'].toString());
                                        String paymentDateString =
                                            DateFormat('MMMM dd, yyyy')
                                                .format(paymentDate)
                                                .toString();

                                        return AlertDialog(
                                          title: Text("Payment Details"),
                                          content: Container(
                                            height: 200,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Transaction ID: ${maintain['pay_id']}'),
                                                Text(
                                                    'Payment Date: ${paymentDateString}'),
                                                Text(
                                                    'Amount Paid: ${maintain['paidAmount']}'),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("Close"))
                                          ],
                                        );
                                      });
                                },
                                child: Text("Payment Details")),
                          if (maintain['status'] == false)
                            ElevatedButton(
                                onPressed: () {
                                  handlePayments(maintain);
                                },
                                child: Text("Pay Now")),
                        ],
                      ),
                    ),
                  );
                });
          }),
    ));
  }
}*/
