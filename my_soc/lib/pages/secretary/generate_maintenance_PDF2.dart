import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:intl/intl.dart';

class GenerateMaintenancePDF extends StatefulWidget {
  const GenerateMaintenancePDF({super.key});

  @override
  State<GenerateMaintenancePDF> createState() => _GenerateMaintenancePDFState();
}

class _GenerateMaintenancePDFState extends State<GenerateMaintenancePDF> {
  late DocumentSnapshot maintenanceDetails;
  late DocumentSnapshot userDetails;
  late DocumentSnapshot buildingDetails;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract the passed arguments
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    userDetails = args['userDetails'];
    buildingDetails = args['buildingDetails'];

    // Simulate fetching maintenance details
    final String maintenanceId = "LddCYmEggBVbGO8nZqcM";

    // Retrieve the maintenance details from Firestore
    FirebaseFirestore.instance.collection('maintenance').doc(maintenanceId).get().then((DocumentSnapshot doc) {
      setState(() {
        maintenanceDetails = doc;
        isLoading = false;
      });
    });
  }

  Future<void> generatePDF() async {
    if (isLoading) {
      return; // Wait for the Firestore data to be loaded
    }

    try {
      final pdf = pw.Document();

      // Extract maintenance charges and other details from Firestore and passed arguments
      final int maintenanceCharges = maintenanceDetails['maintenanceCharges'] ?? 0;
      final int serviceCharges = maintenanceDetails['serviceCharges'] ?? 0;
      final int repairCharges = maintenanceDetails['repairCharges'] ?? 0;
      final int otherCharges = maintenanceDetails['otherCharges'] ?? 0;
      final int lateFees = maintenanceDetails['lateFees'] ?? 0;

      // Parking charges based on user vehicles (car, scooter, cycle)
      int parkingCharges = 0;
      List vehicles = userDetails['vehicles'] ?? [];
      List<pw.TableRow> parkingRows = []; // List to hold parking charge breakdown rows

      for (var vehicle in vehicles) {
        // Correctly extract 'type' from the vehicle object
        String vehicleType = vehicle['type'] ?? '';
        switch (vehicleType.toLowerCase()) {
          case 'car':
            parkingCharges += 300;
            parkingRows.add(_buildTableRow("Car Parking", "300"));
            break;
          case 'scooter':
            parkingCharges += 150;
            parkingRows.add(_buildTableRow("Scooter Parking", "150"));
            break;
          case 'bicycle':
            parkingCharges += 50;
            parkingRows.add(_buildTableRow("Cycle Parking", "50"));
            break;
          default:
            break;
        }
      }

      // Calculate total charges
      final int totalCharges = maintenanceCharges +
          serviceCharges +
          repairCharges +
          otherCharges +
          lateFees +
          parkingCharges;

      // Date formatting
      final String currentDate = DateFormat('dd MMM yyyy').format(DateTime.now());
      final String dueDate = DateFormat('dd MMM yyyy').format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0));

      // Fetch society name, user name, and flat number from the passed arguments
      final String societyName = buildingDetails['buildingName'] ?? 'Unknown Society';
      final String userName = '${userDetails['firstName']} ${userDetails['lastName']}';
      final String flatNumber = userDetails['flatNumber'] ?? 'Unknown Flat';
      final String email = userDetails['email'] ?? 'Unknown Email';
      final String phoneNumber = userDetails['phone'] ?? 'Unknown Phone Number';
      final String buildingId = userDetails['buildingId'] ?? 'Unknown ID';

      // Generate the invoice ID (Building ID + User Flat Number + Current Month and Year)
      final String invoiceId = "$buildingId${userDetails['flatNumber']}${DateFormat('MMMyyyy').format(DateTime.now())}";  // e.g., 'A123Flat1Jan2025'

      // Add content to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(societyName,
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              
              // Invoice ID aligned to the left with the updated format
              pw.Text("Invoice ID = INV - $invoiceId",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // User Details Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Name: $userName", style: pw.TextStyle(fontSize: 16)),
                  pw.Text("Date: $currentDate", style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Phone: $phoneNumber", style: pw.TextStyle(fontSize: 16)),
                  pw.Text("Email: $email", style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Flat No: $flatNumber", style: pw.TextStyle(fontSize: 16)),
                  pw.Text("Due Date: $dueDate", style: pw.TextStyle(fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table for Charges
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow("Maintenance Charges", "$maintenanceCharges"),
                  _buildTableRow("Service Charges", "$serviceCharges"),
                  _buildTableRow("Repair Charges", "$repairCharges"),
                  _buildTableRow("Parking Charges", "$parkingCharges"), // Add total parking charges here
                  _buildTableRow("Other Charges", "$otherCharges"),
                  _buildTableRow("Late Fees", "$lateFees"),
                  pw.TableRow(
                    children: [
                      pw.Text("Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text("$totalCharges", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),

              // Breakdown Table for Parking Charges
              pw.Text("Parking Charges Breakdown:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Table(
                border: pw.TableBorder.all(),
                children: parkingRows, // Display the parking charges breakdown here
              ),
            ],
          ),
        ),
      );

      // Save the PDF to the device
      final String directoryPath = "/storage/emulated/0/Download";
      final String filePath = "$directoryPath/MaintenanceDetailsReport.pdf";

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved to: $filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  }

  // Helper method to build each row of the table
  pw.TableRow _buildTableRow(String chargeName, String amount) {
    return pw.TableRow(
      children: [
        pw.Text(chargeName, style: pw.TextStyle(fontSize: 16)),
        pw.Text(amount, style: pw.TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Download Maintenance Details PDF")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Download Maintenance Details PDF")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Generate and Download Maintenance PDF",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generatePDF,
              child: Text("Generate PDF"),
            ),
          ],
        ),
      ),
    );
  }
}
