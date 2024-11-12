import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/addusermodal.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html; // Import for web-based download and display

class DriverBookingDetails extends StatefulWidget {
  @override
  _DriverBookingDetailsState createState() => _DriverBookingDetailsState();
}

class _DriverBookingDetailsState extends State<DriverBookingDetails> {
  Map<String, bool> isEditingWeight = {};
  Map<String, TextEditingController> weightControllers = {};
  Map<String, double> updatedWeights = {};
  List<Map<String, dynamic>> selectedProducts = [];
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String bookingId = args?['bookingId'] ?? 'Unknown';
    String status = (args?['status'] ?? 'unknown').trim().toLowerCase();
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
              const Text("Booking Details",
                  style: TextStyle(color: Colors.white)),
              Spacer(),
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
                      overallWeight, overallPrice, formattedDate);
                },
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
        body: StreamBuilder(
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

              // Initialize variables for accumulating prices and weights
              double totalCalculatedPrice = 0.0;
              double totalCalculatedWeight = 0.0;

              // Loop through each user and add up calculated/collected prices and weights
              for (var userDoc in users) {
                var userData = userDoc.data() as Map<String, dynamic>;
                String userStatus = userData['status'] ?? 'pending';

                if (userStatus == 'collected') {
                  totalCalculatedPrice +=
                      userData['final_calculated_total_price'] ?? 0.0;
                  totalCalculatedWeight +=
                      userData['final_total_weight'] ?? 0.0;
                } else {
                  totalCalculatedPrice +=
                      userData['calculated_total_price'] ?? 0.0;
                  totalCalculatedWeight += userData['total_weight'] ?? 0.0;
                }
              }

              // Calculate the difference
              double priceDifference = totalCalculatedPrice - overallPrice;
              double weightDifference = totalCalculatedWeight - overallWeight;

              return Center(
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
                        Row(
                          children: [
                            const Text('Booking Details',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (status ==
                                'collecting') // Show only if collecting
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddUserModal(bookingId: bookingId);
                                    },
                                  );
                                },
                                child: const Text(
                                  'Add Guest User',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Booking ID: $bookingId',
                            style: const TextStyle(fontSize: 15)),
                        Text('Status: $status',
                            style: const TextStyle(fontSize: 15)),
                        Text('Vehicle: $vehicle',
                            style: const TextStyle(fontSize: 15)),
                        Text('Vehicle ID: $vehicleId',
                            style: const TextStyle(fontSize: 15)),

                        // Display for Est. Total Price
                        Row(
                          children: [
                            Text(
                              'Est. Total Price: ₱${overallPrice.toStringAsFixed(2)} ',
                              style: const TextStyle(fontSize: 15),
                            ),
                            Text(
                              '${priceDifference >= 0 ? '+' : ''}${priceDifference.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                color: priceDifference >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        // Display for Actual Calculated Price
                        Text(
                          'Actual Calculated Price: ₱${totalCalculatedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15),
                        ),

                        // Display for Est. Total Weight
                        Row(
                          children: [
                            Text(
                              'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg ',
                              style: const TextStyle(fontSize: 15),
                            ),
                            Text(
                              '${weightDifference >= 0 ? '+' : ''}${weightDifference.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 15,
                                color: weightDifference >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        // Display for Actual Calculated Weight
                        Text(
                          'Actual Calculated Weight: ${totalCalculatedWeight.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 15),
                        ),

                        Text('Date: $formattedDate',
                            style: const TextStyle(fontSize: 15)),
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
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              var users = userSnapshot.data?.docs ?? [];
                              if (users.isEmpty) {
                                return const Center(
                                    child: Text('No users found.'));
                              }

                              // Sorting logic for users
                              var nonCollectedUsers = users.where((userDoc) {
                                var userData =
                                    userDoc.data() as Map<String, dynamic>;
                                return userData['status'] == null ||
                                    (userData['status'] != 'collected' &&
                                        userData['status'] != 'failed');
                              }).toList();

                              var collectedUsers = users.where((userDoc) {
                                var userData =
                                    userDoc.data() as Map<String, dynamic>;
                                return userData['status'] == 'collected';
                              }).toList();

                              var failedUsers = users.where((userDoc) {
                                var userData =
                                    userDoc.data() as Map<String, dynamic>;
                                return userData['status'] == 'failed';
                              }).toList();

// Sort collected users by collected timestamp
                              collectedUsers.sort((a, b) {
                                var aTimestamp =
                                    (a.data() as Map<String, dynamic>)[
                                        'collected_timestamp'] as Timestamp?;
                                var bTimestamp =
                                    (b.data() as Map<String, dynamic>)[
                                        'collected_timestamp'] as Timestamp?;
                                return aTimestamp?.compareTo(
                                        bTimestamp ?? Timestamp.now()) ??
                                    0;
                              });

// Concatenate the lists: non-collected, collected, and then failed users
                              var sortedUsers = nonCollectedUsers +
                                  collectedUsers +
                                  failedUsers;

                              return ListView.builder(
                                itemCount: sortedUsers.length,
                                itemBuilder: (context, userIndex) {
                                  var userData = sortedUsers[userIndex].data()
                                      as Map<String, dynamic>;
                                  String firstName =
                                      userData['firstName'] ?? 'Unknown';
                                  String lastName =
                                      userData['lastName'] ?? 'Unknown';
                                  String address =
                                      userData['address'] ?? 'Unknown';
                                  String contact =
                                      userData['contact'] ?? 'Unknown';
                                  String email = userData['email'] ?? 'Unknown';

                                  // If user is collected, use final_total_price and final_total_weight
                                  double totalPrice =
                                      userData['status'] == 'collected'
                                          ? userData['final_total_price'] ?? 0.0
                                          : userData['total_price'] ?? 0.0;
                                  double totalWeight = userData['status'] ==
                                          'collected'
                                      ? userData['final_total_weight'] ?? 0.0
                                      : userData['total_weight'] ?? 0.0;
                                  // Retrieve calculated_total_price or final_calculated_total_price from userData
                                  double calculatedTotalPrice = userData[
                                              'status'] ==
                                          'collected'
                                      ? userData[
                                              'final_calculated_total_price'] ??
                                          0.0
                                      : userData['calculated_total_price'] ??
                                          0.0;

                                  String userId = sortedUsers[userIndex].id;
                                  String userStatus =
                                      userData['status']?.isEmpty ?? true
                                          ? 'pending'
                                          : userData['status'];
                                  bool isCollected = userStatus == 'collected';
                                  Timestamp? collectedTimestamp =
                                      userData['collected_timestamp'];
                                  String collectedDate = collectedTimestamp !=
                                          null
                                      ? DateFormat('MM/dd/yyyy, HH:mm')
                                          .format(collectedTimestamp.toDate())
                                      : 'N/A';

                                  return Card(
                                    margin: const EdgeInsets.all(10),
                                    color: isCollected
                                        ? Colors.lightGreen[100]
                                        : (userStatus == 'failed'
                                            ? Colors.red[100]
                                            : null), // Red for failed status
                                    child: ExpansionTile(
                                      title: Text('$firstName $lastName',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        '${firstName == "Guest" ? "" : "Address: $address\n"}'
                                        '${firstName == "Guest" ? "" : "Contact: $contact\n"}'
                                        '${firstName == "Guest" ? "" : "Email: $email\n"}'
                                        'Total Price: ₱${totalPrice.toStringAsFixed(2)}\n'
                                        'Calculated Total Price: ₱${calculatedTotalPrice.toStringAsFixed(2)}\n'
                                        'Total Weight: ${totalWeight.toStringAsFixed(2)} kg\n'
                                        'Driver Share: ₱${((((((totalPrice ?? 0.0) / (1 - 0.30)) + 40) - (totalPrice ?? 0.0)) * 0.30).toStringAsFixed(2))}\n'
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
                                          builder:
                                              (context, recyclableSnapshot) {
                                            if (!recyclableSnapshot.hasData) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }

                                            var recyclables =
                                                recyclableSnapshot.data?.docs ??
                                                    [];

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
                                                    recyclableData['type'] ??
                                                        'Unknown';
                                                double weight = isCollected
                                                    ? recyclableData[
                                                            'final_weight'] ??
                                                        recyclableData['weight']
                                                    : recyclableData['weight'];
                                                double price =
                                                    recyclableData['price'] ??
                                                        0.0;
                                                double itemPrice = isCollected
                                                    ? recyclableData[
                                                            'final_item_price'] ??
                                                        weight * price
                                                    : weight * price;
                                                String recyclableId =
                                                    recyclables[recIndex].id;

                                                if (!weightControllers
                                                    .containsKey(
                                                        recyclableId)) {
                                                  weightControllers[
                                                          recyclableId] =
                                                      TextEditingController(
                                                          text: weight
                                                              .toString());
                                                  updatedWeights[recyclableId] =
                                                      weight;
                                                }

                                                bool isEditing =
                                                    isEditingWeight[
                                                            recyclableId] ??
                                                        false;

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text('Type: $type'),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: (status ==
                                                                        'collecting' &&
                                                                    !isCollected &&
                                                                    isEditing)
                                                                ? TextFormField(
                                                                    controller:
                                                                        weightControllers[
                                                                            recyclableId],
                                                                    decoration:
                                                                        const InputDecoration(
                                                                      isDense:
                                                                          true, // Reduces vertical padding inside TextFormField
                                                                      labelText:
                                                                          'Weight (kg)',
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                    ),
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .number,
                                                                  )
                                                                : Text(
                                                                    'Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg',
                                                                  ),
                                                          ),
                                                          if (!isCollected &&
                                                              status ==
                                                                  'collecting' &&
                                                              userStatus !=
                                                                  'failed') ...[
                                                            IconButton(
                                                              icon: Icon(
                                                                  isEditing
                                                                      ? Icons
                                                                          .check
                                                                      : Icons
                                                                          .edit),
                                                              onPressed: () {
                                                                setState(() {
                                                                  if (isEditing) {
                                                                    double
                                                                        newWeight =
                                                                        double.tryParse(
                                                                              weightControllers[recyclableId]!.text,
                                                                            ) ??
                                                                            weight;
                                                                    updatedWeights[
                                                                            recyclableId] =
                                                                        newWeight;
                                                                    itemPrice =
                                                                        newWeight *
                                                                            price;
                                                                  }
                                                                  isEditingWeight[
                                                                          recyclableId] =
                                                                      !isEditing;
                                                                });
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red),
                                                              onPressed:
                                                                  () async {
                                                                bool
                                                                    confirmDelete =
                                                                    await showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                          'Delete Product'),
                                                                      content: Text(
                                                                          'Are you sure you want to delete this product?'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context).pop(false);
                                                                          },
                                                                          child:
                                                                              Text('Cancel'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context).pop(true);
                                                                          },
                                                                          child:
                                                                              Text('Delete'),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );

                                                                if (confirmDelete ==
                                                                    true) {
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          'bookings')
                                                                      .doc(
                                                                          bookingId)
                                                                      .collection(
                                                                          'users')
                                                                      .doc(
                                                                          userId)
                                                                      .collection(
                                                                          'recyclables')
                                                                      .doc(
                                                                          recyclableId)
                                                                      .delete();

                                                                  setState(() {
                                                                    recyclables
                                                                        .removeAt(
                                                                            recIndex);
                                                                  });

                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                          'Product deleted successfully.'),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      if (isCollected)
                                                        Text(
                                                          'Final Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg',
                                                        ),
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
                                        if (!isCollected &&
                                            status == 'collecting' &&
                                            userStatus !=
                                                'failed') // Allow adding products only if collecting
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  _showAddProductModal(userId,
                                                      bookingId); // Function to open modal for adding a product
                                                },
                                                child: const Text(
                                                  'Add Product',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue),
                                              ),
                                            ],
                                          ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        if (!isCollected &&
                                            status == 'collecting' &&
                                            userStatus !=
                                                'failed') // Allow actions only if status is collecting
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  _showCollectedConfirmation(
                                                      userId,
                                                      bookingId,
                                                      firstName,
                                                      lastName,
                                                      userData);
                                                },
                                                child: const Text(
                                                  'Collected',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green),
                                              ),
                                              SizedBox(
                                                  width:
                                                      10), // Space between buttons
                                              ElevatedButton(
                                                onPressed: () async {
                                                  _showNotCollectedConfirmation(
                                                      userId,
                                                      bookingId,
                                                      firstName,
                                                      lastName,
                                                      userData);
                                                },
                                                child: const Text(
                                                  'Not Collected',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        if (status ==
                            'collecting') // Show "Mark Booking as Collected" only if status is collecting
                          ElevatedButton(
                            onPressed: () async {
                              await _showFinalCollectedConfirmation(bookingId);
                            },
                            child: const Text(
                              'Mark Booking as Collected',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }));
  }

  Future<void> _showNotCollectedConfirmation(
    String userId,
    String bookingId,
    String firstName,
    String lastName,
    Map<String, dynamic> userData,
  ) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Not Collected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you sure you want to mark $firstName $lastName as not collected?'),
              const Text(
                  'This will mark the collection as failed and set all totals to zero.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _markAsNotCollected(bookingId, userId);
    }
  }

  Future<void> _markAsNotCollected(String bookingId, String userId) async {
    try {
      // Step 1: Get the user's document reference in the 'users' collection
      var userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Step 2: Prepare the 'reports' subcollection and create a new report entry
      var reportRef = userDocRef.collection('reports').doc();
      var bookingDocRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      var userBookingDocPath =
          'bookings/$bookingId/users/$userId'; // Full path as a string
      var timestamp = FieldValue.serverTimestamp();

      // Step 3: Add a new report document with datetimestamp, status, bookingReference, and userDocumentPath
      await reportRef.set({
        'datetimestamp': timestamp,
        'status': 'failed',
        'bookingReference': bookingDocRef,
        'userDocumentPath': userBookingDocPath,
      });

      // Step 4: Fetch recyclables from the booking document
      var recyclablesSnapshot = await bookingDocRef
          .collection('users')
          .doc(userId)
          .collection('recyclables')
          .get();

      var batch = FirebaseFirestore.instance.batch();

      // Step 5: Copy each recyclable item into the 'recyclables' subcollection in the report
      for (var rec in recyclablesSnapshot.docs) {
        var recyclableData = rec.data();

        // Add the full recyclable data to the report's 'recyclables' subcollection
        await reportRef.collection('recyclables').add({
          'category': recyclableData['category'] ?? 'Unknown',
          'final_item_price': 0.0, // Reset final values as requested
          'final_weight': 0.0,
          'item_price': recyclableData['item_price'] ?? 0.0,
          'original_price': recyclableData['original_price'] ?? 0.0,
          'price': recyclableData['price'] ?? 0.0,
          'product_Id': recyclableData['product_Id'] ?? '',
          'timestamp': recyclableData['timestamp'],
          'type': recyclableData['type'] ?? 'Unknown',
          'weight': recyclableData['weight'] ?? 0.0,
        });

        // Update the original recyclable item in the booking to set final_weight and final_item_price to 0
        batch.update(
          rec.reference,
          {
            'final_weight': 0.0,
            'final_item_price': 0.0,
          },
        );
      }

      // Step 6: Update the user's document in the booking with failed status
      var userBookingRef = bookingDocRef.collection('users').doc(userId);
      batch.update(userBookingRef, {
        'status': 'failed',
      });

      // Commit the batch update
      await batch.commit();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'User marked as not collected. Report added, recyclables copied, and status updated to failed.'),
        ),
      );
    } catch (e) {
      print('Error in _markAsNotCollected: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Failed to mark user as not collected. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showCollectedConfirmation(String userId, String bookingId,
      String firstName, String lastName, Map<String, dynamic> userData) async {
    // Show modal to confirm collection
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you sure you want to mark $firstName $lastName as collected?'),
              const Text(
                  'Recyclables and their updated weights/prices will be finalized.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _markAsCollected(bookingId, userId);
    }
  }

  Future<void> _markAsCollected(String bookingId, String userId) async {
    var recyclablesSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .get();

    double finalTotalPrice = 0.0;
    double finalTotalWeight = 0.0;

    var batch = FirebaseFirestore.instance.batch();

    for (var rec in recyclablesSnapshot.docs) {
      var recyclableData = rec.data() as Map<String, dynamic>;
      String recyclableId = rec.id;

      // Calculate final weight and final item price
      double finalWeight =
          updatedWeights[recyclableId] ?? recyclableData['weight'];
      double price = recyclableData['price'] ?? 0.0;
      double finalItemPrice = finalWeight * price;

      // Sum up the final item prices and final weights
      finalTotalPrice += finalItemPrice;
      finalTotalWeight += finalWeight;

      // Update each recyclable with final weight and final item price
      batch.update(
        rec.reference,
        {
          'final_weight': finalWeight,
          'final_item_price': finalItemPrice,
        },
      );
    }

    // Calculate the final_calculated_total_price as final_total_price - 40
    double finalCalculatedTotalPrice = finalTotalPrice - 40;

    // Now update the user's document with final_total_price, final_total_weight, collected status, and final_calculated_total_price
    var userRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId);

    batch.update(userRef, {
      'status': 'collected',
      'final_total_price': finalTotalPrice, // Store the final total price
      'final_total_weight': finalTotalWeight, // Store the final total weight
      'final_calculated_total_price':
          finalCalculatedTotalPrice, // Store the final calculated total price
      'collected_timestamp':
          Timestamp.now(), // Add collected timestamp for the user
    });

    // Update the status of each user in the users collection to "collected"
    await _updateUsersStatusToCollected(bookingId);

    // Add new document to the `outflow` collection
    var bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();
    var bookingData = bookingDoc.data() as Map<String, dynamic>;

    String vehicle = bookingData['vehicle'] ?? 'Unknown Vehicle';
    String vehicleId = bookingData['vehicleId'] ?? 'Unknown Vehicle ID';
    String employee = bookingData['driver'] ?? 'Unknown Driver';
    String employeeId = bookingData['driverId'] ?? 'Unknown Driver ID';

    await FirebaseFirestore.instance.collection('outflow').add({
      'date': Timestamp.now(),
      'price': finalCalculatedTotalPrice,
      'weight': finalTotalWeight,
      'vehicle': vehicle,
      'vehicleId': vehicleId,
      'employee': employee,
      'employeeId': employeeId,
      'bookingId': bookingId,
      'status': 'collected',
      'category': 'booking',
    });

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'User marked as collected, total price and weight calculated, and outflow recorded')),
    );
  }

  Future<void> _showFinalCollectedConfirmation(String bookingId) async {
    bool hasUncollectedUsers = false;
    bool allUsersProcessed = true;

    // Fetch all users within the booking
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    // Check if each user is either collected or failed
    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      String userStatus = userData['status'] ?? 'pending';

      if (userStatus == 'pending') {
        hasUncollectedUsers = true;
        allUsersProcessed = false;
        break;
      } else if (userStatus != 'collected' && userStatus != 'failed') {
        allUsersProcessed = false;
      }
    }

    if (hasUncollectedUsers || !allUsersProcessed) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Incomplete Collection'),
            content: const Text(
                'Some users have not been marked as collected or failed. Please finish collecting or failing all users before marking the booking as collected.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    } else {
      // Show confirmation dialog to mark the booking as collected
      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Mark Booking as Completed'),
            content: const Text(
                'Are you sure you want to mark the entire booking as completed?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed) {
        await _finalizeBookingCollection(bookingId, usersSnapshot);
      }
    }
  }

  Future<void> _finalizeBookingCollection(
      String bookingId, QuerySnapshot usersSnapshot) async {
    // Calculate the total final overall price, final overall weight, and total driver share
    double finalOverallPrice = 0.0;
    double finalOverallWeight = 0.0;
    double totalDriverShare = 0.0;

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      double finalTotalPrice = userData['final_total_price'] ?? 0.0;
      double finalTotalWeight = userData['final_total_weight'] ?? 0.0;

      // Calculate the driver share for each user
      double driverShare =
          ((((finalTotalPrice / (1 - 0.30)) + 40) - finalTotalPrice) * 0.30);

      // Accumulate the totals
      finalOverallPrice += finalTotalPrice;
      finalOverallWeight += finalTotalWeight;
      totalDriverShare += driverShare;
    }

    // Update the booking document with the final overall price, weight, and driver share
    var bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    await bookingRef.update({
      'status': 'collected',
      'final_overall_price': finalOverallPrice,
      'final_overall_weight': finalOverallWeight,
      'driver_share':
          totalDriverShare.toStringAsFixed(2), // Add the total driver share
    });

    // Fetch booking data for outflow entry
    var bookingDoc = await bookingRef.get();
    var bookingData = bookingDoc.data() as Map<String, dynamic>;

    String vehicle = bookingData['vehicle'] ?? 'Unknown Vehicle';
    String vehicleId = bookingData['vehicleId'] ?? 'Unknown Vehicle ID';
    String employee = bookingData['driver'] ?? 'Unknown Driver';
    String employeeId = bookingData['driverId'] ?? 'Unknown Driver ID';

    // Add a new document to the outflow collection for the driver share
    await FirebaseFirestore.instance.collection('outflow').add({
      'date': Timestamp.now(),
      'price': double.parse(totalDriverShare.toStringAsFixed(2)),
      'vehicle': vehicle,
      'vehicleId': vehicleId,
      'employee': employee,
      'employeeId': employeeId,
      'bookingId': bookingId,
      'status': 'collected',
      'category': 'driver share',
    });

    // Add the outflow entry for total
    // var bookingDoc = await FirebaseFirestore.instance
    //     .collection('bookings')
    //     .doc(bookingId)
    //     .get();
    // var bookingData = bookingDoc.data() as Map<String, dynamic>;

    // String vehicle = bookingData['vehicle'] ?? 'Unknown';
    // String vehicleId = bookingData['vehicleId'] ?? 'Unknown';
    // String employee = bookingData['driver'] ?? 'Unknown';
    // String employeeId = bookingData['driverId'] ?? 'Unknown';

    // await FirebaseFirestore.instance.collection('outflow').add({
    //   'date': Timestamp.now(),
    //   'price': finalOverallPrice,
    //   'weight': finalOverallWeight,
    //   'vehicle': vehicle,
    //   'vehicleId': vehicleId,
    //   'employee': employee,
    //   'employeeId': employeeId,
    //   'bookingId': bookingId,
    //   'status': 'collected',
    //   'category': 'booking',
    // });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'Booking marked as collected. Final overall price, weight, and driver share updated.',
        ),
      ),
    );

    // Pop the current screen after the operation is complete
    Navigator.of(context).pop();
  }

// Function to update the status of users in the users collection to "collected"
  Future<void> _updateUsersStatusToCollected(String bookingId) async {
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    var batch = FirebaseFirestore.instance.batch();

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;

      if (userData['status'] != null) {
        // Update the user's status to "collected"
        var userRef =
            FirebaseFirestore.instance.collection('users').doc(userDoc.id);
        batch.update(userRef, {'status': 'done'});
      }
    }

    // Commit the batch update
    await batch.commit();
  }

  void _showAddProductModal(String userId, String bookingId) async {
    final TextEditingController weightController = TextEditingController();
    String selectedProductName = 'Unknown';
    double? recentPrice;
    double? originalPrice;
    double? percentageProfit;
    String? productId;
    String? category;

    // Fetch existing product names in user's recyclables
    List<String> existingProductNames =
        await _fetchUserRecyclableProductNames(userId, bookingId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown to select product name
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      var products = snapshot.data!.docs.where((doc) {
                        String productName =
                            doc['product_name'].toString().toLowerCase();
                        return !existingProductNames.contains(productName);
                      }).toList();

                      if (products.isEmpty) {
                        return const Text("No new products available to add.");
                      }

                      // Select the first available product by default
                      if (selectedProductName == 'Unknown' &&
                          products.isNotEmpty) {
                        selectedProductName = products.first['product_name'];
                        productId = products.first.id;
                        category = products.first['category'];
                      }

                      return DropdownButton<String>(
                        value: selectedProductName,
                        onChanged: (value) {
                          setState(() {
                            selectedProductName = value!;

                            // Find the selected product's details
                            var selectedProduct = products.firstWhere((doc) =>
                                doc['product_name'] == selectedProductName);

                            productId = selectedProduct.id;
                            category = selectedProduct['category'];

                            // Fetch latest price and original price
                            _fetchLatestPrice(productId!).then((data) {
                              setState(() {
                                recentPrice = data['price'];
                                originalPrice = data['original_price'];
                                percentageProfit = data['percentage_profit'];
                              });
                            });
                          });
                        },
                        items: products.map<DropdownMenuItem<String>>((doc) {
                          return DropdownMenuItem<String>(
                            value: doc['product_name'],
                            child: Text(doc['product_name']),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Display the most recent price
                  recentPrice != null
                      ? Text(
                          'Recent Price: ₱${recentPrice!.toStringAsFixed(2)} per kg')
                      : const Text("No product chosen"),
                  const SizedBox(height: 10),
                  // Input for weight
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double weight =
                        double.tryParse(weightController.text) ?? 0.0;
                    if (recentPrice != null && weight > 0) {
                      await _addProductToUser(
                        userId,
                        bookingId,
                        selectedProductName.toUpperCase(),
                        weight,
                        recentPrice!,
                        productId!,
                        category!,
                        originalPrice!,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Add the product to user's recyclables with the additional fields
  Future<void> _addProductToUser(
    String userId,
    String bookingId,
    String productName,
    double weight,
    double price,
    String productId,
    String category,
    double originalPrice,
  ) async {
    double itemPrice = weight * price;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .add({
      'type': productName, // Store as uppercase
      'weight': weight,
      'price': price,
      'original_price': originalPrice, // New field for original price
      'item_price': itemPrice, // Changed from item_total to item_price
      'productId': productId, // New field for product ID
      'category': category, // New field for category
      'timestamp': Timestamp.now(), // Changed from added_timestamp to timestamp
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully.')),
    );
  }

// Helper function to fetch existing product names in user's recyclables
  Future<List<String>> _fetchUserRecyclableProductNames(
      String userId, String bookingId) async {
    var recyclablesSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .get();

    // Convert all product names to lowercase to ensure case-insensitive comparison
    return recyclablesSnapshot.docs.map((doc) {
      return (doc['type'] as String).toLowerCase();
    }).toList();
  }

  // Function to fetch the latest price and original price for a product based on product ID
  Future<Map<String, double>> _fetchLatestPrice(String productId) async {
    try {
      // Fetch the latest price from the 'prices' subcollection
      var priceSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('prices')
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      if (priceSnapshot.docs.isNotEmpty) {
        var priceData = priceSnapshot.docs.first;
        return {
          'price': priceData['price']?.toDouble() ?? 0.0,
          'original_price': priceData['original_price']?.toDouble() ?? 0.0,
          'percentage_profit':
              priceData['percentage_profit']?.toDouble() ?? 0.0,
        };
      }
    } catch (e) {
      print('Error fetching latest price: $e');
    }
    return {
      'price': 0.0,
      'original_price': 0.0,
      'percentage_profit': 0.0,
    }; // Default values if no data is found
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

    // Fetch users data to calculate total calculated price and weight
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    double totalCalculatedPrice = 0.0;
    double totalCalculatedWeight = 0.0;

    // Loop through each user and add up calculated/collected prices and weights
    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      String userStatus = userData['status'] ?? 'pending';

      if (userStatus == 'collected') {
        totalCalculatedPrice += userData['final_calculated_total_price'] ?? 0.0;
        totalCalculatedWeight += userData['final_total_weight'] ?? 0.0;
      } else {
        totalCalculatedPrice += userData['calculated_total_price'] ?? 0.0;
        totalCalculatedWeight += userData['total_weight'] ?? 0.0;
      }
    }

    // Calculate the differences
    double priceDifference = totalCalculatedPrice - overallPrice;
    double weightDifference = totalCalculatedWeight - overallWeight;

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
          pw.Text("Status: ${status[0].toUpperCase() + status.substring(1)}"),
          pw.Text("Vehicle: $vehicle"),
          pw.Text("Vehicle ID: $vehicleId"),

          // Display for Est. Total Price
          pw.Row(
            children: [
              pw.Text(
                'Est. Total Price: Php${overallPrice.toStringAsFixed(2)} ',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.Text(
                '${priceDifference >= 0 ? '+' : ''}${priceDifference.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: priceDifference >= 0 ? PdfColors.green : PdfColors.red,
                ),
              ),
            ],
          ),

          // Display for Actual Calculated Price
          pw.Text(
            'Actual Calculated Price: Php${totalCalculatedPrice.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 18),
          ),

          // Display for Est. Total Weight
          pw.Row(
            children: [
              pw.Text(
                'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg ',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.Text(
                '${weightDifference >= 0 ? '+' : ''}${weightDifference.toStringAsFixed(2)} kg',
                style: pw.TextStyle(
                  fontSize: 18,
                  color:
                      weightDifference >= 0 ? PdfColors.green : PdfColors.red,
                ),
              ),
            ],
          ),

          // Display for Actual Calculated Weight
          pw.Text(
            'Actual Calculated Weight: ${totalCalculatedWeight.toStringAsFixed(2)} kg',
            style: pw.TextStyle(fontSize: 18),
          ),

          pw.Text("Date: $formattedDate"),
          pw.SizedBox(height: 20),
          pw.Text(
            "Users",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
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

// Modify _generateUserDetails to include all details shown in the app
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
      double totalPrice = userData['status'] == 'collected'
          ? userData['final_total_price'] ?? 0.0
          : userData['total_price'] ?? 0.0;
      double totalWeight = userData['status'] == 'collected'
          ? userData['final_total_weight'] ?? 0.0
          : userData['total_weight'] ?? 0.0;
      double calculatedTotalPrice = userData['status'] == 'collected'
          ? userData['final_calculated_total_price'] ?? 0.0
          : userData['calculated_total_price'] ?? 0.0;

      Timestamp? collectedTimestamp = userData['collected_timestamp'];
      String collectedDate = collectedTimestamp != null
          ? DateFormat('MM/dd/yyyy, HH:mm').format(collectedTimestamp.toDate())
          : 'N/A';

      String userStatus = userData['status'] ?? 'pending';
      bool isCollected = userStatus == 'collected';

      userDetails.add(pw.Text(
        "$firstName $lastName",
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
      ));

      if (firstName != "Guest") {
        userDetails.add(pw.Text("Address: $address"));
        userDetails.add(pw.Text("Email: $email"));
        userDetails.add(pw.Text("Contact: $contact"));
      }

      userDetails
          .add(pw.Text("Total Price: PHP ${totalPrice.toStringAsFixed(2)}"));
      userDetails.add(pw.Text(
          "Calculated Total Price: PHP ${calculatedTotalPrice.toStringAsFixed(2)}"));
      userDetails
          .add(pw.Text("Total Weight: ${totalWeight.toStringAsFixed(2)} kg"));
      if (isCollected) {
        userDetails.add(pw.Text("Collected: $collectedDate"));
      }

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
        double weight = isCollected
            ? recData['final_weight'] ?? recData['weight']
            : recData['weight'];
        double price = recData['price'] ?? 0.0;
        double itemPrice = isCollected
            ? recData['final_item_price'] ?? weight * price
            : weight * price;

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
