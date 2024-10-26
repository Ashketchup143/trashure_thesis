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
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Text(
              'Booking Details',
              style: TextStyle(color: Colors.white),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.map),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display booking fields with null checks
            Text("Booking ID: $bookingId"),
            Text("Date: ${_formatDateTime(bookingData['date'])}"),
            Text(
                "Time: ${_formatTime(bookingData['start_time'], bookingData['end_time'])}"),
            Text("Driver: ${bookingData['driver'] ?? 'No Driver Assigned'}"),
            Text("Vehicle: ${bookingData['vehicle'] ?? 'No Vehicle Assigned'}"),
            Text("Status: ${bookingData['status'] ?? 'No Status'}"),
            SizedBox(height: 20),

            // Fetch and display user data with recyclables
            Center(
              child: Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height * .7,
                  width: MediaQuery.of(context).size.width * .95,
                  decoration: BoxDecoration(border: Border.all()),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var users = snapshot.data?.docs ?? [];
                      if (users.isEmpty) {
                        return Center(
                            child:
                                Text('No users associated with this booking.'));
                      }

                      double overallTotal = 0; // Initialize overall total

                      return Container(
                        child: FutureBuilder(
                          future: _calculateOverallTotal(users),
                          builder: (context, totalSnapshot) {
                            if (!totalSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            overallTotal = totalSnapshot.data ?? 0;

                            return Column(
                              children: [
                                _buildTitlesRow(), // Add a row with column titles
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      var userDoc = users[index];
                                      var userData = userDoc.data()
                                          as Map<String, dynamic>;

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('bookings')
                                            .doc(bookingId)
                                            .collection('users')
                                            .doc(userDoc.id)
                                            .collection('recyclables')
                                            .snapshots(),
                                        builder:
                                            (context, recyclablesSnapshot) {
                                          if (!recyclablesSnapshot.hasData) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          var recyclables =
                                              recyclablesSnapshot.data?.docs ??
                                                  [];
                                          double userTotal = 0;

                                          recyclables.forEach((recyclableDoc) {
                                            var recyclableData = recyclableDoc
                                                .data() as Map<String, dynamic>;
                                            double weight =
                                                recyclableData['weight'] ?? 0;
                                            double price =
                                                recyclableData['price'] ?? 0;
                                            double itemTotal = weight * price;

                                            userTotal += itemTotal;
                                          });

                                          return ExpansionTile(
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      "${userData['firstName'] ?? 'No First Name'} ${userData['lastName'] ?? 'No Last Name'}"),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      userData['email'] ??
                                                          'No Email'),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Text(
                                                      userData['address'] ??
                                                          'No Address'),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                        "₱${userTotal.toStringAsFixed(2)}"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: [
                                              Container(
                                                color: const Color.fromARGB(255,
                                                    239, 239, 237), // Add shade
                                                child: Column(
                                                  children: recyclables
                                                      .map((recyclableDoc) {
                                                    var recyclableData =
                                                        recyclableDoc.data()
                                                            as Map<String,
                                                                dynamic>;
                                                    double weight =
                                                        recyclableData[
                                                                'weight'] ??
                                                            0;
                                                    double price =
                                                        recyclableData[
                                                                'price'] ??
                                                            0;
                                                    double itemTotal =
                                                        weight * price;

                                                    return ListTile(
                                                      title: Text(
                                                          "Type: ${recyclableData['type'] ?? 'No Type'}"),
                                                      subtitle: Text(
                                                        "Weight: $weight kg, Price: ₱${price.toStringAsFixed(2)}, Item Total: ₱${itemTotal.toStringAsFixed(2)}",
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.edit),
                                                            onPressed: () {
                                                              showEditRecyclableDialog(
                                                                  context,
                                                                  bookingId,
                                                                  userDoc.id,
                                                                  recyclableDoc
                                                                      .id,
                                                                  recyclableData);
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.delete),
                                                            onPressed: () {
                                                              FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'bookings')
                                                                  .doc(
                                                                      bookingId)
                                                                  .collection(
                                                                      'users')
                                                                  .doc(userDoc
                                                                      .id)
                                                                  .collection(
                                                                      'recyclables')
                                                                  .doc(
                                                                      recyclableDoc
                                                                          .id)
                                                                  .delete();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xFF4CAF4F),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  // Add new recyclable
                                                  showAddRecyclableDialog(
                                                      context,
                                                      bookingId,
                                                      userDoc.id);
                                                },
                                                child: Text(
                                                  "Add Recyclable",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                // Display the booking overall price with a StreamBuilder
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .doc(bookingId)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    var updatedBooking = snapshot.data?.data()
                                        as Map<String, dynamic>;
                                    double overallPrice =
                                        updatedBooking['overall_price'] ?? 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Overall Total for Booking: ₱${overallPrice.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format date and time
  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'No Date';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM d, yyyy (EEEE)').format(dateTime);
  }

  // Format start and end time
  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 'No Time';
    return "$startTime - $endTime";
  }

  // Function to calculate the overall total for all users
  Future<double> _calculateOverallTotal(
      List<QueryDocumentSnapshot> users) async {
    double overallTotal = 0;
    for (var userDoc in users) {
      var recyclablesSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userDoc.id)
          .collection('recyclables')
          .get();

      for (var recyclableDoc in recyclablesSnapshot.docs) {
        var recyclableData = recyclableDoc.data() as Map<String, dynamic>;
        double weight = recyclableData['weight'] ?? 0;
        double price = recyclableData['price'] ?? 0;
        double itemTotal = weight * price;

        overallTotal += itemTotal;
      }
    }

    return overallTotal;
  }

  // Add a row for column titles
  Widget _buildTitlesRow() {
    return Row(
      children: [
        title('Name', 3),
        title('Email', 3),
        title('Address', 4),
        title('Total', 2),
      ],
    );
  }

  Expanded title(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
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
        title: Text('Edit Recyclable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Validate and parse the input values
              double weight = double.tryParse(weightController.text) ?? 0.0;
              double price = double.tryParse(priceController.text) ?? 0.0;

              // Update the recyclable with new values
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
                'item_price': weight * price, // Update item price
              });

              // Update the user's total price
              await _updateUserTotalPrice(bookingId, userId);

              // Update the booking's overall price
              await _updateBookingOverallPrice(bookingId);

              // Re-fetch the updated booking data
              var updatedBooking = await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .get();
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserTotalPrice(String bookingId, String userId) async {
    double userTotalPrice = 0;

    // Fetch all recyclables for this user
    var recyclablesSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .get();

    for (var recyclableDoc in recyclablesSnapshot.docs) {
      var recyclableData = recyclableDoc.data();
      double itemPrice = recyclableData['item_price'] ?? 0;
      userTotalPrice += itemPrice; // Sum up all item prices
    }

    // Update the total price in the user's document
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .update({
      'total_price': userTotalPrice,
    });
  }

  Future<void> _updateBookingOverallPrice(String bookingId) async {
    double overallTotalPrice = 0;

    // Fetch all users for this booking
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data();
      double userTotalPrice = userData['total_price'] ?? 0;
      overallTotalPrice += userTotalPrice; // Sum up all user total prices
    }

    // Update the overall price in the booking document
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({
      'overall_price': overallTotalPrice,
    });
  }

  // Function to show the dialog for adding a recyclable
  void showAddRecyclableDialog(
      BuildContext context, String bookingId, String userId) {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    String? selectedProduct;
    double? recentProductPrice;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Recyclable'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    var products = snapshot.data?.docs ?? [];

                    if (products.isEmpty) {
                      return Text("No products available");
                    }

                    return DropdownButton<String>(
                      value: selectedProduct,
                      hint: Text('Select Product'),
                      onChanged: (String? newValue) async {
                        setState(() {
                          selectedProduct = newValue;
                        });

                        // Fetch recent price for the selected product
                        var pricesSnapshot = await FirebaseFirestore.instance
                            .collection('products')
                            .doc(newValue)
                            .collection('prices')
                            .orderBy('time', descending: true)
                            .limit(1)
                            .get();

                        if (pricesSnapshot.docs.isNotEmpty) {
                          var priceData = pricesSnapshot.docs.first.data()
                              as Map<String, dynamic>;
                          setState(() {
                            recentProductPrice = priceData['price'] ?? 0.0;
                            priceController.text =
                                recentProductPrice!.toString();
                          });
                        }
                      },
                      items: products.map((doc) {
                        var productData = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(productData['product_name'] ?? 'Unnamed'),
                        );
                      }).toList(),
                    );
                  },
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price (₱)'),
                  keyboardType: TextInputType.number,
                ),
                if (recentProductPrice != null)
                  Text(
                    "Suggested Price: ₱${recentProductPrice?.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  double? weight = double.tryParse(weightController.text);
                  double? price = double.tryParse(priceController.text);

                  if (selectedProduct == null ||
                      weight == null ||
                      price == null ||
                      weight <= 0 ||
                      price <= 0) {
                    // Add error message instead of Snackbar
                    setState(() {
                      // You could set an error message here to display in the dialog
                    });
                    return;
                  }

                  double itemPrice = weight * price;

                  // Add the recyclable to the user's subcollection
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .collection('users')
                      .doc(userId)
                      .collection('recyclables')
                      .add({
                    'type': selectedProduct,
                    'weight': weight,
                    'price': price,
                    'item_price': itemPrice, // Add item_price calculation
                  });

                  // Update the user's total price
                  await _updateUserTotalPrice(bookingId, userId);

                  // Update the booking's overall price
                  await _updateBookingOverallPrice(bookingId);

                  Navigator.of(context).pop();
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
