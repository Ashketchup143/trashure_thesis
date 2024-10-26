import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/addusermodal.dart';
import 'package:trashure_thesis/screens/map.dart';

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
    print(
        'Booking status: $status'); // Add this to check if status is correctly being passed
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Text("Booking Details", style: TextStyle(color: Colors.white)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Maps(
                          bookingId: bookingId)), // Pushing the Maps widget
                );
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
                Row(
                  children: [
                    Text('Booking Details',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Spacer(),
                    if (status == 'collecting') // Show only if collecting
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AddUserModal(bookingId: bookingId);
                            },
                          );
                        },
                        child: Text('Add Guest User'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Text('Booking ID: $bookingId', style: TextStyle(fontSize: 18)),
                Text('Status: $status', style: TextStyle(fontSize: 18)),
                Text('Vehicle: $vehicle', style: TextStyle(fontSize: 18)),
                Text('Vehicle ID: $vehicleId', style: TextStyle(fontSize: 18)),
                Text('Est. Total Price: ₱${overallPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18)),
                Text(
                    'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg',
                    style: TextStyle(fontSize: 18)),
                Text('Date: $formattedDate', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var users = userSnapshot.data?.docs ?? [];
                      if (users.isEmpty) {
                        return Center(child: Text('No users found.'));
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Address: $address, Contact: $contact\nEmail: $email\nTotal Price: ₱$totalPrice\nTotal Weight: ${totalWeight.toStringAsFixed(2)} kg\nCollected: $collectedDate',
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
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    var recyclables =
                                        recyclableSnapshot.data?.docs ?? [];

                                    return ListView.builder(
                                      itemCount: recyclables.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
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

                                        bool isEditing =
                                            isEditingWeight[recyclableId] ??
                                                false;

                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Type: $type'),
                                              Row(
                                                children: [
                                                  if (!isCollected &&
                                                      status ==
                                                          'collecting') // Allow editing only if collecting and not yet collected
                                                    isEditing
                                                        ? Expanded(
                                                            child:
                                                                TextFormField(
                                                              controller:
                                                                  weightControllers[
                                                                      recyclableId],
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText:
                                                                    'Weight (kg)',
                                                                border:
                                                                    OutlineInputBorder(),
                                                              ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                            ),
                                                          )
                                                        : Text(
                                                            'Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg'),
                                                  if (!isCollected &&
                                                      status ==
                                                          'collecting') // Show edit icon only if status is collecting
                                                    IconButton(
                                                      icon: Icon(isEditing
                                                          ? Icons.check
                                                          : Icons.edit),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (isEditing) {
                                                            double newWeight =
                                                                double.tryParse(
                                                                        weightControllers[recyclableId]!
                                                                            .text) ??
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
                                                ],
                                              ),
                                              if (isCollected)
                                                Text(
                                                    'Final Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg'),
                                              Text('Price: ₱$price'),
                                              Text(
                                                  'Item Price: ₱${(updatedWeights[recyclableId]! * price).toStringAsFixed(2)}'),
                                              Divider(),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                if (!isCollected &&
                                    status ==
                                        'collecting') // Allow adding products only if collecting
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          _showAddProductModal(userId,
                                              bookingId); // Function to open modal for adding a product
                                        },
                                        child: Text('Add Product'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue),
                                      ),
                                    ],
                                  ),
                                if (!isCollected &&
                                    status ==
                                        'collecting') // Allow collecting only if status is collecting
                                  ElevatedButton(
                                    onPressed: () async {
                                      _showCollectedConfirmation(
                                          userId,
                                          bookingId,
                                          firstName,
                                          lastName,
                                          userData);
                                    },
                                    child: Text('Collected'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
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
                    child: Text('Mark Booking as Collected'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCollectedConfirmation(String userId, String bookingId,
      String firstName, String lastName, Map<String, dynamic> userData) async {
    // Show modal to confirm collection
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you sure you want to mark $firstName $lastName as collected?'),
              Text(
                  'Recyclables and their updated weights/prices will be finalized.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text('Confirm'),
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

    // Now update the user's document with final_total_price, final_total_weight, and collected status
    var userRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId);

    batch.update(userRef, {
      'status': 'collected',
      'final_total_price': finalTotalPrice, // Store the final total price
      'final_total_weight': finalTotalWeight, // Store the final total weight
      'collected_timestamp':
          Timestamp.now(), // Add collected timestamp for the user
    });

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
      'price': finalTotalPrice,
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
      SnackBar(
          content: Text(
              'User marked as collected, total price and weight calculated, and outflow recorded')),
    );
  }

  Future<void> _showFinalCollectedConfirmation(String bookingId) async {
    bool hasUncollectedUsers = false;

    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .get();

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      if (userData['status'] != 'collected') {
        hasUncollectedUsers = true;
        break;
      }
    }

    if (hasUncollectedUsers) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Incomplete Collection'),
            content: Text(
                'There are users who have not been marked as collected. Please finish collecting before marking the booking as completed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Ok'),
              ),
            ],
          );
        },
      );
    } else {
      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Mark Booking as Completed',
            ),
            content: Text(
                'Are you sure you want to mark the entire booking as completed?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed) {
        // Calculate the total final_overall_price and final_overall_weight
        double finalOverallPrice = 0.0;
        double finalOverallWeight = 0.0;

        for (var userDoc in usersSnapshot.docs) {
          var userData = userDoc.data() as Map<String, dynamic>;
          double finalTotalPrice = userData['final_total_price'] ?? 0.0;
          double finalTotalWeight = userData['final_total_weight'] ?? 0.0;

          finalOverallPrice += finalTotalPrice;
          finalOverallWeight += finalTotalWeight;
        }

        // Update the booking document with the final overall price and weight
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'collected',
          'final_overall_price': finalOverallPrice,
          'final_overall_weight': finalOverallWeight,
        });

        // Get booking details for outflow entry
        var bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get();
        var bookingData = bookingDoc.data() as Map<String, dynamic>;

        String vehicle = bookingData['vehicle'] ?? 'Unknown';
        String vehicleId = bookingData['vehicleId'] ?? 'Unknown';
        String employee = bookingData['driver'] ?? 'Unknown';
        String employeeId = bookingData['driverId'] ?? 'Unknown';

        // Add the outflow entry
        await FirebaseFirestore.instance.collection('outflow').add({
          'date': Timestamp.now(), // Current date and time
          'price': finalOverallPrice, // final_overall_price
          'weight': finalOverallWeight, // final_overall_weight
          'vehicle': vehicle,
          'vehicleId': vehicleId,
          'employee': employee,
          'employeeId': employeeId,
          'bookingId': bookingId,
          'status': 'collected',
          'category': 'booking',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                  'Booking marked as collected. Final overall price and weight updated.')),
        );
        // Pop the current screen after the operation is complete
        Navigator.of(context).pop();
      }
    }
  }

  void _showAddProductModal(String userId, String bookingId) async {
    final TextEditingController weightController = TextEditingController();
    String selectedProductName = 'Unknown';
    double? recentPrice;

    // Fetch existing product names in user's recyclables
    List<String> existingProductNames =
        await _fetchUserRecyclableProductNames(userId, bookingId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Product'),
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
                        return CircularProgressIndicator();
                      }

                      var products = snapshot.data!.docs.where((doc) {
                        String productName =
                            doc['product_name'].toString().toLowerCase();
                        return !existingProductNames
                            .contains(productName); // Exclude existing products
                      }).toList();

                      if (products.isEmpty) {
                        return Text("No new products available to add.");
                      }

                      if (selectedProductName == 'Unknown' &&
                          products.isNotEmpty) {
                        selectedProductName = products.first['product_name'];
                      }

                      return DropdownButton<String>(
                        value: selectedProductName,
                        onChanged: (value) {
                          setState(() {
                            selectedProductName = value!;
                            _fetchLatestPrice(selectedProductName)
                                .then((price) {
                              setState(() {
                                recentPrice = price;
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
                  SizedBox(height: 10),
                  // Display the most recent price
                  recentPrice != null
                      ? Text(
                          'Recent Price: ₱${recentPrice!.toStringAsFixed(2)} per kg')
                      : Text("no product chosen"),
                  SizedBox(height: 10),
                  // Input for weight
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
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
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double weight =
                        double.tryParse(weightController.text) ?? 0.0;
                    if (recentPrice != null && weight > 0) {
                      await _addProductToUser(userId, bookingId,
                          selectedProductName, weight, recentPrice!);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
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

// Function to fetch the latest price for a product based on product_name
  Future<double> _fetchLatestPrice(String productName) async {
    try {
      // Find the product document by product_name
      var productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('product_name', isEqualTo: productName)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        var productId = productSnapshot.docs.first.id;

        // Fetch the latest price from the 'prices' subcollection
        var priceSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .collection('prices')
            .orderBy('time', descending: true)
            .limit(1)
            .get();

        if (priceSnapshot.docs.isNotEmpty) {
          return priceSnapshot.docs.first['price']?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      print('Error fetching latest price: $e');
    }
    return 0.0; // Default if no price is found
  }

// Add the product to user's recyclables
  Future<void> _addProductToUser(String userId, String bookingId,
      String productName, double weight, double price) async {
    double totalPrice = weight * price;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .add({
      'type': productName, // Changed to productName
      'weight': weight,
      'price': price,
      'item_total': totalPrice,
      'added_timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product added successfully.')),
    );
  }
}
