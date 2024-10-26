import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:trashure_thesis/sidebar.dart';

class CompletedBookings extends StatefulWidget {
  const CompletedBookings({super.key});

  @override
  State<CompletedBookings> createState() => _CompletedBookingsState();
}

class _CompletedBookingsState extends State<CompletedBookings> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  TextEditingController dateController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

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
                                  'Completed Bookings',
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
                                      title('Schedule ID', 2),
                                      title('Date', 4),
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
                                            .orderBy('date',
                                                descending:
                                                    false) // Order by date
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          var bookings =
                                              snapshot.data?.docs ?? [];

                                          // Filter out 'collected' and 'completed' bookings and apply search query
                                          var filteredBookings =
                                              bookings.where((doc) {
                                            var data = doc.data()
                                                as Map<String, dynamic>?;

                                            if (data == null ||
                                                data['status'] != 'completed') {
                                              return false;
                                            }

                                            return _matchesSearchQuery(data,
                                                doc.id); // Continue with other filtering if needed
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
  bool _matchesSearchQuery(Map<String, dynamic>? data, String scheduleId) {
    if (data == null) return false; // Handle null data

    // Handle potential null values for fields
    String id = scheduleId.toLowerCase();
    String driver =
        (data['driver']?.toString() ?? 'no driver assigned').toLowerCase();
    String vehicle =
        (data['vehicle']?.toString() ?? 'no vehicle assigned').toLowerCase();
    String status = (data['status']?.toString() ?? '').toLowerCase();
    String date =
        _formatDate(data['date']?.toDate() ?? DateTime(1970)).toLowerCase();
    String startTime =
        (data['start_time']?.toString() ?? 'no start time').toLowerCase();
    String endTime =
        (data['end_time']?.toString() ?? 'no end time').toLowerCase();

    // Normalize searchQuery
    String normalizedQuery = searchQuery.toLowerCase();

    // Search logic (including scheduleId, start_time, and end_time)
    return id.contains(normalizedQuery) ||
        driver.contains(normalizedQuery) ||
        vehicle.contains(normalizedQuery) ||
        status.contains(normalizedQuery) ||
        date.contains(normalizedQuery) ||
        startTime.contains(normalizedQuery) ||
        endTime.contains(normalizedQuery);
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
            flex: 2,
            child: Text(scheduleId),
          ),
          Expanded(
            flex: 4,
            child: Text(
              bookingData['date'] != null
                  ? "${_formatDate(bookingData['date'].toDate())}, "
                      "${bookingData['start_time'] ?? 'N/A'} - ${bookingData['end_time'] ?? 'N/A'}"
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
                  ? '₱${bookingData['overall_price'].toStringAsFixed(2)}' // Add the peso sign ₱
                  : '₱0', // Default to ₱0 if the price is null
              style: GoogleFonts.poppins(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['overall_weight']?.toStringAsFixed(2) ??
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
