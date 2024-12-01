import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/screens/addusermodal.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

import 'package:trashure_thesis/user_model.dart'; // Import for web-based download and display

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
    final String userRole =
        Provider.of<UserModel>(context, listen: false).userRole;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String bookingId = args?['bookingId'] ?? 'Unknown';
    String location = args?['location'] ?? 'Unknown';
    String status = (args?['status'] ?? 'unknown').trim().toLowerCase();
    String vehicle = args?['vehicle'] ?? 'Unknown';
    String vehicleId = args?['vehicleId'] ?? 'Unknown';
    double overallPrice = args?['overall_price']?.toDouble() ?? 0.0;
    double overallWeight = args?['overall_weight']?.toDouble() ?? 0.0;

    Timestamp? timestamp = args?['date'];
    DateTime? date = timestamp?.toDate();
    // Extract start and end time from arguments
    String startTime = args?['start_time'] ?? 'Unknown Start Time';
    String endTime = args?['end_time'] ?? 'Unknown End Time';

// Combine the date with the start and end times
    String formattedDate = date != null
        ? DateFormat('MM/dd/yyyy, EEEE').format(date) +
            ' ($startTime - $endTime)'
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
                      overallWeight, overallPrice, formattedDate, userRole);
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
                        Text('Location: $location',
                            style: const TextStyle(fontSize: 15)),
                        Text('Status: $status',
                            style: const TextStyle(fontSize: 15)),
                        Text('Vehicle: $vehicle',
                            style: const TextStyle(fontSize: 15)),
                        Text('Vehicle ID: $vehicleId',
                            style: const TextStyle(fontSize: 15)),

                        // Display for Est. Total Price
                        // Row(
                        //   children: [
                        //     Text(
                        //       'Est. Total Price: ₱${overallPrice.toStringAsFixed(2)} ',
                        //       style: const TextStyle(fontSize: 15),
                        //     ),
                        //     Text(
                        //       '${priceDifference >= 0 ? '+' : ''}${priceDifference.toStringAsFixed(2)}',
                        //       style: TextStyle(
                        //         fontSize: 15,
                        //         color: priceDifference >= 0
                        //             ? Colors.green
                        //             : Colors.red,
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        // Display for Actual Calculated Price
                        Text(
                          'Actual Calculated Price: ₱${totalCalculatedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15),
                        ),

                        // Display for Est. Total Weight
                        // Row(
                        //   children: [
                        //     Text(
                        //       'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg ',
                        //       style: const TextStyle(fontSize: 15),
                        //     ),
                        //     Text(
                        //       '${weightDifference >= 0 ? '+' : ''}${weightDifference.toStringAsFixed(2)} kg',
                        //       style: TextStyle(
                        //         fontSize: 15,
                        //         color: weightDifference >= 0
                        //             ? Colors.green
                        //             : Colors.red,
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        // Display for Actual Calculated Weight
                        Text(
                          'Actual Calculated Weight: ${totalCalculatedWeight.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 15),
                        ),

                        Text('Date: $formattedDate',
                            style: const TextStyle(fontSize: 15)),

                        // Add StreamBuilder for user count
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .collection('users')
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const Text(
                                "Loading user count...",
                                style:
                                    TextStyle(fontSize: 15, color: Colors.grey),
                              );
                            }
                            // Count the number of users in the snapshot
                            int userCount = userSnapshot.data?.docs.length ?? 0;
                            return Text(
                              "Number of Users: $userCount",
                              style: const TextStyle(fontSize: 15),
                            );
                          },
                        ),
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

                                  // Determine the share percentage based on userRole
                                  double sharePercentage =
                                      userRole == 'contractual driver'
                                          ? 0.35
                                          : 0.30;

// Check if the user is in donate mode
                                  double effectiveTotalPrice =
                                      userData['mode'] == 'donate'
                                          ? userData['total_price'] ?? 0.0
                                          : (userData['status'] == 'collected'
                                              ? userData['final_total_price'] ??
                                                  0.0
                                              : userData['total_price'] ?? 0.0);

                                  print(
                                      'User Role: $userRole'); // Add this to check the fetched userRole

// Calculate the driver share
                                  double driverShare = 0.0;

                                  if (userStatus != 'failed') {
                                    if (firstName == "Guest" ||
                                        userData['category'] == 'business') {
                                      // Guest or Business users: No subtraction of 40
                                      driverShare =
                                          (((effectiveTotalPrice / (1 - 0.30)) -
                                                  effectiveTotalPrice) *
                                              sharePercentage);
                                    } else {
                                      // Non-guest and non-business users: Include subtraction of 40
                                      driverShare = ((((effectiveTotalPrice /
                                                  (1 - 0.30)) +
                                              40 -
                                              effectiveTotalPrice) *
                                          sharePercentage));
                                    }
                                  }

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
                                        'Driver Share: ₱${driverShare.toStringAsFixed(2)}\n'
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
                                                                  isEditingWeight[
                                                                              recyclableId] ==
                                                                          true
                                                                      ? Icons
                                                                          .check
                                                                      : Icons
                                                                          .edit),
                                                              onPressed:
                                                                  isEditingWeight[
                                                                              recyclableId] ==
                                                                          true
                                                                      ? () async {
                                                                          // Save changes to Firebase
                                                                          double
                                                                              newWeight =
                                                                              double.tryParse(weightControllers[recyclableId]?.text ?? '0') ?? weight;
                                                                          try {
                                                                            await FirebaseFirestore.instance.collection('bookings').doc(bookingId).collection('users').doc(userId).collection('recyclables').doc(recyclableId).update({
                                                                              'final_weight': newWeight,
                                                                              'final_item_price': newWeight * (recyclableData['price'] ?? 0.0),
                                                                            });

                                                                            setState(() {
                                                                              updatedWeights[recyclableId] = newWeight;
                                                                              isEditingWeight[recyclableId] = false;
                                                                            });

                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              const SnackBar(
                                                                                content: Text('Weight updated successfully.'),
                                                                              ),
                                                                            );
                                                                          } catch (e) {
                                                                            print('Error updating weight: $e');
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              const SnackBar(
                                                                                content: Text('Failed to update weight. Please try again.'),
                                                                              ),
                                                                            );
                                                                          }
                                                                        }
                                                                      : () {
                                                                          // Enter editing mode
                                                                          setState(
                                                                              () {
                                                                            isEditingWeight[recyclableId] =
                                                                                true;
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

                                                                if (confirmDelete) {
                                                                  await _deleteProduct(
                                                                    bookingId:
                                                                        bookingId,
                                                                    userId:
                                                                        userId,
                                                                    recyclableId:
                                                                        recyclableId,
                                                                    itemPrice:
                                                                        itemPrice,
                                                                    weight:
                                                                        weight,
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      // if (isCollected)
                                                      //   Text(
                                                      //     'Final Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg',
                                                      //   ),
                                                      Text(
                                                          'Price: ₱${price.toStringAsFixed(2)}'),
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
                              'Mark All Bookings as Collected',
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

  Future<void> _deleteProduct({
    required String bookingId,
    required String userId,
    required String recyclableId,
    required double itemPrice, // Original price passed to the method
    required double weight,
  }) async {
    try {
      var userRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId);

      var recyclableRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .collection('recyclables')
          .doc(recyclableId);

      var userDoc = await userRef.get();
      var recyclableDoc = await recyclableRef.get();

      if (userDoc.exists && recyclableDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        var recyclableData = recyclableDoc.data() as Map<String, dynamic>;

        String mode = userData['mode'] ?? 'regular';
        String productId = recyclableData['productId'] ?? '';

        print('Deleting product with mode: $mode, productId: $productId');

        double updatedTotalPrice = userData['total_price'] ?? 0.0;
        double updatedTotalWeight = (userData['total_weight'] ?? 0.0) - weight;

        // Recalculate itemPrice
        double recalculatedItemPrice;
        if (mode == 'donate') {
          print(
              'Fetching latest price for productId: $productId in donate mode');
          var latestPriceData = await _fetchLatestPrice(productId);
          double latestPrice = latestPriceData['price'] ?? 0.0;
          recalculatedItemPrice = weight * latestPrice;
          print(
              'Recalculated itemPrice for donate mode: $recalculatedItemPrice');
        } else {
          recalculatedItemPrice = weight * itemPrice;
          print(
              'Calculated itemPrice for regular mode: $recalculatedItemPrice');
        }

        // Deduct recalculated item price from total price
        updatedTotalPrice -= recalculatedItemPrice;
        if (updatedTotalPrice < 0) updatedTotalPrice = 0;

        if (updatedTotalWeight < 0) updatedTotalWeight = 0;

        print(
            'Updated total_price: $updatedTotalPrice, total_weight: $updatedTotalWeight');

        var batch = FirebaseFirestore.instance.batch();

        // Delete the recyclable document
        batch.delete(recyclableRef);

        // Update the user's totals
        batch.update(userRef, {
          'total_price': updatedTotalPrice,
          'total_weight': updatedTotalWeight,
        });

        await batch.commit();
        print('Batch update committed successfully.');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully.')),
        );
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete product. Please try again.')),
      );
    }
  }

  Future<void> _showNotCollectedConfirmation(
    String userId,
    String bookingId,
    String firstName,
    String lastName,
    Map<String, dynamic> userData,
  ) async {
    TextEditingController reasonController = TextEditingController();
    bool isReasonEmpty = false;

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Not Collected'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Are you sure you want to mark $firstName $lastName as not collected?'),
                  const SizedBox(height: 10),
                  const Text(
                      'This will mark the collection as failed and set all totals to zero.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason for not collecting',
                      border: const OutlineInputBorder(),
                      errorText:
                          isReasonEmpty ? 'This field is required' : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isReasonEmpty = value.isEmpty;
                      });
                    },
                  ),
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
                    setState(() {
                      isReasonEmpty = reasonController.text.isEmpty;
                    });

                    if (!isReasonEmpty) {
                      Navigator.of(context).pop(true); // Confirm
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _markAsNotCollected(bookingId, userId, reasonController.text);
    }
  }

  Future<void> _markAsNotCollected(
      String bookingId, String userId, String reason) async {
    try {
      // Step 1: Get the user's document reference in the 'users' collection
      var userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Step 2: Prepare the 'reports' subcollection and create a new report entry
      var reportRef = userDocRef.collection('reports').doc();
      var bookingDocRef =
          FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      var userBookingDocPath = 'bookings/$bookingId/users/$userId';
      var timestamp = FieldValue.serverTimestamp();

      // Step 3: Add a new report document with datetimestamp, status, reason, bookingReference, and userDocumentPath
      await reportRef.set({
        'datetimestamp': timestamp,
        'status': 'failed',
        'reason': reason, // Include the reason in the report
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

      // Step 6: Update the user's document in the booking with failed status and the reason
      var userBookingRef = bookingDocRef.collection('users').doc(userId);
      batch.update(userBookingRef, {
        'status': 'failed',
        'reason': reason, // Save the reason in the user's booking document
        'final_calculated_total_price': 0.0,
        'calculated_total_price': 0.0,
        'final_total_weight': 0.0,
        'total_price': 0.0,
        'final_total_price': 0.0,
        'total_weight': 0.0,
      });

      // Step 7: Update the user's status in the main 'users' collection to 'done'
      batch.update(userDocRef, {'status': 'done', 'review_status': 'reported'});

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
    try {
      // Fetch the recyclables for the user
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

      // Calculate totals and update recyclables
      for (var rec in recyclablesSnapshot.docs) {
        var recyclableData = rec.data() as Map<String, dynamic>;
        String recyclableId = rec.id;

        // Calculate final weight and item price
        double finalWeight =
            updatedWeights[recyclableId] ?? recyclableData['weight'];
        double price = recyclableData['price'] ?? 0.0;
        double finalItemPrice = finalWeight * price;

        // Accumulate total price and weight
        finalTotalPrice += finalItemPrice;
        finalTotalWeight += finalWeight;

        // Update each recyclable document with the final weight and item price
        batch.update(
          rec.reference,
          {
            'final_weight': finalWeight,
            'final_item_price': finalItemPrice,
          },
        );
      }

      // Fetch user data
      var userDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .get();
      var userData = userDoc.data() as Map<String, dynamic>;

      // Retrieve mode with a default value
      String mode =
          userData['mode'] ?? 'regular'; // Default to 'regular' if not set
      String firstName = userData['firstName'] ?? 'Unknown';
      String userStatus = userData['status'] ?? 'pending';
      String category = userData['category'] ?? 'unknown'; // Fetch category
      print(mode);
      print(category);

      // Check if the user is a guest
      bool isGuest = firstName == "Guest" || category == "business";

      double finalCalculatedTotalPrice;
      if (isGuest) {
        // For guests and business, set final_calculated_total_price to final_total_price
        finalCalculatedTotalPrice = finalTotalPrice;
      } else if (mode == 'donate') {
        // For donations, final_calculated_total_price is 0
        finalCalculatedTotalPrice = 0.0;
      } else {
        // For other cases, subtract 40 for services
        finalCalculatedTotalPrice = finalTotalPrice - 40;
      }

      // Update the user's document
      var userRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId);

      batch.update(userRef, {
        'status': 'collected',
        'final_total_price': finalTotalPrice,
        'final_total_weight': finalTotalWeight,
        'final_calculated_total_price': finalCalculatedTotalPrice,
        'collected_timestamp': Timestamp.now(),
      });

      // If the user is not a guest, update their status in the main `users` collection
      if (!isGuest) {
        var mainUserRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        batch.update(mainUserRef, {'status': 'done'});
      }

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

      // Create the outflow document
      DocumentReference outflowRef =
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
        'category': isGuest ? 'guest booking' : 'booking',
      });

      // Add recyclables as a subcollection under the outflow document
      for (var rec in recyclablesSnapshot.docs) {
        var recyclableData = rec.data() as Map<String, dynamic>;
        String recyclableId = rec.id;

        double finalWeight =
            updatedWeights[recyclableId] ?? recyclableData['weight'];
        double price = recyclableData['price'] ?? 0.0;
        double finalItemPrice = finalWeight * price;
        String type = recyclableData['type'] ?? 'Unknown Type';

        await outflowRef.collection('recyclables').add({
          'recyclableId': recyclableId,
          'type': type,
          'final_weight': finalWeight,
          'price': price,
          'final_item_price': finalItemPrice,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User marked as collected successfully, including guest users.',
          ),
        ),
      );
    } catch (e) {
      print("Error in markAsCollected: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark user as collected. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showFinalCollectedConfirmation(String bookingId) async {
    bool hasUncollectedUsers = false;
    bool allUsersProcessed = true;
    final String userRole =
        Provider.of<UserModel>(context, listen: false).userRole;

    // Text controllers for input fields
    TextEditingController endingMileageController = TextEditingController();
    TextEditingController fuelPaymentController = TextEditingController();

    // Validation flags
    bool isEndingMileageEmpty = false;
    bool isFuelPaymentEmpty = false;

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
      // Show confirmation dialog with additional required fields
      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Mark Booking as Completed'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Please fill in the required fields to proceed.'),
                    const SizedBox(height: 10),
                    // Input field for ending mileage
                    TextField(
                      controller: endingMileageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Ending Mileage',
                        border: const OutlineInputBorder(),
                        errorText: isEndingMileageEmpty
                            ? 'This field is required'
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          isEndingMileageEmpty = value.isEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Input field for fuel payment (only visible for driver role)
                    if (userRole.toLowerCase() == 'driver')
                      TextField(
                        controller: fuelPaymentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Payment for Fuel (PHP)',
                          border: const OutlineInputBorder(),
                          errorText: isFuelPaymentEmpty
                              ? 'This field is required'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            isFuelPaymentEmpty = value.isEmpty;
                          });
                        },
                      ),
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
                      // Check if required fields are filled
                      setState(() {
                        isEndingMileageEmpty =
                            endingMileageController.text.isEmpty;
                        isFuelPaymentEmpty =
                            userRole.toLowerCase() == 'driver' &&
                                fuelPaymentController.text.isEmpty;
                      });

                      // Proceed only if both fields are filled
                      if (!isEndingMileageEmpty && !isFuelPaymentEmpty) {
                        Navigator.of(context).pop(true); // Confirm
                      }
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed) {
        await _finalizeBookingCollection(
          bookingId,
          usersSnapshot,
          userRole,
          endingMileageController.text,
          fuelPaymentController.text,
        );
      }
    }
  }

  Future<void> _finalizeBookingCollection(
    String bookingId,
    QuerySnapshot usersSnapshot,
    String userRole,
    String endingMileage,
    String fuelPayment,
  ) async {
    double finalOverallPrice = 0.0;
    double finalOverallWeight = 0.0;
    double totalDriverShare = 0.0;
    double finalCalculatedOverallPrice = 0.0; // New field
    double sharePercentage =
        userRole.toLowerCase() == 'contractual driver' ? 0.35 : 0.30;

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;

      // Sum up the final price, weight, and calculated total price
      double finalTotalPrice = userData['final_total_price'] ?? 0.0;
      double finalTotalWeight = userData['final_total_weight'] ?? 0.0;
      double calculatedTotalPrice = userData['status'] == 'collected'
          ? userData['final_calculated_total_price'] ?? 0.0
          : userData['calculated_total_price'] ?? 0.0;

      finalOverallPrice += finalTotalPrice;
      finalOverallWeight += finalTotalWeight;
      finalCalculatedOverallPrice +=
          calculatedTotalPrice; // Add calculated total price

      // Calculate the driver share
      double driverShare = 0.0;

      if (userData['status'] != 'failed') {
        double effectiveTotalPrice = userData['mode'] == 'donate'
            ? userData['total_price'] ?? 0.0
            : finalTotalPrice;

        if (userData['firstName'] == "Guest" ||
            userData['category'] == "business") {
          // Guest or Business users: No subtraction of 40
          driverShare =
              ((((effectiveTotalPrice / (1 - 0.30)) - effectiveTotalPrice) *
                  sharePercentage));
        } else {
          // Non-guest and non-business users: Include subtraction of 40
          driverShare = ((((effectiveTotalPrice / (1 - 0.30)) +
                  40 -
                  effectiveTotalPrice) *
              sharePercentage));
        }
      }

      totalDriverShare += driverShare;
    }

    // Update the booking document with the new fields
    var bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    await bookingRef.update({
      'status': 'collected',
      'final_overall_price': finalOverallPrice,
      'final_overall_weight': finalOverallWeight,
      'final_calculated_overall_price':
          finalCalculatedOverallPrice, // New field
      'driver_share': totalDriverShare.toStringAsFixed(2),
      'ending_mileage': double.tryParse(endingMileage) ?? 0.0,
    });

    // Fetch booking data for outflow entry
    var bookingDoc = await bookingRef.get();
    var bookingData = bookingDoc.data() as Map<String, dynamic>;

    String vehicle = bookingData['vehicle'] ?? 'Unknown Vehicle';
    String vehicleId = bookingData['vehicleId'] ?? 'Unknown Vehicle ID';
    String employee = bookingData['driver'] ?? 'Unknown Driver';
    String employeeId = bookingData['driverId'] ?? 'Unknown Driver ID';

    // Check if the employee has a payslip subcollection
    var employeeRef =
        FirebaseFirestore.instance.collection('employees').doc(employeeId);

    var employeeDoc = await employeeRef.get();
    if (employeeDoc.exists) {
      // Check if the payslip subcollection exists

      // Add a new payslip entry for the employee
      var payslipCollectionRef = employeeRef.collection('payslip');
      await payslipCollectionRef.add({
        'date': Timestamp.now(),
        'price': double.parse(totalDriverShare.toStringAsFixed(2)),
        'vehicle': vehicle,
        'vehicleId': vehicleId,
        'bookingId': bookingId,
        'status': 'pending',
        'category': 'driver share',
      });

      print('New payslip entry added for employee $employeeId');
    } else {
      print('Employee $employeeId not found.');
    }

    // Add outflow entry for fuel payment if applicable
    if (userRole.toLowerCase() == 'driver' && fuelPayment.isNotEmpty) {
      double fuelPrice = double.tryParse(fuelPayment) ?? 0.0;
      await FirebaseFirestore.instance.collection('outflow').add({
        'date': Timestamp.now(),
        'price': fuelPrice,
        'vehicle': vehicle,
        'vehicleId': vehicleId,
        'employee': employee,
        'employeeId': employeeId,
        'bookingId': bookingId,
        'status': 'collected',
        'category': 'fuel',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
            'Booking marked as collected. Final overall price, weight, calculated overall price, driver share, and fuel payment updated.'),
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
    String? selectedCategory;
    String? selectedProductName;
    double? recentPrice;
    double? originalPrice;
    String? productId;
    double totalPrice = 0.0; // Variable to track total price dynamically
    String mode = 'regular'; // Default mode

    // Fetch the user's mode
    var userDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      mode = userDoc.data()?['mode'] ?? 'regular';
    }

    // Fetch all categories and types
    var productSnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    List<Map<String, dynamic>> products = productSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'category': doc['category'] ?? 'Unknown',
              'product_name': doc['product_name'] ?? 'Unknown'
            })
        .toList();

    // Get the list of unique categories
    List<String> categories = products
        .map((product) => product['category'] as String)
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter products by the selected category
            List<Map<String, dynamic>> filteredProducts = products
                .where((product) => product['category'] == selectedCategory)
                .toList();

            return AlertDialog(
              title: const Text('Add Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown for selecting a category
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: const Text('Select Category'),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        selectedProductName = null; // Reset product selection
                        totalPrice = 0.0; // Reset total price
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Dropdown for selecting a product (type)
                  DropdownButton<String>(
                    value: selectedProductName,
                    hint: const Text('Select Type'),
                    onChanged: (value) {
                      setState(() {
                        selectedProductName = value;

                        // Find the selected product's details
                        var selectedProduct = filteredProducts.firstWhere(
                            (product) => product['product_name'] == value);

                        productId = selectedProduct['id'];

                        // Fetch latest price and original price
                        _fetchLatestPrice(productId!).then((data) {
                          setState(() {
                            recentPrice = mode == 'donate'
                                ? 0.0
                                : data[
                                    'price']; // Set price to 0 if donate mode
                            originalPrice = data['original_price'];
                            totalPrice = 0.0; // Reset total price
                          });
                        });
                      });
                    },
                    items: filteredProducts.map((product) {
                      return DropdownMenuItem<String>(
                        value: product['product_name'],
                        child: Text(product['product_name']),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Display the most recent price or "Donate Mode Active"
                  recentPrice != null
                      ? Text(mode == 'donate'
                          ? 'Donate Mode Active: Price is ₱0.00'
                          : 'Recent Price: ₱${recentPrice!.toStringAsFixed(2)} per kg')
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
                    onChanged: (value) {
                      // Update the total price dynamically as weight changes
                      setState(() {
                        double weight = double.tryParse(value) ?? 0.0;
                        totalPrice = (recentPrice ?? 0.0) * weight;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Display total price
                  Text(
                    'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                        selectedProductName!,
                        weight,
                        recentPrice!,
                        productId!,
                        selectedCategory!,
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
    try {
      // Fetch the user's mode from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .get();

      var userData = userDoc.data() as Map<String, dynamic>;
      String mode =
          userData['mode'] ?? 'regular'; // Default to 'regular' if not set

      // If the mode is "donate," fetch the latest price for the product type
      double itemPrice = 0.0;
      if (mode == 'donate') {
        var latestPriceData = await _fetchLatestPrice(productId);
        double latestPrice = latestPriceData['price'] ?? 0.0;
        itemPrice = weight * latestPrice;
      } else {
        // Calculate item price using the given price for non-donate modes
        itemPrice = weight * price;
      }

      // Add the product to the recyclables collection
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .collection('recyclables')
          .add({
        'type': productName,
        'weight': weight,
        'price': price,
        'original_price': originalPrice,
        'item_price': itemPrice,
        'productId': productId,
        'category': category,
        'timestamp': Timestamp.now(),
      });

      // Update total weight and total price
      double currentTotalWeight = userData['total_weight'] ?? 0.0;
      double currentTotalPrice = userData['total_price'] ?? 0.0;

      double updatedTotalWeight = currentTotalWeight + weight;
      double updatedTotalPrice = mode == 'donate'
          ? currentTotalPrice +
              itemPrice // Use calculated price for donate mode
          : currentTotalPrice + itemPrice;

      // Update user's totals in Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .update({
        'total_weight': updatedTotalWeight,
        'total_price': updatedTotalPrice,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully.')),
      );
    } catch (e) {
      print('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add product. Please try again.'),
        ),
      );
    }
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
    print('Returning default price values for productId: $productId');
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
    String userRole,
  ) async {
    final pdf = pw.Document();

    // Fetch user and recyclables details
    List<pw.Widget> userDetails =
        await _generateUserDetailsWithRecyclables(bookingId, userRole);

    // Calculate actual total price and weight for consistency
    double actualTotalPrice = 0.0;
    double actualTotalWeight = 0.0;

    // Fetch users for the booking
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      String userStatus = userData['status'] ?? 'pending';

      if (userStatus == 'collected') {
        actualTotalPrice += userData['final_calculated_total_price'] ?? 0.0;
        actualTotalWeight += userData['final_total_weight'] ?? 0.0;
      } else {
        actualTotalPrice += userData['calculated_total_price'] ?? 0.0;
        actualTotalWeight += userData['total_weight'] ?? 0.0;
      }
    }

    // Add the booking summary and user details to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Booking Details Section
          pw.Text(
            "Booking Details",
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text("Booking ID: $bookingId"),
          pw.Text("Status: ${status[0].toUpperCase() + status.substring(1)}"),
          pw.Text("Vehicle: $vehicle"),
          pw.Text("Vehicle ID: $vehicleId"),

          // Replace Estimated/Calculated with Actual Calculated Total
          pw.Text(
            "Actual Total Price: PHP ${actualTotalPrice.toStringAsFixed(2)}",
          ),
          pw.Text(
            "Actual Total Weight: ${actualTotalWeight.toStringAsFixed(2)} kg",
          ),
          pw.Text("Date: $formattedDate"),
          pw.SizedBox(height: 20),

          // Users and Recyclables Section
          pw.Text(
            "Users and Recyclables",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...userDetails,
        ],
      ),
    );

    // Convert PDF to Uint8List
    final pdfBytes = await pdf.save();

    // Create a Blob from the Uint8List
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create a hidden download link
    final anchor = html.AnchorElement()
      ..href = url
      ..download = 'booking_details.pdf'
      ..style.display = 'none';

    // Add the link to the document
    html.document.body?.append(anchor);

    // Trigger a click event on the anchor
    anchor.click();

    // Remove the anchor from the document
    anchor.remove();

    // Clean up the blob URL
    html.Url.revokeObjectUrl(url);
  }

  Future<List<pw.Widget>> _generateUserDetailsWithRecyclables(
      String bookingId, String userRole) async {
    List<pw.Widget> userDetails = [];

    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    double sharePercentage =
        userRole.toLowerCase() == 'contractual driver' ? 0.35 : 0.30;

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      String firstName = userData['firstName'] ?? 'Unknown';
      String lastName = userData['lastName'] ?? 'Unknown';
      String address = userData['address'] ?? 'Unknown';
      String email = userData['email'] ?? 'Unknown';
      String contact = userData['contact'] ?? 'Unknown';
      String userStatus = userData['status'] ?? 'pending';

      double totalPrice = userStatus == 'collected'
          ? userData['final_total_price'] ?? 0.0
          : userData['total_price'] ?? 0.0;
      double calculatedTotalPrice = userStatus == 'collected'
          ? userData['final_calculated_total_price'] ?? 0.0
          : userData['calculated_total_price'] ?? 0.0;
      double totalWeight = userStatus == 'collected'
          ? userData['final_total_weight'] ?? 0.0
          : userData['total_weight'] ?? 0.0;

      // Calculate the driver share
      double driverShare =
          ((((totalPrice / (1 - 0.30)) + 40) - totalPrice) * sharePercentage);

      // Add user details
      userDetails.add(pw.Text(
        "$firstName $lastName (${userStatus.toUpperCase()})",
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
      userDetails
          .add(pw.Text("Driver Share: PHP ${driverShare.toStringAsFixed(2)}"));

      // Fetch recyclables for this user
      var recyclablesSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userDoc.id)
          .collection('recyclables')
          .get();

      if (recyclablesSnapshot.docs.isNotEmpty) {
        userDetails.add(pw.SizedBox(height: 10));
        userDetails.add(pw.Text(
          "Recyclables:",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ));

        // Create table for recyclables
        List<pw.TableRow> tableRows = [
          pw.TableRow(
            children: [
              pw.Text("Type",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Weight (kg)",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Price (PHP)",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Item Price (PHP)",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ];

        for (var recDoc in recyclablesSnapshot.docs) {
          var recData = recDoc.data() as Map<String, dynamic>;
          String type = recData['type'] ?? 'Unknown';
          double weight = recData['final_weight'] ?? recData['weight'] ?? 0.0;
          double price = recData['price'] ?? 0.0;
          double itemPrice = recData['final_item_price'] ?? weight * price;

          tableRows.add(
            pw.TableRow(
              children: [
                pw.Text(type),
                pw.Text(weight.toStringAsFixed(2)),
                pw.Text(price.toStringAsFixed(2)),
                pw.Text(itemPrice.toStringAsFixed(2)),
              ],
            ),
          );
        }

        userDetails.add(
          pw.Table(
            border: pw.TableBorder.all(),
            children: tableRows,
          ),
        );
      } else {
        userDetails.add(pw.Text("No recyclables found."));
      }

      userDetails.add(pw.SizedBox(height: 10));
      userDetails.add(pw.Divider());
    }

    return userDetails;
  }
}
