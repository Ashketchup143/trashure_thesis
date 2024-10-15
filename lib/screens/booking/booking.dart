import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:intl/intl.dart';

import 'package:trashure_thesis/sidebar.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  TextEditingController dateController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // Dropdown selections
  String? selectedDriver;
  String? selectedVehicle;

  // Checkbox states
  Map<String, bool> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    dateController.text =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
  }

  String _formatDate(DateTime date) {
    // Format date as "Month, Day, Year (Day of Week)"
    return DateFormat('MMMM d, yyyy (EEEE)').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Sidebar(),
        body: Builder(
            builder: (context) => Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 20, left: 40, right: 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.menu,
                                      color: Colors.green, size: 30),
                                  onPressed: () {
                                    Scaffold.of(context)
                                        .openDrawer(); // Opens the drawer
                                  },
                                ),
                                Text(
                                  'Booking',
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            // Add Schedule Modal Button
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
                                    controller:
                                        searchController, // Use your existing search controller
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by ID, Date, Driver, Vehicle, Status', // Adjust the hint text as needed
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value
                                            .toLowerCase(); // Update the search query
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed:
                                      _showAddScheduleModal, // Show modal
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4CAF4F),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Add Schedule',
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed:
                                      _showAssignDriverModal, // Show modal
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0062FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Assign Driver/Vehicle',
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20),
                                // Adding the search bar next to the buttons
                              ],
                            ),
                            SizedBox(height: 20),
                            // Titles Row for Schedule Info
                            Container(
                              height: MediaQuery.of(context).size.height * .8,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(border: Border.all()),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      title('Schedule ID', 3),
                                      title('Date', 3),
                                      title('Driver', 2),
                                      title('Vehicle', 2),
                                      title('Overall Price', 1),
                                      title('Overall Weight', 1),
                                      title('Status', 1),
                                      title('Details', 1),
                                    ],
                                  ),
                                  Expanded(
                                    child: Container(
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('bookings')
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          var bookings =
                                              snapshot.data?.docs ?? [];

                                          // Ensure safe handling of null data
                                          var filteredBookings =
                                              bookings.where((doc) {
                                            var data = doc.data()
                                                as Map<String, dynamic>?;
                                            return _matchesSearchQuery(
                                                data); // Safely pass data to search function
                                          }).toList();

                                          return ListView(
                                            children:
                                                filteredBookings.map((doc) {
                                              var bookingData = doc.data()
                                                  as Map<String, dynamic>;
                                              var scheduleId = doc.id;
                                              return _buildCustomCheckboxTile(
                                                  scheduleId, bookingData);
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )));
  }

  // Search bar widget
  Widget _buildSearchBar() {
    return TextFormField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by ID, Date, Driver, Vehicle, Status',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value.toLowerCase();
        });
      },
    );
  }

  // Function to check if a booking matches the search query
  bool _matchesSearchQuery(Map<String, dynamic>? data) {
    if (data == null) return false; // Handle null data

    // Handle potential null values for fields
    String id = (data['id']?.toString() ?? '').toLowerCase();
    String driver =
        (data['driver']?.toString() ?? 'no driver assigned').toLowerCase();
    String vehicle =
        (data['vehicle']?.toString() ?? 'no vehicle assigned').toLowerCase();
    String status = (data['status']?.toString() ?? '').toLowerCase();
    String date = _formatDate(data['date']?.toDate() ?? DateTime(1970))
        .toLowerCase(); // Default date if null

    // Normalize searchQuery (e.g., search for 'no driver', 'no vehicle')
    String normalizedQuery = searchQuery.toLowerCase();

    // Search logic
    return id.contains(normalizedQuery) ||
        driver.contains(normalizedQuery) ||
        vehicle.contains(normalizedQuery) ||
        status.contains(normalizedQuery) ||
        date.contains(normalizedQuery);
  }

  // Show modal for adding schedule
  void _showAddScheduleModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Select Date",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      dateController.text =
                          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addSchedule(); // Add schedule
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show modal for assigning driver and vehicle
  void _showAssignDriverModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Vehicle and Driver'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vehicle selection dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      var vehicles = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedVehicle,
                        decoration: InputDecoration(
                          labelText: 'Select Vehicle',
                          border: OutlineInputBorder(),
                        ),
                        items: vehicles.map((doc) {
                          var vehicleData = doc.data() as Map<String, dynamic>;
                          String vehicleLabel =
                              "${vehicleData['brand']} ${vehicleData['model']}";
                          return DropdownMenuItem<String>(
                            value: doc.id, // This stores vehicleId as a String
                            child: Text(vehicleLabel), // Display vehicle name
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedVehicle = newValue!;
                            _fetchMostRecentDriverForVehicle(newValue,
                                setState); // Fetch and assign the most recent driver
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  // Display the automatically assigned driver
                  if (selectedDriver != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('employees')
                          .doc(selectedDriver)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        var driverData =
                            snapshot.data?.data() as Map<String, dynamic>;
                        return Text(
                          'Assigned Driver: ${driverData['name']}',
                          style: TextStyle(fontSize: 16),
                        );
                      },
                    )
                  else
                    Text(
                      'No driver assigned yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Ensure at least one checkbox is selected
                    if (_selectedOptions.containsValue(true)) {
                      Navigator.of(context).pop();
                      _updateDriverVehicle(); // Update driver and vehicle
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Please select at least one schedule to assign.')),
                      );
                    }
                  },
                  child: Text('Assign'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Function to fetch the most recent driver for the selected vehicle
  Future<void> _fetchMostRecentDriverForVehicle(
      String vehicleId, void Function(void Function()) setState) async {
    try {
      var driversSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .collection('drivers')
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      if (driversSnapshot.docs.isNotEmpty) {
        var recentDriverData = driversSnapshot.docs.first.data();
        setState(() {
          selectedDriver = recentDriverData[
              'driverid']; // Automatically assign the most recent driverId
        });
      }
    } catch (e) {
      print('Error fetching most recent driver: $e');
    }
  }

// Function to update driver and vehicle information for selected bookings
  Future<void> _updateDriverVehicle() async {
    if (selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    if (selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'The selected vehicle has no driver assigned. Please assign a driver first.')),
      );
      return;
    }

    try {
      var selectedSchedules = _selectedOptions.keys
          .where((key) =>
              _selectedOptions[key] ==
              true) // Only select schedules where checkbox is true
          .toList();

      for (var scheduleId in selectedSchedules) {
        // Fetch vehicle and driver details from Firestore
        var vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(selectedVehicle)
            .get();
        var vehicleData = vehicleDoc.data() as Map<String, dynamic>;

        var driverDoc = await FirebaseFirestore.instance
            .collection('employees')
            .doc(selectedDriver)
            .get();
        var driverData = driverDoc.data() as Map<String, dynamic>;

        var vehicleName = "${vehicleData['brand']} ${vehicleData['model']}";
        var driverName = driverData['name'];

        // Update booking with both driver and vehicle details
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(scheduleId)
            .update({
          'vehicle': vehicleName,
          'vehicleId': selectedVehicle,
          'driver': driverName,
          'driverId': selectedDriver,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver and vehicle assigned successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign driver and vehicle: $e')),
      );
    }
  }

  // Function to add a document to Firestore (just the schedule)
  Future<void> _addSchedule() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'date': Timestamp.fromDate(selectedDate),
        'status': 'pending',
        'driver': null, // Initialize as null
        'vehicle': null, // Initialize as null
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add schedule: $e')),
      );
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

  // Function to build the custom checkbox tile
  Widget _buildCustomCheckboxTile(
      String scheduleId, Map<String, dynamic> bookingData) {
    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(scheduleId),
          ),
          Expanded(
            flex: 3,
            child: Text(
              bookingData['date'] != null
                  ? _formatDate(bookingData['date'].toDate()).toString()
                  : 'No Date',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bookingData['driver']?.toString() ?? 'No Driver Assigned',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bookingData['vehicle']?.toString() ?? 'No Vehicle Assigned',
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['overall_price'] != null
                  ? '₱${bookingData['overall_price'].toString()}' // Add the peso sign ₱
                  : '₱0', // Default to ₱0 if the price is null
              style: GoogleFonts.poppins(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['overall_weight']?.toString() ??
                  'N/A', // Added this line to display the overall price
              style: GoogleFonts.poppins(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['status']?.toString() ?? 'No Status',
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                  ),
                  IconButton(
                    icon: Icon(Icons.map), // Add the map icon
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Maps(
                                bookingId:
                                    scheduleId)), // Pushing the Maps widget
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingDetails(
                            bookingId: scheduleId,
                            bookingData: bookingData,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      value: _selectedOptions[scheduleId] ?? false,
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[scheduleId] = value ?? false;
        });
      },
      activeColor: Colors.green, // Change color to green when checked
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
