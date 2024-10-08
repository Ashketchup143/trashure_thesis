import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart'; // Add this import to use the DateFormat class

class EmployeeProfileScreen extends StatefulWidget {
  @override
  _EmployeeProfileScreenState createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _salaryController;
  late TextEditingController _expTimeInController;
  late TextEditingController _expTimeOutController;

  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? employee;
  Map<String, dynamic>? originalEmployeeData;

  // Lists for daily time records and bookings
  List<Map<String, dynamic>> _dailyTimeRecords = [];
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _positionController = TextEditingController();
    _addressController = TextEditingController();
    _birthDateController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _salaryController = TextEditingController();
    _expTimeInController = TextEditingController();
    _expTimeOutController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (employee == null) {
      employee =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (employee != null) {
        // Save the original data for comparison
        originalEmployeeData = Map<String, dynamic>.from(employee!);

        // Set initial values of the controllers with the employee data
        _nameController.text = employee!['name'] ?? '';
        _positionController.text = employee!['position'] ?? '';
        _addressController.text = employee!['address'] ?? '';
        _birthDateController.text = employee!['birth_date'] ?? '';
        _contactController.text = employee!['contact_number'] ?? '';
        _emailController.text = employee!['email_address'] ?? '';
        _salaryController.text = employee!['salary_per_hour'] ?? '';
        _expTimeInController.text = employee!['exp_time_in'] ?? '';
        _expTimeOutController.text = employee!['exp_time_out'] ?? '';

        // Fetch daily time records for all employees
        _fetchDailyTimeRecords(employee!['id']);

        // If the employee is a driver, fetch bookings
        if (employee!['position'] == 'Driver') {
          _fetchDriverBookings(employee!['id']);
        }
      }
    }
  }

  // Helper function to format date
  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM d, yyyy')
        .format(dateTime); // Month Date, Year format
  }

// Helper function to format day of the week
  String formatDayOfWeek(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('EEEE').format(dateTime); // Monday, Tuesday, etc.
  }

// Helper function to format time (Time In/Out)
  String formatTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('h:mm a').format(dateTime); // 12:30 PM format
  }

  // Fetch daily time records from the 'daily_time_record' subcollection
  Future<void> _fetchDailyTimeRecords(String employeeId) async {
    try {
      CollectionReference timeRecordsRef = FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record');

      QuerySnapshot snapshot = await timeRecordsRef.get();

      // If subcollection has no documents, handle it gracefully
      if (snapshot.docs.isEmpty) {
        setState(() {
          _dailyTimeRecords = [];
        });
        return;
      }

      // If subcollection exists and has documents, map them to the list
      List<Map<String, dynamic>> timeRecords = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      setState(() {
        _dailyTimeRecords = timeRecords;
      });
    } catch (e) {
      print("Error fetching daily time records: $e");
      setState(() {
        _dailyTimeRecords = [];
      });
    }
  }

  // Fetch bookings where the driver is assigned
  Future<void> _fetchDriverBookings(String driverId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: driverId)
        .get();

    List<Map<String, dynamic>> bookings = snapshot.docs.map((doc) {
      // Use doc.id to get the document ID (this will be used as booking_id)
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['booking_id'] = doc.id; // Assign the document ID as booking_id
      return data;
    }).toList();

    setState(() {
      _bookings = bookings;
    });
  }

  // Toggle the edit mode
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Compare values to determine if data has changed
  bool _hasChanged() {
    return _nameController.text != originalEmployeeData!['name'] ||
        _positionController.text != originalEmployeeData!['position'] ||
        _addressController.text != originalEmployeeData!['address'] ||
        _birthDateController.text != originalEmployeeData!['birth_date'] ||
        _contactController.text != originalEmployeeData!['contact_number'] ||
        _emailController.text != originalEmployeeData!['email_address'] ||
        _salaryController.text != originalEmployeeData!['salary_per_hour'] ||
        _expTimeInController.text != originalEmployeeData!['exp_time_in'] ||
        _expTimeOutController.text != originalEmployeeData!['exp_time_out'];
  }

  // Save updated employee information to Firestore if data has changed
  void _saveChanges(String employeeId) async {
    if (!_hasChanged()) {
      _showDialog('No changes', 'No information has been changed.');
      _isEditing = false;
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .update({
        'name': _nameController.text,
        'position': _positionController.text,
        'address': _addressController.text,
        'birth_date': _birthDateController.text,
        'contact_number': _contactController.text,
        'email_address': _emailController.text,
        'salary_per_hour': _salaryController.text,
        'exp_time_in': _expTimeInController.text,
        'exp_time_out': _expTimeOutController.text,
      });

      _showDialog('Success', 'Employee information has been updated.');
      setState(() {
        _isEditing = false;
        originalEmployeeData = {
          'name': _nameController.text,
          'position': _positionController.text,
          'address': _addressController.text,
          'birth_date': _birthDateController.text,
          'contact_number': _contactController.text,
          'email_address': _emailController.text,
          'salary_per_hour': _salaryController.text,
          'exp_time_in': _expTimeInController.text,
          'exp_time_out': _expTimeOutController.text,
        };
      });
    } catch (e) {
      _showDialog('Error', 'Failed to update employee information.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Display dialog
  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Employee Profile',
          style: GoogleFonts.poppins(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.green,
        actions: [
          if (employee != null)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirmation'),
                          content: Text(
                              'Are you sure you want to set this employee to inactive?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: Text('Yes'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(employee!['id'])
                          .update({'status': 'inactive'});

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Employee status updated to inactive'),
                      ));
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditing && employee != null) {
                      _saveChanges(employee!['id']);
                    } else {
                      _toggleEdit();
                    }
                  },
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (employee != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileField('Employee ID', employee!['id'],
                              isEditable: false),
                          SizedBox(height: 16),
                          _buildProfileField('Name', _nameController.text,
                              controller: _nameController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Position', _positionController.text,
                              controller: _positionController),
                          SizedBox(height: 16),
                          _buildProfileField('Address', _addressController.text,
                              controller: _addressController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Birth Date', _birthDateController.text,
                              controller: _birthDateController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Contact Number', _contactController.text,
                              controller: _contactController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Email Address', _emailController.text,
                              controller: _emailController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Salary Per Hour', _salaryController.text,
                              controller: _salaryController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Expected Time In', _expTimeInController.text,
                              controller: _expTimeInController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Expected Time Out', _expTimeOutController.text,
                              controller: _expTimeOutController),
                        ],
                      ),
                    SizedBox(height: 16),

                    // Display Daily Time Records for all employees
                    Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Time Records',
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          _dailyTimeRecords.isNotEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _dailyTimeRecords.length,
                                  itemBuilder: (context, index) {
                                    final record = _dailyTimeRecords[index];

                                    // Fetch the date, time_in, and time_out as Timestamp
                                    Timestamp dateTimestamp =
                                        record['date'] ?? Timestamp.now();
                                    Timestamp timeInTimestamp =
                                        record['time_in'] ?? Timestamp.now();
                                    Timestamp timeOutTimestamp =
                                        record['time_out'] ?? Timestamp.now();

                                    return ListTile(
                                      title: Text(
                                        "Date: ${formatDate(dateTimestamp)} (${formatDayOfWeek(dateTimestamp)})", // Month Date, Year (Day)
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        "Time In: ${formatTime(timeInTimestamp)}, Time Out: ${formatTime(timeOutTimestamp)}", // HH:MM AM/PM
                                      ),
                                    );
                                  },
                                )
                              : Text('No time records available'),
                          SizedBox(height: 16),

                          // Only display bookings if the employee is a driver
                          if (employee!['position'] == 'Driver')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Bookings',
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                                // Inside your ListView for Driver's Bookings
                                _bookings.isNotEmpty
                                    ? ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: _bookings.length,
                                        itemBuilder: (context, index) {
                                          final booking = _bookings[index];

                                          // Store bookingData in a map to pass to the BookingDetails page
                                          Map<String, dynamic> bookingData = {
                                            'booking_id':
                                                booking['booking_id'] ??
                                                    'No Booking ID',
                                            'vehicle': booking['vehicle'] ??
                                                'No Vehicle',
                                            'overall_price':
                                                booking['overall_price'] ?? 0.0,
                                            'overall_weight':
                                                booking['overall_weight'] ??
                                                    0.0,
                                            'date': booking['date'] ??
                                                Timestamp.now(),
                                            'status': booking['status'] ??
                                                'No Status',
                                          };

                                          String bookingId = booking[
                                                  'booking_id'] ??
                                              'No Booking ID'; // Use document ID
                                          String vehicle = booking['vehicle'] ??
                                              'No Vehicle'; // Vehicle
                                          double overallPrice =
                                              booking['overall_price'] ??
                                                  0.0; // Overall Price
                                          double overallWeight =
                                              booking['overall_weight'] ??
                                                  0.0; // Overall Weight
                                          Timestamp dateTimestamp = booking[
                                                  'date'] ??
                                              Timestamp.now(); // Booking Date
                                          String status = booking['status'] ??
                                              'No Status'; // Booking Status

                                          return ListTile(
                                            title: Text(
                                              "Booking ID: $bookingId",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    "Date: ${formatDate(dateTimestamp)} (${formatDayOfWeek(dateTimestamp)})"), // Date and Day of Week
                                                Text(
                                                    "Vehicle: $vehicle"), // Vehicle
                                                Text(
                                                    "Overall Price: ₱${overallPrice.toStringAsFixed(2)}"), // Overall Price with formatting
                                                Text(
                                                    "Overall Weight: ${overallWeight.toStringAsFixed(2)} kg"), // Overall Weight
                                                Text(
                                                    "Status: $status"), // Status
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.info_outline),
                                              onPressed: () {
                                                // Navigate to BookingDetails with bookingId and bookingData
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookingDetails(
                                                      bookingId: bookingId,
                                                      bookingData: bookingData,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      )
                                    : Text('No bookings available'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget to build each profile field with optional editing
  Widget _buildProfileField(String fieldName, String fieldValue,
      {TextEditingController? controller, bool isEditable = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$fieldName:',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _isEditing && isEditable
              ? TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
              : Text(
                  fieldValue,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
