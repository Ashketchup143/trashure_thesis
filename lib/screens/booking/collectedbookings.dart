import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:trashure_thesis/sidebar.dart';

class CollectedBookings extends StatefulWidget {
  const CollectedBookings({super.key});

  @override
  State<CollectedBookings> createState() => _CollectedBookingsState();
}

class _CollectedBookingsState extends State<CollectedBookings> {
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
      drawer: const Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu,
                            color: Colors.green, size: 30),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      Text(
                        'Collected Bookings',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                          decoration: const InputDecoration(
                            hintText:
                                'Search by ID, Date, Driver, Vehicle, Status',
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
                  const SizedBox(height: 20),
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
                            title('Location', 1),
                            title('Driver', 2),
                            title('Vehicle', 2),
                            title('OA. Price', 1),
                            title('OA. Weight', 1),
                            title('Status', 1),
                            title('Details', 1),
                          ],
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('status', isEqualTo: 'collected')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              // Retrieve documents and convert to list
                              var bookings = snapshot.data?.docs ?? [];

                              // Sort bookings by date manually
                              bookings.sort((a, b) {
                                DateTime dateA =
                                    (a['date'] as Timestamp).toDate();
                                DateTime dateB =
                                    (b['date'] as Timestamp).toDate();
                                return dateA
                                    .compareTo(dateB); // Ascending order
                              });

                              // Filter bookings based on search query
                              var filteredBookings = bookings.where((doc) {
                                var data = doc.data() as Map<String, dynamic>?;
                                return _matchesSearchQuery(data, doc.id);
                              }).toList();

                              // Display sorted and filtered bookings
                              return ListView(
                                children: filteredBookings.map((doc) {
                                  var bookingData =
                                      doc.data() as Map<String, dynamic>;
                                  var scheduleId = doc.id;
                                  return _buildCustomCheckboxTile(
                                      scheduleId, bookingData);
                                }).toList(),
                              );
                            },
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
      ),
    );
  }

  // Function to check if a booking matches the search query
  bool _matchesSearchQuery(Map<String, dynamic>? data, String scheduleId) {
    if (data == null) return false;

    String location =
        (data['location']?.toString() ?? 'no location assigned').toLowerCase();
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

    String normalizedQuery = searchQuery.toLowerCase();

    return id.contains(normalizedQuery) ||
        driver.contains(normalizedQuery) ||
        vehicle.contains(normalizedQuery) ||
        status.contains(normalizedQuery) ||
        date.contains(normalizedQuery) ||
        startTime.contains(normalizedQuery) ||
        endTime.contains(normalizedQuery) ||
        location.contains(normalizedQuery);
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckboxTile(
      String scheduleId, Map<String, dynamic> bookingData) {
    return ListTile(
      leading: Checkbox(
        value: _selectedOptions[scheduleId] ?? false,
        onChanged: (bool? value) {
          setState(() {
            _selectedOptions[scheduleId] = value ?? false;
          });
        },
        activeColor: Colors.green,
      ),
      title: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(scheduleId, style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 4,
            child: Text(
              bookingData['date'] != null
                  ? "${_formatDate(bookingData['date'].toDate())}, "
                      "${bookingData['start_time'] ?? 'N/A'} - ${bookingData['end_time'] ?? 'N/A'}"
                  : 'No Date',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['location']?.toString() ?? 'No Location',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bookingData['driver']?.toString() ?? 'No Driver Assigned',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bookingData['vehicle']?.toString() ?? 'No Vehicle Assigned',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['overall_price'] != null
                  ? '₱${bookingData['overall_price'].toStringAsFixed(2)}'
                  : '₱0',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['overall_weight'] != null
                  ? '${bookingData['overall_weight'].toStringAsFixed(2)} kg'
                  : 'N/A',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              bookingData['status']?.toString() ?? 'No Status',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.map, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Maps(bookingId: scheduleId),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
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
        ],
      ),
    );
  }
}
