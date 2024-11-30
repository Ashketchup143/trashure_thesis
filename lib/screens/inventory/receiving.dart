import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:trashure_thesis/sidebar.dart';

class Receiving extends StatefulWidget {
  const Receiving({super.key});

  @override
  State<Receiving> createState() => _ReceivingState();
}

class _ReceivingState extends State<Receiving> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  List<Map<String, dynamic>> significantDifferences =
      []; // To store the significant differences

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * .96,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 30),
                      onPressed: () {
                        Scaffold.of(context).openDrawer(); // Opens the drawer
                      },
                    ),
                    Text(
                      'Receiving (Collected Bookings)',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Search Bar
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 430,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(17.5),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by booking ID, driver, or date',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25),
                // List of bookings with StreamBuilder inside Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .orderBy('date', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var bookings = snapshot.data?.docs ?? [];

                        // Filter bookings to include only 'collected' status
                        var collectedBookings = bookings.where((doc) {
                          var data = doc.data() as Map<String, dynamic>?;
                          return data?['status'] == 'collected' &&
                              _matchesSearchQuery(data);
                        }).toList();

                        if (collectedBookings.isEmpty) {
                          return const Center(
                              child: Text('No collected bookings found'));
                        }

                        return Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.black)),
                              ),
                              child: Row(
                                children: [
                                  title('Booking ID', 2),
                                  title('Date', 3),
                                  title('Location', 2),
                                  title('Driver', 2),
                                  title('Vehicle', 2),
                                  title('OA. Price', 1),
                                  title('OA. Weight', 1),
                                  title('#', 1),
                                  title('Details', 1),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: collectedBookings.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  var doc = collectedBookings[index];
                                  var bookingData =
                                      doc.data() as Map<String, dynamic>;
                                  var bookingId = doc.id;
                                  return _buildExpansionTile(
                                      bookingId, bookingData);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _fetchNumOfUsers(String bookingId) async {
    try {
      final usersCollection = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users');
      final snapshot = await usersCollection.get();
      return snapshot.size;
    } catch (e) {
      print('Error fetching number of users for booking $bookingId: $e');
      return 0; // Return 0 in case of an error
    }
  }

  // Function to build expansion tile with booking information and recyclables
  Widget _buildExpansionTile(
      String bookingId, Map<String, dynamic> bookingData) {
    Map<String, TextEditingController> inputControllers = {};
    Map<String, double> totalWeights = {};
    Map<String, double> differences = {};

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(flex: 2, child: Text('Booking ID: $bookingId')),
          Expanded(
            flex: 3,
            child: Text(
              bookingData['date'] != null
                  ? "${DateFormat('MMMM d, yyyy').format(bookingData['date'].toDate())}, "
                      "${bookingData['start_time'] ?? 'N/A'} - ${bookingData['end_time'] ?? 'N/A'}"
                  : 'No Date',
            ),
          ),
          Expanded(
            flex: 2,
            child:
                Center(child: Text(bookingData['location'] ?? 'No Location')),
          ),
          Expanded(
              flex: 2,
              child: Center(child: Text(bookingData['driver'] ?? 'No Driver'))),
          Expanded(
            flex: 2,
            child: Center(child: Text(bookingData['vehicle'] ?? 'No Vehicle')),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                bookingData['overall_price'] != null
                    ? '₱${bookingData['overall_price'].toStringAsFixed(2)}'
                    : '₱0',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                bookingData['overall_weight'] != null
                    ? '${bookingData['overall_weight'].toStringAsFixed(2)} kg'
                    : 'N/A',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: FutureBuilder<int>(
                future: _fetchNumOfUsers(bookingId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Error',
                        style: TextStyle(color: Colors.red));
                  } else {
                    return Text(
                      '${snapshot.data}',
                      style: TextStyle(fontSize: 14),
                    );
                  }
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: const Icon(Icons.map, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Maps(bookingId: bookingId)),
                    );
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: const Icon(Icons.info_outline, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetails(
                          bookingId: bookingId,
                          bookingData: bookingData,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        SizedBox(
          height: 350,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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

                    totalWeights.clear();
                    differences.clear();

                    List<Future<void>> userRecyclablesFutures =
                        users.map((userDoc) async {
                      QuerySnapshot recyclableSnapshot = await userDoc.reference
                          .collection('recyclables')
                          .get();
                      var recyclables = recyclableSnapshot.docs;

                      recyclables.forEach((recyclableDoc) {
                        var recyclableData =
                            recyclableDoc.data() as Map<String, dynamic>;

                        String type =
                            (recyclableData['type'] ?? 'unknown').toString();
                        double weight =
                            (recyclableData['final_weight'] ?? 0).toDouble();

                        totalWeights[type] = (totalWeights[type] ?? 0) + weight;

                        inputControllers[type] = TextEditingController(
                            text: totalWeights[type]!.toStringAsFixed(1));
                        differences[type] = 0;
                      });
                    }).toList();

                    return FutureBuilder(
                      future: Future.wait(userRecyclablesFutures),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return ListView(
                          shrinkWrap: true,
                          children: totalWeights.entries.map((entry) {
                            String type = entry.key;
                            double totalWeight = entry.value;
                            return _buildRecyclableInputTile(
                              type,
                              totalWeight,
                              inputControllers[type]!,
                              differences,
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF4F),
                ),
                onPressed: () async {
                  showInventoryTransferModal(context, totalWeights, () async {
                    await addWeightsToInventory(
                        totalWeights, inputControllers, bookingId);
                    await checkForSignificantDifferenceAndReport(
                        bookingId, totalWeights, inputControllers, bookingData);
                    await updateBookingStatus(bookingId);
                  });
                },
                child: const Text(
                  'Complete Booking and Add to Inventory',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  void showInventoryTransferModal(BuildContext context,
      Map<String, double> totalWeights, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Items to be Transferred to Inventory'),
          content: Container(
            width: double.maxFinite,
            height:
                MediaQuery.of(context).size.height * 0.6, // Set a fixed height
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List the items and their respective weights in a scrollable view
                  ...totalWeights.entries.map((entry) {
                    return ListTile(
                      title: Text('Type: ${entry.key}'),
                      subtitle:
                          Text('Weight: ${entry.value.toStringAsFixed(2)} kg'),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
                onConfirm(); // Execute the action to transfer to inventory
              },
              child: const Text('Confirm Transfer'),
            ),
          ],
        );
      },
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text("Transferring to Inventory... Please wait."),
            ],
          ),
        );
      },
    );
  }

  // Function to build a recyclable input tile with input handling and difference calculation
  Widget _buildRecyclableInputTile(String type, double totalWeight,
      TextEditingController inputController, Map<String, double> differences) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text('Type: $type'),
                subtitle: Text('Total Weight: $totalWeight kg'),
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: inputController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Input weight',
                ),
                onChanged: (value) {
                  double inputWeight = double.tryParse(value) ?? 0;
                  setState(() {
                    differences[type] = inputWeight - totalWeight;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '${differences[type]?.toStringAsFixed(2)} kg',
                style: TextStyle(
                  color: (differences[type]! < 0) ? Colors.red : Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to check for significant differences and report if necessary
  Future<void> checkForSignificantDifferenceAndReport(
      String bookingId,
      Map<String, double> totalWeights,
      Map<String, TextEditingController> inputControllers,
      Map<String, dynamic> bookingData) async {
    double significantDifferenceThresholdPercent = 5.0; // 5% difference
    String driverId = bookingData['driverId'] ?? 'Unknown Driver';
    String driver = bookingData['driver'] ?? 'Unknown';
    DateTime bookingDate = bookingData['date'].toDate();

    // Clear the significant differences list for the modal
    significantDifferences.clear();

    // Loop through totalWeights and compare with input values
    for (var entry in totalWeights.entries) {
      String type = entry.key;
      double totalWeight = entry.value;
      double inputWeight = double.tryParse(inputControllers[type]!.text) ?? 0;

      double percentDifference =
          ((inputWeight - totalWeight).abs() / totalWeight) * 100;
      if (percentDifference > significantDifferenceThresholdPercent) {
        // Add the significant difference to the list for the modal
        significantDifferences.add({
          'type': type,
          'totalWeight': totalWeight,
          'inputWeight': inputWeight,
          'difference': percentDifference,
          'category': 'recyclables', // Assuming category is recyclables for now
        });

        // Directly reference the employee using driverId
        DocumentReference employeeDoc =
            FirebaseFirestore.instance.collection('employees').doc(driverId);

        // Add a report in the employee's `reports` subcollection
        DocumentReference reportDoc =
            await employeeDoc.collection('reports').add({
          'bookingId': bookingId,
          'driverId': driverId,
          'driver': driver,
          'bookingDate': bookingDate,
          'category': 'recyclables',
          'dateChecked': FieldValue.serverTimestamp(),
        });

        // Add recyclables subcollection with discrepancies
        for (var diff in significantDifferences) {
          await reportDoc.collection('recyclables').add({
            'type': diff['type'],
            'totalWeight': diff['totalWeight'],
            'inputWeight': diff['inputWeight'],
            'difference': diff['difference'],
          });
        }
      }
    }

    // Show the modal if there are significant differences
    if (significantDifferences.isNotEmpty) {
      showModal(context, bookingId, driver, driverId, bookingDate);
    }
  }

  // Function to show a modal with the significant differences
  void showModal(BuildContext context, String bookingId, String driver,
      String driverId, DateTime bookingDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Significant Differences Found'),
          content: Container(
            height: MediaQuery.of(context).size.height * .5,
            width: MediaQuery.of(context).size.width * .5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ID: $bookingId'),
                Text('Driver: $driver'),
                Text('Driver ID: $driverId'),
                Text(
                    'Booking Date: ${DateFormat('MMMM d, yyyy').format(bookingDate)}'),
                SizedBox(height: 20),
                Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: significantDifferences.length,
                    itemBuilder: (BuildContext context, int index) {
                      var difference = significantDifferences[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${difference['type']}'),
                            Text(
                                'Total Weight: ${difference['totalWeight']} kg'),
                            Text(
                                'Inputted Weight: ${difference['inputWeight']} kg'),
                            Text(
                                'Difference: ${difference['difference'].toStringAsFixed(2)} %'),
                            Text('Category: ${difference['category']}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to add inputted weights of all recyclables to inventory
  Future<void> addWeightsToInventory(
    Map<String, double> totalWeights,
    Map<String, TextEditingController> inputControllers,
    String bookingId,
  ) async {
    final CollectionReference inventory =
        FirebaseFirestore.instance.collection('inventory');
    final WriteBatch batch = FirebaseFirestore.instance.batch();

    // Cache the category data for each type
    Map<String, String> categories = {};

    try {
      // Show the loading dialog
      showLoadingDialog(context);

      // Fetch user recyclables once and store category information
      QuerySnapshot userRecyclables = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .get();

      // Iterate over user documents
      for (var userDoc in userRecyclables.docs) {
        QuerySnapshot recyclablesSnapshot =
            await userDoc.reference.collection('recyclables').get();

        for (var recyclableDoc in recyclablesSnapshot.docs) {
          var recyclableData = recyclableDoc.data() as Map<String, dynamic>;
          String type =
              recyclableData['type']?.toString().toLowerCase() ?? 'unknown';
          String category =
              recyclableData['category']?.toString() ?? 'recyclables';

          // Debug print to check fetched data
          print('Fetched Type: $type, Fetched Category: $category');

          // Ensure we only set the category if it is not null or empty
          if (category.isNotEmpty && category != 'recyclables') {
            if (!categories.containsKey(type)) {
              categories[type] = category;
              print('Assigned Category for Type $type: $category');
            }
          }
        }
      }

// Log the final cached categories map
      print('Final Cached Categories Map: $categories');

      // Loop through each total weight and update the inventory
      for (var entry in totalWeights.entries) {
        String type = entry.key;
        double inputWeight =
            double.tryParse(inputControllers[type]?.text ?? '0') ?? 0;
        String category = categories[type] ??
            'unknown'; // Use the cached category or set to "unknown"

        // Log the category for debugging
        print('Type: $type, Category: $category');

        // Query to find if the inventory document for the type already exists
        QuerySnapshot inventoryDocs =
            await inventory.where('type', isEqualTo: type).limit(1).get();

        if (inventoryDocs.docs.isNotEmpty) {
          DocumentReference typeDoc = inventoryDocs.docs.first.reference;
          batch.update(typeDoc, {
            'weight': FieldValue.increment(inputWeight),
            'category': category, // Update the category as well
          });

          // Add entry to the weight history subcollection
          await typeDoc.collection('weight_history').add({
            'weight': inputWeight,
            'operation': 'add',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          DocumentReference newDocRef = inventory.doc();
          batch.set(newDocRef, {
            'category': category,
            'type': type,
            'weight': inputWeight,
          });

          // Add entry to the weight history subcollection
          await newDocRef.collection('weight_history').add({
            'weight': inputWeight,
            'operation': 'add',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      // Commit the batch write
      await batch.commit();
      print('Inventory update completed successfully.');

      // Close the loading dialog
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating inventory: $e');
      Navigator.of(context).pop();

      // Show an error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add weights to inventory: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Function to update the booking status to 'completed'
  Future<void> updateBookingStatus(String bookingId) async {
    DocumentReference bookingDoc =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    await bookingDoc.update({
      'status': 'completed',
    });
  }

  // Function to filter bookings based on search query
  bool _matchesSearchQuery(Map<String, dynamic>? data) {
    if (data == null) return false;

    String driver = (data['driver']?.toString() ?? '').toLowerCase();
    String date = data['date'] != null
        ? DateFormat('MMMM d, yyyy').format(data['date'].toDate()).toLowerCase()
        : '';
    String vehicle = (data['vehicle']?.toString() ?? '').toLowerCase();

    String normalizedQuery = searchQuery.toLowerCase();

    return driver.contains(normalizedQuery) ||
        date.contains(normalizedQuery) ||
        vehicle.contains(normalizedQuery);
  }
}

// Function to create titles for each row in the list view
Expanded title(String title, int flex) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.black),
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
