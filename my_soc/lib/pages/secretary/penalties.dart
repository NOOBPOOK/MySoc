// This page displays all the penalties applied to all users within this building
// Modify it so that only users can get to know thier own penalties.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/pages/secretary/add_penalty.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PenaltiesPage extends StatefulWidget {
  PenaltiesPage({super.key});

  @override
  State<PenaltiesPage> createState() => _PenaltiesPageState();
}

class _PenaltiesPageState extends State<PenaltiesPage> {
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

  void dispose() {
    _razorpay.clear();
    super.dispose();
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

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _generateOrder(
      {required QueryDocumentSnapshot penalty_info,
      required dynamic amount}) async {
    // print("This function is called 2");
    // Make a server call to generate id
    final url = Uri.parse("http://192.168.29.138:3000/generate/penalty_id");

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      String jsonBody = jsonEncode({'amount': amount, 'id': penalty_info.id});

      var response = await http.post(url, headers: headers, body: jsonBody);
      var resp_data = json.decode(response.body);
      return resp_data['orderId'];
    } catch (e) {
      print(e.toString());
      return "";
    }
  }

  void _handlePenaltiesPayments(
      {required QueryDocumentSnapshot penalty_info}) async {
    // Check if the due date is passed
    // Step 1: Parse ISO 8601 string into a DateTime object
    DateTime dateTime = DateTime.parse(penalty_info['dueDate']);
    Timestamp timestamp1 = Timestamp.fromDate(dateTime);

    Timestamp currentTime = Timestamp.now();

    int comp = currentTime.compareTo(timestamp1);
    // print(comp);

    var amount = penalty_info['amount'];

    // Check if due date has passed
    if (comp > 0) {
      int diff = currentTime.seconds - timestamp1.seconds;
      int diffDays = (diff / (60 * 24 * 60)).round();
      print("Number of days $diffDays}");
      // Add 5$ for each day
      amount += (5 * diffDays);
      // Now show a display box about updated value

      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Payment Dues"),
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

    // print("This function is called");
    final order_id =
        await _generateOrder(penalty_info: penalty_info, amount: amount);
    // print('The order for our payment is ${order_id}');
    var options = {
      'key': dotenv.env['TEST_RAZORPAY_ID'],
      'amount': amount * 100,
      'order_id': order_id,
      'name': 'Inheritance Project',
      'description': 'Payment for penalties',
      'prefill': {
        'contact': user_details['phone'],
        'email': user_details['email'],
      },
      'notes': {
        'arg_id': penalty_info.id,
        'build_id': build_details.id,
        'reason': 'penalty',
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
    // Load the args sent from home page
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penalties'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buildings')
            .doc(build_details.id)
            .collection('penalties')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error.toString());
            return Center(
              child: Text(
                'Error loading penalties',
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
                    'No penalties found',
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
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              print(index);
              var penalty = snapshot.data!.docs[index];
              DateTime createdAt = (penalty['createdAt'] as Timestamp).toDate();
              bool isPaid = penalty['status'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isPaid ? Colors.green : Colors.red,
                    child: Icon(
                      isPaid ? Icons.check : Icons.currency_rupee,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '₹${penalty['amount'].toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    createdAt.toString().split('.')[0],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            isPaid ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaid ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          isPaid
                              ? null
                              : _handlePenaltiesPayments(penalty_info: penalty);
                        },
                        child: Text(
                          isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(penalty['reason']),
                          const SizedBox(height: 16),
                          if (penalty['proofImage'] != null) ...[
                            Text(
                              'Proof of Violation:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showImageDialog(
                                  context, penalty['proofImage']),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    penalty['proofImage'],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the add_penalties.dart page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPenalty(
                user_data: user_details,
                build_data: build_details,
              ), // Replace with the correct AddPenaltiesPage
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
