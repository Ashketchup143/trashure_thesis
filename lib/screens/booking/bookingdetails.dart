import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';

class BookingDetails extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  BookingDetails({required this.bookingId, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Row(
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            // Add Reviews Icon if the status is 'collected' or 'completed'
            if (bookingData['status'] == 'collected' ||
                bookingData['status'] == 'completed')
              IconButton(
                icon: const Icon(Icons.rate_review, color: Colors.white),
                onPressed: () {
                  _showReviewDialog(context, bookingId);
                },
              ),
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Maps(bookingId: bookingId)),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Booking ID: $bookingId"),
            Text("Date: ${_formatDateTime(bookingData['date'])}"),
            Text(
                "Location: ${bookingData['location'] ?? 'No Location Assigned'}"),
            Text(
                "Time: ${_formatTime(bookingData['start_time'], bookingData['end_time'])}"),
            Text("Driver: ${bookingData['driver'] ?? 'No Driver Assigned'}"),
            Text("Vehicle: ${bookingData['vehicle'] ?? 'No Vehicle Assigned'}"),
            Text("Status: ${bookingData['status'] ?? 'No Status'}"),
            // Display number of users using StreamBuilder
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text(
                    'Error fetching users',
                    style: TextStyle(color: Colors.red),
                  );
                } else {
                  final userCount = snapshot.data?.docs.length ?? 0;
                  return Text(
                    "Number of Users: $userCount",
                  );
                }
              },
            ),
            // Display Starting and Ending Mileage if the status is 'collected' or 'completed'
            if (bookingData['status'] == 'collected' ||
                bookingData['status'] == 'completed') ...[
              Text(
                "Driver Share: ${bookingData['driver_share'] ?? 'N/A'}",
                style: const TextStyle(),
              ),
              Text(
                "Starting Mileage: ${bookingData['starting_mileage']?.toStringAsFixed(2) ?? 'N/A'} km",
                style: const TextStyle(),
              ),
              Text(
                "Ending Mileage: ${bookingData['ending_mileage']?.toStringAsFixed(2) ?? 'N/A'} km",
                style: const TextStyle(),
              ),
            ],

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var users = snapshot.data?.docs ?? [];
                    if (users.isEmpty) {
                      return const Center(
                          child:
                              Text('No users associated with this booking.'));
                    }

                    return Column(
                      children: [
                        _buildTitlesRow(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var userDoc = users[index];
                              var userData =
                                  userDoc.data() as Map<String, dynamic>;

                              return _buildUserTile(
                                  context, bookingId, userDoc.id, userData);
                            },
                          ),
                        ),
                        _buildOverallTotals(bookingId),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, String bookingId, String userId,
      Map<String, dynamic> userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .collection('recyclables')
          .snapshots(),
      builder: (context, recyclablesSnapshot) {
        if (!recyclablesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var recyclables = recyclablesSnapshot.data?.docs ?? [];

        double userTotalWeight = recyclables.fold(0.0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          return sum + (data['final_weight'] ?? data['weight'] ?? 0.0);
        });

        double userTotalPrice = recyclables.fold(0.0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          return sum + (data['final_item_price'] ?? data['item_price'] ?? 0.0);
        });

// Set total price to 0 if the user is in "donate" mode
        if (userData['mode']?.toString().toLowerCase() == 'donate') {
          userTotalPrice = 0.0;
        }

        double calculatedTotalPrice =
            userData['final_calculated_total_price'] ??
                userData['calculated_total_price'] ??
                0.0;

        // Determine the share percentage based on the driver's position
        double sharePercentage = 0.30; // Default to 30%
        if (bookingData['position']?.toString().toLowerCase() ==
            'contractual driver') {
          sharePercentage = 0.35; // Set to 35% for contractual drivers
        }

// Initialize driverShare
        double driverShare = 0.0;

// Determine the effective total price based on the user's mode
        if (userData['status'] != 'failed') {
          double effectiveTotalPrice =
              userData['mode']?.toString().toLowerCase() == 'donate'
                  ? userData['total_price'] ?? 0.0
                  : userData['final_total_price'] ??
                      userData['total_price'] ??
                      0.0;

          if (userData['firstName']?.toString().toLowerCase() == "guest") {
            // Guest users: No addition of 40
            driverShare =
                ((((effectiveTotalPrice / (1 - 0.30)) - effectiveTotalPrice) *
                    sharePercentage));
          } else {
            // Non-guest users: Include addition of 40
            driverShare = ((((effectiveTotalPrice / (1 - 0.30)) +
                    40 -
                    effectiveTotalPrice) *
                sharePercentage));
          }

          driverShare =
              double.parse(driverShare.toStringAsFixed(2)); // Round off
        }
        return ExpansionTile(
          title: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                    "${userData['firstName'] ?? 'No First Name'} ${userData['lastName'] ?? 'No Last Name'}"),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                      userData['category'] ?? 'No Category'), // Add Category
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(userData['email'] ?? 'No Email'),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  userData['address'] ?? 'No Address',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(userData['status'] ?? 'No Status'),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("${userTotalWeight.toStringAsFixed(2)} kg"),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("₱${userTotalPrice.toStringAsFixed(2)}"),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("₱${calculatedTotalPrice.toStringAsFixed(2)}"),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("₱${driverShare.toStringAsFixed(2)}"),
                ),
              ),
            ],
          ),
          children: [
            const Divider(), // Ad

            Column(
              children: [
                // Title Row for the recyclables
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Type",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Weight (kg)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Price (₱)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Total (₱)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(), // Add a divider for visual separation

                ...recyclables.map((recyclableDoc) {
                  var recyclableData =
                      recyclableDoc.data() as Map<String, dynamic>;

                  // Extract weight and price from recyclableData
                  double weight = recyclableData['final_weight'] ??
                      recyclableData['weight'] ??
                      0.0;
                  double price = recyclableData['price'] ?? 0.0;

                  // Dynamically calculate itemPrice as weight * price
                  double itemPrice = weight * price;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            recyclableData['type'] ?? 'No Type',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${weight.toStringAsFixed(2)} kg",
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₱${price.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "₱${itemPrice.toStringAsFixed(2)}", // Use dynamically calculated itemPrice
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                if (userData['status']?.toLowerCase() == 'collected')
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Collected Timestamp: ${_formatDateTime(userData['collected_timestamp'])}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Color.fromARGB(255, 98, 95, 95)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverallTotals(String bookingId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = userSnapshot.data!.docs;

        double overallWeight = 0.0;
        double overallTotalPrice = 0.0;
        double totalCalculatedPrice = 0.0;
        double totalDriverShare = 0.0;

        return FutureBuilder<List<QuerySnapshot>>(
          future: Future.wait(
            users.map((userDoc) {
              return FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .doc(userDoc.id)
                  .collection('recyclables')
                  .get();
            }).toList(),
          ),
          builder: (context, recyclablesSnapshots) {
            if (!recyclablesSnapshots.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            for (int i = 0; i < users.length; i++) {
              var userDoc = users[i];
              var userData = userDoc.data() as Map<String, dynamic>;
              var recyclables = recyclablesSnapshots.data![i].docs;

              double userWeight = 0.0;
              double userTotalPrice = 0.0;

              // Calculate totals for all recyclables of this user
              for (var recyclableDoc in recyclables) {
                var recyclableData =
                    recyclableDoc.data() as Map<String, dynamic>;

                double recyclableWeight = recyclableData['final_weight'] ??
                    recyclableData['weight'] ??
                    0.0;
                double recyclableItemPrice =
                    recyclableData['final_item_price'] ??
                        recyclableData['item_price'] ??
                        0.0;

                userWeight += recyclableWeight;
                userTotalPrice += recyclableItemPrice;
              }

              // Skip adding the price if the user is in "donate" mode
              if (userData['mode']?.toString().toLowerCase() != 'donate') {
                overallTotalPrice += userTotalPrice;
              }
              // Update the overall totals
              overallWeight += userWeight;
              overallTotalPrice += userTotalPrice;

              // Add the calculated total price (or final_calculated_total_price if available)
              double userCalculatedTotalPrice =
                  userData['final_calculated_total_price'] ??
                      userData['calculated_total_price'] ??
                      0.0;
              totalCalculatedPrice += userCalculatedTotalPrice;

              // Calculate and add the driver share
              double sharePercentage = 0.30; // Default share
              if (userData['position']?.toString().toLowerCase() ==
                  'contractual driver') {
                sharePercentage = 0.35; // Contractual driver share
              }

              double calculatedPrice = userData['total_price'] ??
                  userData['final_total_price'] ??
                  0.0;
              // double driverShare =
              //     ((((calculatedPrice / (1 - 0.30)) + 40) - calculatedPrice) *
              //         sharePercentage);

              // totalDriverShare += driverShare;
            }

            // Render calculated totals
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    "Overall Weight for Booking: ${overallWeight.toStringAsFixed(2)} kg",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "Total Calculated Price for Booking: ₱${totalCalculatedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   "Total Driver Share: ₱${totalDriverShare.toStringAsFixed(2)}",
                  //   style: const TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTitlesRow() {
    return Row(
      children: [
        title('Name', 3),
        title('Category', 2),
        title('Email', 3),
        title('Address', 4),
        title('Status', 2),
        title('Weight (kg)', 2),
        title('Total (₱)', 2),
        title('Calculated Price (₱)', 2), // New column for Calculated Price
        title('Driver Share (₱)', 2), // New column for Driver Share
      ],
    );
  }

  Expanded title(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'No Date';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM d, yyyy (EEEE)').format(dateTime);
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 'No Time';
    return "$startTime - $endTime";
  }

  Widget _buildRecyclableActions(BuildContext context, String bookingId,
      String userId, String recyclableId, Map<String, dynamic> recyclableData) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            showEditRecyclableDialog(
                context, bookingId, userId, recyclableId, recyclableData);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .collection('users')
                .doc(userId)
                .collection('recyclables')
                .doc(recyclableId)
                .delete();
          },
        ),
      ],
    );
  }

  void showEditRecyclableDialog(BuildContext context, String bookingId,
      String userId, String recyclableId, Map<String, dynamic> recyclableData) {
    final TextEditingController weightController =
        TextEditingController(text: recyclableData['weight'].toString());
    final TextEditingController priceController =
        TextEditingController(text: recyclableData['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recyclable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              double weight = double.tryParse(weightController.text) ?? 0.0;
              double price = double.tryParse(priceController.text) ?? 0.0;

              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .doc(userId)
                  .collection('recyclables')
                  .doc(recyclableId)
                  .update({
                'weight': weight,
                'price': price,
                'item_price': weight * price,
              });

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Customer Reviews"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.8, // Set a responsive width
            height: MediaQuery.of(context).size.height *
                0.5, // Set a responsive height
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('customer_review')
                  .orderBy('date', descending: true) // Sort by most recent date
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("An error occurred."));
                }

                var reviews = snapshot.data?.docs ?? [];
                if (reviews.isEmpty) {
                  return const Center(child: Text("No reviews available."));
                }

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var reviewData =
                        reviews[index].data() as Map<String, dynamic>? ?? {};
                    String name = reviewData['name'] ?? 'Anonymous';
                    int rating = reviewData['rating'] ?? 0;
                    String feedback =
                        reviewData['feedback'] ?? 'No feedback provided';
                    DateTime? date =
                        (reviewData['date'] as Timestamp?)?.toDate();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Rating: $rating/5",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Feedback: $feedback",
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (date != null)
                            Text(
                              "Date: ${DateFormat('MMMM d, yyyy, h:mm a').format(date)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          const Divider(), // Add a divider for better separation
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
