import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/screens/driver/driverprofile.dart';
import 'package:trashure_thesis/user_model.dart'; // Import intl package for date formatting

class Driver extends StatefulWidget {
  const Driver({super.key});

  @override
  State<Driver> createState() => _DriverState();
}

class _DriverState extends State<Driver> {
  String name = 'Unknown Driver';
  String id = 'Unknown ID';
  bool isCollecting = false; // Flag to check if any booking is collecting

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // User is signed out, redirect to login page
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // User is signed in, fetch driver data and check status
        _fetchDriverData();
        _checkIfCollecting();
        _fetchDriverProviderData();
      }
    });
  }

  // Function to fetch the logged-in driver’s information from Firebase
  Future<void> _fetchDriverData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? 'Unknown';

      // Query Firestore to get the driver’s information based on their email
      QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('email_address', isEqualTo: email)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        var driverData =
            driverSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          name = driverData['name'] ?? 'Unknown Driver';
          id = driverSnapshot.docs.first.id; // Get the document ID
        });
      }
    }
  }

  Future<void> _fetchDriverProviderData() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Retrieve email from the authenticated user
      String email = user.email ?? 'Unknown';

      // Get the UserModel instance using Provider
      final userModel = Provider.of<UserModel>(context, listen: false);

      // If the UserModel already has the necessary data, use it directly
      if (userModel.userName.isNotEmpty && userModel.userId.isNotEmpty) {
        setState(() {
          name = userModel.userName;
          id = userModel.userId;
        });
        print('Fetched data from Provider: Name: $name, ID: $id');
        return;
      }

      // Otherwise, query Firestore to get the driver's information based on their email
      try {
        QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
            .collection('employees')
            .where('email_address', isEqualTo: email.trim())
            .get();

        if (driverSnapshot.docs.isNotEmpty) {
          var driverData =
              driverSnapshot.docs.first.data() as Map<String, dynamic>;

          // Extract driver details
          String driverName = driverData['name'] ?? 'Unknown Driver';
          String driverId = driverSnapshot.docs.first.id;
          String position = driverData['position'] ?? 'employee';

          // Update the Provider with fetched data
          userModel.setUserName(driverName);
          userModel.setUserId(driverId);
          userModel.setUserRole(position.toLowerCase());

          // Update local state with fetched data
          setState(() {
            name = driverName;
            id = driverId;
          });

          print('Fetched data from Firestore: Name: $name, ID: $id');
        } else {
          print('Driver not found in Firestore.');
        }
      } catch (e) {
        print('Error fetching driver data: $e');
      }
    } else {
      print('No authenticated user found.');
    }
  }

  // Function to check if any booking already has the status "collecting"
  Future<void> _checkIfCollecting() async {
    QuerySnapshot collectingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: id)
        .where('status', isEqualTo: 'collecting')
        .get();

    setState(() {
      isCollecting = collectingSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _logout() async {
    try {
      // Clear the user data in UserModel
      Provider.of<UserModel>(context, listen: false).clearUserData();
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      // await Future.delayed(Duration(milliseconds: 500)); // Add a brief delay
      Navigator.pushReplacementNamed(context, '/'); // Navigate to login page
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  // Function to format Firestore Timestamp to "MM/dd/yyyy, DayOfWeek"
  String formatDate(Timestamp timestamp) {
    DateTime date =
        timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateFormat formatter = DateFormat('MM/dd/yyyy'); // Define desired format
    String dayOfWeek =
        DateFormat('EEEE').format(date); // Get day of the week (e.g., Monday)
    return '${formatter.format(date)}, $dayOfWeek'; // Return formatted date and day of the week
  }

  // Function to update the status of the booking
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus}); // Update status to the new value
    _checkIfCollecting(); // Recheck if a booking is set to "collecting"
  }

  // Function to show a confirmation modal before changing status to "collecting"
  Future<void> _showCollectConfirmation(String bookingId) async {
    TextEditingController mileageController = TextEditingController();

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Collect Recyclables'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you going to collect the recyclables for this booking?'),
              const SizedBox(height: 16),
              // Starting Mileage Input Field
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Starting Mileage',
                  border: OutlineInputBorder(),
                ),
              ),
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

    // Check if the user confirmed and provided a mileage value
    if (confirmed == true && mileageController.text.isNotEmpty) {
      double? startingMileage = double.tryParse(mileageController.text);

      if (startingMileage != null) {
        await _updateBookingStatusWithMileage(
            bookingId, 'collecting', startingMileage);
      } else {
        // Show error if mileage input is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Invalid mileage input. Please enter a valid number.')),
        );
      }
    }
  }

  Future<void> _updateBookingStatusWithMileage(
      String bookingId, String newStatus, double startingMileage) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': newStatus,
        'starting_mileage': startingMileage,
      });
      _checkIfCollecting(); // Recheck if a booking is set to "collecting"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Booking updated successfully with starting mileage.')),
      );
    } catch (e) {
      print('Error updating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking. Please try again.')),
      );
    }
  }

  // Function to show a modal when a booking is already in progress
  void _showErrorModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking in Progress'),
          content: Text('You still have a booking in progress.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the modal
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: _logout, // Call the logout function
            ),
            Text(
              "Booking",
              style: TextStyle(color: Colors.white),
            ), // Display the driver's name in the app bar
          ],
        ),
        actions: [
          // Add the transaction icon on the right
          IconButton(
            icon: Icon(
              Icons
                  .receipt_long, // Icon representing transactions (receipt icon)
              color: Colors.white,
            ),
            onPressed: () {
              // Navigate to the transaction screen or perform any action
              Navigator.pushNamed(context, '/drivertransactions');
            },
          ),

          IconButton(
            icon: Icon(
              Icons.account_circle, // Profile icon
              color: Colors.white,
              size: 30, // Set icon size
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen()),
              ); // Navigate to profile screen
            },
          ),
        ],
      ),
      body: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            height: MediaQuery.of(context).size.height * .90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.white, // Background color of the inner container
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to the left
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Driver: $name', // Header for Booking data
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Driver ID: $id', // Display the driver's ID
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('driverId', isEqualTo: id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No bookings found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      // Filter bookings for 'pending' and 'collecting' statuses
                      var bookings = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        var status =
                            (data['status'] ?? '').toString().toLowerCase();
                        var overallWeight = (data['overall_weight'] is num)
                            ? data['overall_weight']
                            : 0.0;

                        // Only include bookings with status 'pending' or 'collecting' and weight > 0
                        return (status == 'pending' ||
                                status == 'collecting') &&
                            overallWeight > 0;
                      }).toList();

                      if (bookings.isEmpty) {
                        return const Center(
                          child: Text(
                            'No bookings match the criteria.',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var bookingData =
                              bookings[index].data() as Map<String, dynamic>;
                          var bookingId = bookings[index].id;
                          var bookingDate = bookingData['date'] as Timestamp;
                          var bookingStatus =
                              bookingData['status'] ?? 'Unknown';
                          var overallPrice =
                              (bookingData['overall_price'] is num)
                                  ? bookingData['overall_price']
                                  : 0.0;
                          var overallWeight =
                              (bookingData['overall_weight'] is num)
                                  ? bookingData['overall_weight']
                                  : 0.0;
                          var location = bookingData['location'] ?? null;
                          var calculatedPrice =
                              bookingData['calculated_overall_price'] ??
                                  'Not set';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date: ${formatDate(bookingDate)}, ${bookingData['start_time'] ?? 'N/A'} - ${bookingData['end_time'] ?? 'N/A'}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Location: $location'),
                                        Text('Booking ID: $bookingId'),
                                        Text('Status: $bookingStatus'),
                                        Text(
                                            'Vehicle: ${bookingData['vehicle']}'),
                                        Text(
                                            'Vehicle ID: ${bookingData['vehicleId']}'),
                                        Text(
                                          'Est. Calculated Price: ₱${(calculatedPrice is num ? calculatedPrice : 0.0).toStringAsFixed(2)}',
                                        ),
                                        // Text(
                                        //     'Overall Price: ₱${overallPrice.toStringAsFixed(2)}'),
                                        Text(
                                          'Est. Overall Weight: ${overallWeight.toStringAsFixed(2)} kg',
                                        ),

                                        if (bookingData
                                            .containsKey('starting_mileage'))
                                          Text(
                                              'Starting Mileage: ${bookingData['starting_mileage']} km'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/driverbookingdetails',
                                              arguments: {
                                                'bookingId': bookingId,
                                                'status': bookingData['status'],
                                                'location':
                                                    bookingData['location'],
                                                'vehicle':
                                                    bookingData['vehicle'],
                                                'vehicleId':
                                                    bookingData['vehicleId'],
                                                'overall_price': bookingData[
                                                    'overall_price'],
                                                'overall_weight': bookingData[
                                                    'overall_weight'],
                                                'date': bookingData['date'],
                                                'start_time':
                                                    bookingData['start_time'] ??
                                                        'N/A',
                                                'end_time':
                                                    bookingData['end_time'] ??
                                                        'N/A',
                                              },
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 50),
                                        if (bookingStatus != 'collecting')
                                          ElevatedButton(
                                            onPressed: isCollecting ||
                                                    !_isSameDate(
                                                        bookingData['date'])
                                                ? null // Disable button if already collecting or date doesn't match
                                                : () {
                                                    _showCollectConfirmation(
                                                        bookingId);
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              minimumSize: const Size(80, 30),
                                            ),
                                            child: const Text(
                                              'Collect',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                          )
                                        else
                                          Column(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await _updateBookingStatus(
                                                      bookingId, 'pending');
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  minimumSize:
                                                      const Size(80, 30),
                                                ),
                                                child: const Text(
                                                  'Revert',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Collecting',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

  bool _isSameDate(Timestamp timestamp) {
    DateTime bookingDate =
        timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateTime currentDate = DateTime.now();

    // Compare year, month, and day
    return bookingDate.year == currentDate.year &&
        bookingDate.month == currentDate.month &&
        bookingDate.day == currentDate.day;
  }
}
