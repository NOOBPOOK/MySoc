import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

  final List<Color> cardColors = const [
    Color(0xFF2C698D),
    Color(0xFF7B2CBF),
    Color(0xFF4CAF50),
    Color(0xFFE94560),
    Color(0xFF0F3460),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Successful: ${response.data}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Invoice downloaded successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Download Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text("Failed to download invoice"),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apartment_rounded,
                color: Color(0xFF2C698D),
                size: 32,
              ),
              const SizedBox(width: 12),
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Maintenance',
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
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C698D), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Maintenance Records",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your maintenance records will appear here",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(DocumentSnapshot maintain, Color cardColor) {
    var startDate = DateTime.parse(maintain['startDate']);
    var endDate = DateTime.parse(maintain['endDate']);
    var dueDate = DateTime.parse(maintain['dueDate']);
    var createDate = maintain['created_on'].toDate();
    bool isPaid = maintain['status'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: Colors.white,
            ),
          ),
          title: Text(
            '₹${maintain['amount'].toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${maintain['wing']} - ${maintain['flatNumber']}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    'Period Details',
                    [
                      'Created on: ${DateFormat('MMMM dd, yyyy').format(createDate)}',
                      'From: ${DateFormat('MMMM dd, yyyy').format(startDate)}',
                      'Till: ${DateFormat('MMMM dd, yyyy').format(endDate)}',
                      'Due Date: ${DateFormat('MMMM dd, yyyy').format(dueDate)}',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Payment Details',
                    [
                      'Job ID: ${maintain['job_id']}',
                      'Amount: ₹${maintain['amount']}',
                      'Status: ${isPaid ? 'Paid' : 'Pending'}',
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => download_pdf(
                            maintain['pdfLink'],
                            maintain.id.toString(),
                          ),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Download Invoice',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black26,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (!isPaid) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => handlePayments(maintain),
                            icon:
                                const Icon(Icons.payment, color: Colors.black),
                            label: const Text(
                              'Pay Now',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  detail,
                  style: const TextStyle(color: Colors.white),
                ),
              )),
        ],
      ),
    );
  }

  Future<String> createOrderId(job_id, maintain_id, amount) async {
    final url =
        Uri.parse("http://192.168.29.138:3000/generate/maintainenace_id");
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
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
    DateTime dateTime = DateTime.parse(maintain['dueDate']);
    Timestamp timestamp1 = Timestamp.fromDate(dateTime);
    Timestamp currentTime = Timestamp.now();
    int comp = currentTime.compareTo(timestamp1);
    var amount = maintain['amount'];

    if (comp > 0) {
      int diff = currentTime.seconds - timestamp1.seconds;
      int diffDays = (diff / (60 * 24 * 60)).round();
      amount += (5 * diffDays);

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF2C698D),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Late Payment Notice",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You are paying $diffDays days after the due date.\nA late fee of \$5 per day has been added.\nUpdated amount: \$$amount",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C698D),
                    ),
                    child: const Text(
                      "Understood",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final order_id = await createOrderId(
      maintain['job_id'],
      maintain.id,
      amount,
    );

    var options = {
      'key': dotenv.env['TEST_RAZORPAY_ID'],
      'amount': amount * 100,
      'order_id': order_id,
      'name': 'Inheritance Project',
      'description': 'Payment for Maintenance',
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
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('buildings')
                      .doc(build_details.id)
                      .collection('maintainenace')
                      .where('residentId', isEqualTo: user_details.id)
                      .orderBy('created_on', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading maintenance records',
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2C698D),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var maintain = snapshot.data!.docs[index];
                          Color cardColor =
                              cardColors[index % cardColors.length];

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child:
                                    _buildMaintenanceCard(maintain, cardColor),
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
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buildings')
            .doc(build_details.id)
            .collection('maintainenace')
            .where('residentId', isEqualTo: user_details.id)
            .where('status', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();

          int pendingPayments = snapshot.data!.docs.length;
          if (pendingPayments == 0) return Container();

          return FloatingActionButton.extended(
            onPressed: () {
              // Scroll to the first pending payment
              // You could implement this functionality if needed
            },
            backgroundColor: const Color(0xFF2C698D),
            icon: const Icon(Icons.warning_rounded, color: Colors.white),
            label: Text(
              '$pendingPayments Pending',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
