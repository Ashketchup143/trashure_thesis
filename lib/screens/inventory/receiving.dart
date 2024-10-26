import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          height: MediaQuery.of(context).size.height,
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
                      'Receiving',
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
                SizedBox(height: 20),
                // Titles Row

                SizedBox(height: 10),
                // List of bookings with StreamBuilder inside Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: Colors.black)),
                          ),
                          child: Row(
                            children: [
                              title('Booking ID', 3),
                              title('Date', 2),
                              title('Driver', 2),
                              title('Vehicle', 2),
                            ],
                          ),
                        ),
                        Container(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .orderBy('date',
                                    descending: false) // Order by date
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
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
                                return Center(
                                    child: Text('No collected bookings found'));
                              }

                              return ListView(
                                shrinkWrap:
                                    true, // Ensure ListView doesn't overflow
                                children: collectedBookings.map((doc) {
                                  var bookingData =
                                      doc.data() as Map<String, dynamic>;
                                  var bookingId = doc.id;
                                  return _buildExpansionTile(
                                      bookingId, bookingData);
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
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

  // Function to build expansion tile with booking information and recyclables
  Widget _buildExpansionTile(
      String bookingId, Map<String, dynamic> bookingData) {
    Map<String, TextEditingController> inputControllers = {};
    Map<String, double> totalWeights = {}; // To accumulate total weights
    Map<String, double> differences = {}; // Store the difference values

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(flex: 3, child: Text('Booking ID: $bookingId')),
          Expanded(
            flex: 2,
            child: Text(
              bookingData['date'] != null
                  ? DateFormat('MMMM d, yyyy')
                      .format(bookingData['date'].toDate())
                  : 'No Date',
            ),
          ),
          Expanded(flex: 2, child: Text(bookingData['driver'] ?? 'No Driver')),
          Expanded(
            flex: 2,
            child: Text(bookingData['vehicle'] ?? 'No Vehicle'),
          ),
        ],
      ),
      children: [
        // Reset the total weights and differences when the tile is expanded
        StreamBuilder<QuerySnapshot>(
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

            // Reset totalWeights and differences here
            totalWeights.clear();
            differences.clear();

            // Fetch recyclables for each user and accumulate the weights
            List<Future<void>> userRecyclablesFutures =
                users.map((userDoc) async {
              QuerySnapshot recyclableSnapshot =
                  await userDoc.reference.collection('recyclables').get();
              var recyclables = recyclableSnapshot.docs;

              recyclables.forEach((recyclableDoc) {
                var recyclableData =
                    recyclableDoc.data() as Map<String, dynamic>;

                // Normalize type by converting to lowercase
                String type = (recyclableData['type'] ?? 'unknown')
                    .toString()
                    .toLowerCase();
                double weight =
                    (recyclableData['final_weight'] ?? 0).toDouble();

                // Accumulate weight by type
                totalWeights[type] = (totalWeights[type] ?? 0) + weight;

                // Initialize the input controller with the total weight suggestion
                inputControllers[type] = TextEditingController(
                    text: totalWeights[type]!.toStringAsFixed(1));
                differences[type] = 0; // Initialize differences
              });
            }).toList();

            // Wait for all users' recyclables to be processed
            return FutureBuilder(
              future: Future.wait(userRecyclablesFutures),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Display total weights for each type after all users have been processed
                return Column(
                  children: [
                    Column(
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
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF4F)),
                      onPressed: () {
                        // Show modal before actually transferring to the inventory
                        showInventoryTransferModal(context, totalWeights,
                            () async {
                          // The logic that transfers the weights to the inventory
                          await addWeightsToInventory(
                              totalWeights, inputControllers, bookingId);

                          // Check for significant differences and create report if necessary
                          await checkForSignificantDifferenceAndReport(
                              bookingId,
                              totalWeights,
                              inputControllers,
                              bookingData);

                          await updateBookingStatus(bookingId);
                        });
                      },
                      child: Text(
                        'Complete Booking and Add to Inventory',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                );
              },
            );
          },
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
          title: Text('Items to be Transferred to Inventory'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List the items and their respective weights
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
                onConfirm(); // Execute the action to transfer to inventory
              },
              child: Text('Confirm Transfer'),
            ),
          ],
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
      String bookingId) async {
    CollectionReference inventory =
        FirebaseFirestore.instance.collection('inventory');

    for (var entry in totalWeights.entries) {
      String type = entry.key; // Recyclable type
      double inputWeight = double.tryParse(inputControllers[type]!.text) ??
          0; // Weight input from user
      String category =
          'recyclables'; // Default category in case no category is found

      // Fetch recyclables from the user subcollection to get the category
      QuerySnapshot userRecyclables = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId) // Use the actual booking ID
          .collection('users')
          .get(); // Get all user documents in the booking

      for (var userDoc in userRecyclables.docs) {
        QuerySnapshot recyclablesSnapshot = await userDoc.reference
            .collection('recyclables')
            .where('type',
                isEqualTo:
                    type) // Filter by type to get the correct recyclables
            .limit(1) // We only need one document to get the category
            .get();

        if (recyclablesSnapshot.docs.isNotEmpty) {
          var recyclableData =
              recyclablesSnapshot.docs.first.data() as Map<String, dynamic>;
          category = recyclableData['category'] ??
              'recyclables'; // Extract the category
          break;
        }
      }

      // Check if a document for this type already exists in the inventory collection
      QuerySnapshot inventoryDocs =
          await inventory.where('type', isEqualTo: type).limit(1).get();

      if (inventoryDocs.docs.isNotEmpty) {
        // If the document exists, update the weight and add to weight_history
        DocumentReference typeDoc = inventoryDocs.docs.first.reference;

        // Update the existing weight
        await typeDoc.update({
          'weight': FieldValue.increment(
              inputWeight), // Add input weight to the existing weight
        });

        // Add entry to the weight_history subcollection
        await typeDoc.collection('weight_history').add({
          'weight': inputWeight,
          'operation': 'add',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If no document exists, create a new one with Firebase generated ID
        DocumentReference newDocRef = await inventory.add({
          'category':
              category, // Use the category from the recyclables document
          'type': type,
          'weight': inputWeight, // Set initial weight as the input weight
        });

        // Add entry to the weight_history subcollection
        await newDocRef.collection('weight_history').add({
          'weight': inputWeight,
          'operation': 'add',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
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
