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
                // Container with border wrapping the entire list of bookings
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .orderBy('date', descending: false) // Order by date
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        var bookings = snapshot.data?.docs ?? [];

                        // Filter bookings to include only 'collected' status
                        var collectedBookings = bookings.where((doc) {
                          var data = doc.data() as Map<String, dynamic>?;
                          return data?['status'] == 'collected' &&
                              _matchesSearchQuery(data);
                        }).toList();

                        if (collectedBookings.isEmpty) {
                          return Center(child: Text('No bookings found'));
                        }

                        return ListView(
                          shrinkWrap: true, // Ensure ListView doesn't overflow
                          children: collectedBookings.map((doc) {
                            var bookingData =
                                doc.data() as Map<String, dynamic>;
                            var bookingId = doc.id;
                            return _buildExpansionTile(bookingId, bookingData);
                          }).toList(),
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
              flex: 2, child: Text(bookingData['vehicle'] ?? 'No Vehicle')),
        ],
      ),
      children: [
        // Fetch and display users' recyclables within this booking
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

            // Fetch recyclables for each user and accumulate the weights
            List<Future<void>> userRecyclablesFutures =
                users.map((userDoc) async {
              QuerySnapshot recyclableSnapshot =
                  await userDoc.reference.collection('recyclables').get();
              var recyclables = recyclableSnapshot.docs;

              // Calculate total weight for each recyclable type (case-insensitive)
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
                      onPressed: () async {
                        // Add inputted weights to inventory and update booking status
                        await addWeightsToInventory(totalWeights,
                            inputControllers, bookingId); // Pass bookingId here
                        await updateBookingStatus(bookingId);
                      },
                      child: Text('Complete Booking and Add to Inventory'),
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

  // Function to add inputted weights of all recyclables to inventory
  Future<void> addWeightsToInventory(
      Map<String, double> totalWeights,
      Map<String, TextEditingController> inputControllers,
      String bookingId) async {
    // Pass the booking ID as a parameter

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

      // Loop through each user document and get the recyclables subcollection
      for (var userDoc in userRecyclables.docs) {
        QuerySnapshot recyclablesSnapshot = await userDoc.reference
            .collection('recyclables')
            .where('type',
                isEqualTo:
                    type) // Filter by type to get the correct recyclables
            .limit(1) // We only need one document to get the category
            .get();

        if (recyclablesSnapshot.docs.isNotEmpty) {
          // Get the category from the recyclables document
          var recyclableData =
              recyclablesSnapshot.docs.first.data() as Map<String, dynamic>;
          category = recyclableData['category'] ??
              'recyclables'; // Extract the category
          break; // Exit the loop once we get the category
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
