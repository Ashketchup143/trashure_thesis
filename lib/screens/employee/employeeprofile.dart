import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _salaryController;
  late TextEditingController _expTimeInController;
  late TextEditingController _expTimeOutController;
  Uint8List? _imageBytes;
  String? _imageFileName;

  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? employee;
  Map<String, dynamic>? originalEmployeeData;

  // Lists for daily time records and bookings
  List<Map<String, dynamic>> _dailyTimeRecords = [];
  List<Map<String, dynamic>> _bookings = [];

  List<String> _positionsList = [];
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _birthDateController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _salaryController = TextEditingController();
    _expTimeInController = TextEditingController();
    _expTimeOutController = TextEditingController();
    // Fetch positions list
    _fetchPositions();
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
        _selectedPosition ??= employee!['position'];
        _addressController.text = employee!['address'] ?? '';
        _birthDateController.text = employee!['birth_date'] ?? '';
        _contactController.text = employee!['contact_number'] ?? '';
        _emailController.text = employee!['email_address'] ?? '';
        _salaryController.text = employee!['salary_per_day'].toString() ?? '';
        _expTimeInController.text = employee!['exp_time_in'] ?? '';
        _expTimeOutController.text = employee!['exp_time_out'] ?? '';

        // Fetch daily time records for all employees
        _fetchDailyTimeRecords(employee!['id']);

        // If the employee is a driver, fetch bookings
        if (employee!['position'].toLowerCase() == 'driver' ||
            employee!['position'].toLowerCase() == 'contractual driver') {
          _fetchDriverBookings(employee!['id']);
        }
      }
    }
  }

  Future<void> _fetchPositions() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('positions').get();

      List<String> tempPositionsList = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        tempPositionsList.add(data['position_name']);
      }

      setState(() {
        _positionsList = tempPositionsList;
        // Set the selected position if not already set
      });
    } catch (e) {
      print('Error fetching positions: $e');
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

      // Sort time records by date in descending order (hard-coded)
      timeRecords.sort((a, b) {
        Timestamp dateA = a['date'] ?? Timestamp.now();
        Timestamp dateB = b['date'] ?? Timestamp.now();
        return dateB.compareTo(dateA);
      });

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

    // Sort bookings by date in descending order (hard-coded)
    bookings.sort((a, b) {
      Timestamp dateA = a['date'] ?? Timestamp.now();
      Timestamp dateB = b['date'] ?? Timestamp.now();
      return dateB.compareTo(dateA);
    });

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
        _addressController.text != originalEmployeeData!['address'] ||
        _birthDateController.text != originalEmployeeData!['birth_date'] ||
        _contactController.text != originalEmployeeData!['contact_number'] ||
        _emailController.text != originalEmployeeData!['email_address'] ||
        _salaryController.text != originalEmployeeData!['salary_per_day'] ||
        _expTimeInController.text != originalEmployeeData!['exp_time_in'] ||
        _expTimeOutController.text != originalEmployeeData!['exp_time_out'];
  }

  // Save updated employee information to Firestore if data has changed
  void _saveChanges(String employeeId) async {
    if (!_hasChanged()) {
      _showDialog('No changes', 'No information has been changed.');
      setState(() {
        _isEditing = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the data for update
      Map<String, dynamic> updatedData = {
        'name': _nameController.text,
        'position': _selectedPosition,
        'address': _addressController.text,
        'birth_date': _birthDateController.text,
        'contact_number': _contactController.text,
        'email_address': _emailController.text,
        'salary_per_day': _salaryController.text,
        'exp_time_in': _expTimeInController.text,
        'exp_time_out': _expTimeOutController.text,
      };

      // Update image if it has been changed
      if (_imageBytes != null && _imageFileName != null) {
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('employee_images/$_imageFileName');
        await storageReference.putData(_imageBytes!);
        updatedData['image'] = _imageFileName;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .update(updatedData);

      _showDialog('Success', 'Employee information has been updated.');
      setState(() {
        _isEditing = false;
        originalEmployeeData = Map<String, dynamic>.from(updatedData);
        _imageBytes = null; // Reset image data after update
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
            style:
                GoogleFonts.poppins(textStyle: TextStyle(color: Colors.white)),
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
                  IconButton(
                    icon: Icon(Icons.bar_chart, color: Colors.white),
                    onPressed: () {
                      // Add your report generation or navigation logic here
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
                              // Display Employee Image
                              if (_imageBytes != null)
                                ClipOval(
                                  child: Image.memory(
                                    _imageBytes!,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (employee != null &&
                                  employee!['imageUrl'] != null &&
                                  employee!['imageUrl'].isNotEmpty)
                                ClipOval(
                                  child: Image.network(
                                    employee!['imageUrl'],
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 150);
                                    },
                                  ),
                                )
                              else
                                const Center(
                                  child: Icon(Icons.person, size: 150),
                                ),
                              const SizedBox(height: 16),

                              // Add the button conditionally when editing
                              if (_isEditing)
                                ElevatedButton(
                                  onPressed: _pickImage,
                                  child: const Text('Change Profile Picture'),
                                ),

                              SizedBox(height: 16),

                              _buildProfileField('Employee ID', employee!['id'],
                                  isEditable: false),
                              SizedBox(height: 16),
                              _buildProfileField('Name', _nameController.text,
                                  controller: _nameController),
                              SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Position:',
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
                                    child: _isEditing
                                        ? DropdownButtonFormField<String>(
                                            value: _selectedPosition,
                                            items:
                                                _positionsList.map((position) {
                                              return DropdownMenuItem<String>(
                                                value: position,
                                                child: Text(position),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedPosition = value!;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                          )
                                        : Text(
                                            _selectedPosition ?? '',
                                            style: GoogleFonts.poppins(
                                              textStyle:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),
                              _buildProfileField(
                                  'Address', _addressController.text,
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
                                  controller: _emailController,
                                  isEditable: false),

                              SizedBox(height: 16),
                              _buildProfileField(
                                  'Salary Per Hour', _salaryController.text,
                                  controller: _salaryController),
                              SizedBox(height: 16),
                              _buildProfileField(
                                  'Expected Time In', _expTimeInController.text,
                                  controller: _expTimeInController),
                              SizedBox(height: 16),
                              _buildProfileField('Expected Time Out',
                                  _expTimeOutController.text,
                                  controller: _expTimeOutController),
                            ],
                          ),
                        SizedBox(height: 16),

                        // Display Daily Time Records for all employees
                        if (_dailyTimeRecords.isNotEmpty)
                          Container(
                            height: MediaQuery.of(context).size.height * .3,
                            decoration: BoxDecoration(border: Border.all()),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Time Records',
                                  style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: ListView.builder(
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
                                          "Date: ${formatDate(dateTimestamp)} (${formatDayOfWeek(dateTimestamp)})",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          "Time In: ${formatTime(timeInTimestamp)}, Time Out: ${formatTime(timeOutTimestamp)}",
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 20,
                        ),
                        if (_bookings.isNotEmpty &&
                            (employee!['position'].toLowerCase() == 'driver' ||
                                employee!['position'].toLowerCase() ==
                                    'contractual driver'))
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey)),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigned Bookings',
                                    style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                      child: ListView.builder(
                                    itemCount: _bookings.length,
                                    itemBuilder: (context, index) {
                                      final booking = _bookings[index];

                                      // Use final values if available, fallback to the default values otherwise
                                      String bookingId =
                                          booking['booking_id'] ??
                                              'No Booking ID';
                                      String vehicle =
                                          booking['vehicle'] ?? 'No Vehicle';
                                      double calculatedOverallPrice = booking[
                                              'final_calculated_overall_price'] ??
                                          booking['calculated_overall_price'] ??
                                          0.0; // Fallback to `calculated_overall_price` if final is not available
                                      double overallWeight = booking[
                                              'final_overall_weight'] ??
                                          booking['overall_weight'] ??
                                          0.0; // Fallback to `overall_weight` if final is not available

                                      String status =
                                          booking['status'] ?? 'No Status';

                                      return ListTile(
                                        title: Text(
                                          "Booking ID: $bookingId",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("Vehicle: $vehicle"),
                                            Text(
                                                "Calculated Price: ₱${calculatedOverallPrice.toStringAsFixed(2)}"),
                                            Text(
                                                "Overall Weight: ${overallWeight.toStringAsFixed(2)} kg"),
                                            Text("Status: $status"),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BookingDetails(
                                                  bookingId: bookingId,
                                                  bookingData: booking,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ),
                      ]),
                )));
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

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }
}
