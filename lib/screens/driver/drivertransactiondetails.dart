import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class DriverTransactionDetails extends StatefulWidget {
  @override
  _DriverTransactionDetails createState() => _DriverTransactionDetails();
}

class _DriverTransactionDetails extends State<DriverTransactionDetails> {
  Map<String, TextEditingController> weightControllers = {};
  Map<String, double> updatedWeights = {};

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String bookingId = args?['bookingId'] ?? 'Unknown';
    String status = args?['status'] ?? 'Unknown';
    String vehicle = args?['vehicle'] ?? 'Unknown';
    String vehicleId = args?['vehicleId'] ?? 'Unknown';
    double overallPrice = args?['overall_price']?.toDouble() ?? 0.0;
    double overallWeight = args?['overall_weight']?.toDouble() ?? 0.0;

    Timestamp? timestamp = args?['date'];
    DateTime? date = timestamp?.toDate();
    String formattedDate = date != null
        ? DateFormat('MM/dd/yyyy, EEEE').format(date)
        : 'Unknown Date';

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Text("Booking History Details",
                style: TextStyle(color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Maps(
                          bookingId: bookingId)), // Pushing the Maps widget
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                _generatePdf(context, bookingId, status, vehicle, vehicleId,
                    overallPrice, overallWeight, formattedDate);
              },
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * .95,
          height: MediaQuery.of(context).size.height * .90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 3),
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Details',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Booking ID: $bookingId',
                    style: const TextStyle(fontSize: 18)),
                Text('Status: $status', style: const TextStyle(fontSize: 18)),
                Text('Vehicle: $vehicle', style: const TextStyle(fontSize: 18)),
                Text('Vehicle ID: $vehicleId',
                    style: const TextStyle(fontSize: 18)),
                Text('Est. Total Price: ₱${overallPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18)),
                Text(
                    'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(fontSize: 18)),
                Text('Date: $formattedDate',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var users = userSnapshot.data?.docs ?? [];
                      if (users.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }

                      // Sorting logic for users
                      var nonCollectedUsers = users.where((userDoc) {
                        var userData = userDoc.data() as Map<String, dynamic>;
                        return userData['status'] == null ||
                            userData['status'] != 'collected';
                      }).toList();

                      var collectedUsers = users.where((userDoc) {
                        var userData = userDoc.data() as Map<String, dynamic>;
                        return userData['status'] == 'collected';
                      }).toList();

                      collectedUsers.sort((a, b) {
                        var aTimestamp = (a.data()
                                as Map<String, dynamic>)['collected_timestamp']
                            as Timestamp?;
                        var bTimestamp = (b.data()
                                as Map<String, dynamic>)['collected_timestamp']
                            as Timestamp?;
                        return aTimestamp
                                ?.compareTo(bTimestamp ?? Timestamp.now()) ??
                            0;
                      });

                      var sortedUsers = nonCollectedUsers + collectedUsers;

                      return ListView.builder(
                        itemCount: sortedUsers.length,
                        itemBuilder: (context, userIndex) {
                          var userData = sortedUsers[userIndex].data()
                              as Map<String, dynamic>;
                          String firstName = userData['firstName'] ?? 'Unknown';
                          String lastName = userData['lastName'] ?? 'Unknown';
                          String address = userData['address'] ?? 'Unknown';
                          String contact = userData['contact'] ?? 'Unknown';
                          String email = userData['email'] ?? 'Unknown';

                          // If user is collected, use final_total_price and final_total_weight
                          double totalPrice = userData['status'] == 'collected'
                              ? userData['final_total_price'] ?? 0.0
                              : userData['total_price'] ?? 0.0;
                          double totalWeight = userData['status'] == 'collected'
                              ? userData['final_total_weight'] ?? 0.0
                              : userData['total_weight'] ?? 0.0;
                          // Retrieve calculated_total_price or final_calculated_total_price from userData
                          double calculatedTotalPrice = userData['status'] ==
                                  'collected'
                              ? userData['final_calculated_total_price'] ?? 0.0
                              : userData['calculated_total_price'] ?? 0.0;

                          String userId = sortedUsers[userIndex].id;
                          String userStatus =
                              userData['status']?.isEmpty ?? true
                                  ? 'pending'
                                  : userData['status'];
                          bool isCollected = userStatus == 'collected';
                          Timestamp? collectedTimestamp =
                              userData['collected_timestamp'];
                          String collectedDate = collectedTimestamp != null
                              ? DateFormat('MM/dd/yyyy, HH:mm')
                                  .format(collectedTimestamp.toDate())
                              : 'N/A';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: isCollected ? Colors.lightGreen[100] : null,
                            child: ExpansionTile(
                              title: Text('$firstName $lastName',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${firstName == "Guest" ? "" : "Address: $address\n"}'
                                '${firstName == "Guest" ? "" : "Contact: $contact\n"}'
                                '${firstName == "Guest" ? "" : "Email: $email\n"}'
                                'Total Price: ₱$totalPrice\n'
                                'Calculated Total Price: ₱${calculatedTotalPrice.toStringAsFixed(2)}\n'
                                'Total Weight: ${totalWeight.toStringAsFixed(2)} kg\n'
                                'Driver Share: ₱${((((((totalPrice ?? 0.0) / (1 - 0.20)) + 40) - (totalPrice ?? 0.0)) * 0.25).toStringAsFixed(2))}\n'
                                '${userStatus == 'collected' ? 'Collected: $collectedDate' : ''}',
                              ),
                              children: [
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .doc(bookingId)
                                      .collection('users')
                                      .doc(userId)
                                      .collection('recyclables')
                                      .snapshots(),
                                  builder: (context, recyclableSnapshot) {
                                    if (!recyclableSnapshot.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    var recyclables =
                                        recyclableSnapshot.data?.docs ?? [];

                                    return ListView.builder(
                                      itemCount: recyclables.length,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, recIndex) {
                                        var recyclableData =
                                            recyclables[recIndex].data()
                                                as Map<String, dynamic>;
                                        String type =
                                            recyclableData['type'] ?? 'Unknown';
                                        double weight = isCollected
                                            ? recyclableData['final_weight'] ??
                                                recyclableData['weight']
                                            : recyclableData['weight'];
                                        double price =
                                            recyclableData['price'] ?? 0.0;
                                        double itemPrice = isCollected
                                            ? recyclableData[
                                                    'final_item_price'] ??
                                                weight * price
                                            : weight * price;
                                        String recyclableId =
                                            recyclables[recIndex].id;

                                        if (!weightControllers
                                            .containsKey(recyclableId)) {
                                          weightControllers[recyclableId] =
                                              TextEditingController(
                                                  text: weight.toString());
                                          updatedWeights[recyclableId] = weight;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Type: $type'),
                                              Text(
                                                  'Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg'),
                                              Text('Price: ₱$price'),
                                              Text(
                                                  'Item Price: ₱${(updatedWeights[recyclableId]! * price).toStringAsFixed(2)}'),
                                              const Divider(),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    String bookingId,
    String status,
    String vehicle,
    String vehicleId,
    double overallPrice,
    double overallWeight,
    String formattedDate,
  ) async {
    final pdf = pw.Document();

    // Collect user details asynchronously
    List<pw.Widget> userDetails = await _generateUserDetails(bookingId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            "Booking Details",
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text("Booking ID: $bookingId"),
          pw.Text("Status: $status"),
          pw.Text("Vehicle: $vehicle"),
          pw.Text("Vehicle ID: $vehicleId"),
          pw.Text("Est. Total Price: PHP ${overallPrice.toStringAsFixed(2)}"),
          pw.Text("Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg"),
          pw.Text("Date: $formattedDate"),
          pw.SizedBox(height: 20),
          pw.Text(
            "Users",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // Add user details here
          ...userDetails,
        ],
      ),
    );

    // Convert PDF to Uint8List
    final pdfBytes = await pdf.save();

    // Create a Blob and open in a new tab
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url); // Clean up the object URL
  }

  Future<List<pw.Widget>> _generateUserDetails(String bookingId) async {
    List<pw.Widget> userDetails = [];

    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      String firstName = userData['firstName'] ?? 'Unknown';
      String lastName = userData['lastName'] ?? 'Unknown';
      String address = userData['address'] ?? 'Unknown';
      String email = userData['email'] ?? 'Unknown';
      String contact = userData['contact'] ?? 'Unknown';
      double totalPrice = userData['total_price'] ?? 0.0;
      double totalWeight = userData['total_weight'] ?? 0.0;

      userDetails.add(pw.Text("$firstName $lastName",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      if (firstName != "Guest") {
        userDetails.add(pw.Text("Address: $address"));
        userDetails.add(pw.Text("Email: $email"));
        userDetails.add(pw.Text("Contact: $contact"));
      }
      userDetails
          .add(pw.Text("Total Price: PHP ${totalPrice.toStringAsFixed(2)}"));
      userDetails
          .add(pw.Text("Total Weight: ${totalWeight.toStringAsFixed(2)} kg"));
      userDetails.add(pw.SizedBox(height: 10));

      var recyclablesSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userDoc.id)
          .collection('recyclables')
          .get();

      for (var recDoc in recyclablesSnapshot.docs) {
        var recData = recDoc.data();
        String type = recData['type'] ?? 'Unknown';
        double weight = recData['weight'] ?? 0.0;
        double price = recData['price'] ?? 0.0;
        double itemPrice = weight * price;

        userDetails.add(pw.Text(" - Type: $type"));
        userDetails.add(pw.Text(" - Weight: ${weight.toStringAsFixed(2)} kg"));
        userDetails
            .add(pw.Text(" - Price per kg: PHP ${price.toStringAsFixed(2)}"));
        userDetails
            .add(pw.Text(" - Item Price: PHP ${itemPrice.toStringAsFixed(2)}"));
        userDetails.add(pw.SizedBox(height: 5));
      }

      userDetails.add(pw.Divider());
    }

    return userDetails;
  }
}
