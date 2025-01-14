import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pw;

class DownloadMaintenancePDF extends StatefulWidget {
  const DownloadMaintenancePDF({super.key});

  @override
  State<DownloadMaintenancePDF> createState() => _DownloadMaintenancePDFState();
}

class _DownloadMaintenancePDFState extends State<DownloadMaintenancePDF> {
  DocumentSnapshot? userDetails;
  DocumentSnapshot? buildingDetails;
  DocumentSnapshot? maintenanceDetails;
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic> args = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    if (args.containsKey('userDetails') && args.containsKey('buildingDetails')) {
      userDetails = args['userDetails'];
      buildingDetails = args['buildingDetails'];
      fetchMaintenanceDetails();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Missing required details")),
      );
    }
  }

  Future<void> fetchMaintenanceDetails() async {
    setState(() => isLoading = true);
    
    try {
      // Query maintenance collection for the specific user and month/year
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('maintenance')
          .where('userId', isEqualTo: userDetails!.id)
          .where('month', isEqualTo: selectedDate.month)
          .where('year', isEqualTo: selectedDate.year)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          maintenanceDetails = querySnapshot.docs.first;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No maintenance record found for ${DateFormat('MMMM yyyy').format(selectedDate)}")),
        );
        setState(() {
          maintenanceDetails = null;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching maintenance details: $e")),
      );
      setState(() {
        maintenanceDetails = null;
        isLoading = false;
      });
    }
  }

  Future<void> generatePDF() async {
    if (isLoading || maintenanceDetails == null) {
      return;
    }

    try {
      final pdf = pw.Document();

      // Extract data from documents
      final maintenanceData = maintenanceDetails!.data() as Map<String, dynamic>;
      final userData = userDetails!.data() as Map<String, dynamic>;
      final buildingData = buildingDetails!.data() as Map<String, dynamic>;
      
      // Format dates
      final dueDate = (maintenanceData['dueDate'] as Timestamp).toDate();
      final createdAt = (maintenanceData['createdAt'] as Timestamp).toDate();

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  buildingData['buildingName'] ?? 'Building Maintenance Receipt',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                ),
              ),
              pw.SizedBox(height: 20),

              // User Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoRow("Name", "${userData['firstName']} ${userData['lastName']}"),
                    _buildUserInfoRow("Flat", "Wing ${userData['wing']} - ${userData['flatNumber']}"),
                    _buildUserInfoRow("Phone", userData['phone']),
                    _buildUserInfoRow("Email", userData['email']),
                    _buildUserInfoRow("Generated Date", DateFormat('dd MMM yyyy').format(createdAt)),
                    _buildUserInfoRow("Due Date", DateFormat('dd MMM yyyy').format(dueDate)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Charges Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  _buildTableHeader(),
                  _buildTableRow("Maintenance Charges", "${maintenanceData['maintenanceCharges']}"),
                  _buildTableRow("Service Charges", "${maintenanceData['serviceCharges']}"),
                  _buildTableRow("Repair Charges", "${maintenanceData['repairCharges']}"),
                  _buildTableRow("Parking Charges", "${maintenanceData['parkingCharges']}"),
                  _buildTableRow("Other Charges", "${maintenanceData['otherCharges']}"),
                  _buildTableRow("Late Charges", "${maintenanceData['lateCharges']}"),
                  _buildTotalRow("Total Amount", "${maintenanceData['totalAmount']}"),
                ],
              ),
              
              pw.SizedBox(height: 20),

              // Parking Breakdown
              if (maintenanceData['parkingChargesBreakdown'] != null) ...[
                pw.Text(
                  "Parking Charges Breakdown:",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableHeader(),
                    if (maintenanceData['parkingChargesBreakdown']['car'] != null)
                      _buildTableRow("Car Parking", "${maintenanceData['parkingChargesBreakdown']['car']}"),
                    if (maintenanceData['parkingChargesBreakdown']['bike'] != null)
                      _buildTableRow("Bike Parking", "${maintenanceData['parkingChargesBreakdown']['bike']}"),
                    if (maintenanceData['parkingChargesBreakdown']['cycle'] != null)
                      _buildTableRow("Cycle Parking", "${maintenanceData['parkingChargesBreakdown']['cycle']}"),
                  ],
                ),
              ],

              pw.Spacer(),
              
              // Footer
              pw.Text(
                "Payment Status: ${maintenanceData['status']}".toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: maintenanceData['status'] == 'pending' ? pw.PdfColors.red : pw.PdfColors.green
                ),
              ),
            ],
          ),
        ),
      );

      final String directoryPath = "/storage/emulated/0/Download";
      final String fileName = "Maintenance_${userData['wing']}_${userData['flatNumber']}_${DateFormat('MMM_yyyy').format(selectedDate)}.pdf";
      final String filePath = "$directoryPath/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved to: $filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  }

  pw.Widget _buildUserInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            "$label: ",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: pw.PdfColors.grey300),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            "Description",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            "Amount",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.TableRow _buildTableRow(String description, String amount) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(description),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(amount),
        ),
      ],
    );
  }

  pw.TableRow _buildTotalRow(String description, String amount) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: pw.PdfColors.grey200),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            description,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            amount,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchMaintenanceDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maintenance Receipt"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Select Month",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _selectMonth,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (maintenanceDetails != null)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                "Total Amount: ₹${(maintenanceDetails!.data() as Map<String, dynamic>)['totalAmount']}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: generatePDF,
                                icon: const Icon(Icons.download),
                                label: const Text("Download Receipt"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Center(
                  child: Text(
                    "No maintenance record found for selected month",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}