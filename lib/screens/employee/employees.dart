import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  Map<String, bool> _selectedOptions = {};
  Map<String, bool> _attendanceStatus = {};
  List<Map<String, dynamic>> _employeesList = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  TextEditingController _searchController = TextEditingController();
  Map<String, bool> _paymentStatus = {};
  List<String> _positionsList = [];
  String? _selectedPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchPositions();
    _searchController.addListener(_onSearchChanged);
  }

// Method to fetch positions from the 'positions' collection
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
      });
    } catch (e) {
      print('Error fetching positions: $e');
    }
  }

  void _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('employees')
        .where('status', isEqualTo: 'active')
        .get();

    List<Map<String, dynamic>> tempEmployeesList = [];

    for (var doc in snapshot.docs) {
      var employeeData = doc.data() as Map<String, dynamic>;
      String imageFileName = employeeData['image'] ?? '';
      String? imageUrl;

      if (imageFileName.isNotEmpty) {
        try {
          Reference ref =
              FirebaseStorage.instance.ref('employee_images/$imageFileName');
          imageUrl =
              await ref.getDownloadURL(); // Directly get the download URL
        } catch (e) {
          print('Error fetching image URL: $e');
          imageUrl = null; // Set to null if file not found or any error occurs
        }
      }

      tempEmployeesList.add({
        'id': doc.id,
        'name': employeeData['name'],
        'position': employeeData['position'],
        'exp_time_in': employeeData['exp_time_in'],
        'exp_time_out': employeeData['exp_time_out'],
        'address': employeeData['address'],
        'birth_date': employeeData['birth_date'],
        'contact_number': employeeData['contact_number'],
        'email_address': employeeData['email_address'],
        'salary_per_day': double.parse(employeeData['salary_per_day']),
        'imageUrl': imageUrl,
      });
    }

    Map<String, bool> tempAttendanceStatus = {};
    Map<String, bool> tempSelectedOptions = {};
    Map<String, bool> tempPaymentStatus = {};

    for (var employee in tempEmployeesList) {
      String employeeId = employee['id'];
      tempSelectedOptions[employeeId] = false;
      bool isClockedIn = await _checkIfClockedIn(employeeId);
      tempAttendanceStatus[employeeId] = isClockedIn;

      // Check if the employee has already been paid for the day
      bool alreadyPaid = await _checkIfAlreadyPaid(employeeId);
      tempPaymentStatus[employeeId] = alreadyPaid;
    }

    setState(() {
      _employeesList = tempEmployeesList;
      _filteredEmployees = _employeesList;
      _attendanceStatus = tempAttendanceStatus;
      _selectedOptions = tempSelectedOptions;
      _paymentStatus = tempPaymentStatus;
      _isLoading = false;
    });
  }

  Future<bool> _checkIfAlreadyPaid(String employeeId) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot dtrSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time_in', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Check if any of the fetched records have the "paid" status
      for (var doc in dtrSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'paid') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking payment status for $employeeId: $e');
      return false;
    }
  }

  Future<bool> _checkIfClockedIn(String employeeId) async {
    try {
      DocumentReference employeeDocRef =
          FirebaseFirestore.instance.collection('employees').doc(employeeId);
      QuerySnapshot dtrSnapshot = await employeeDocRef
          .collection('daily_time_record')
          .where('time_out', isNull: true)
          .get();

      if (dtrSnapshot.docs.isNotEmpty) {
        var dtrData = dtrSnapshot.docs.first.data() as Map<String, dynamic>;
        // Check if the status is already "paid"
        if (dtrData['status'] == 'paid') {
          return false; // Already paid, so no clock-in status
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking attendance status for $employeeId: $e');
      return false;
    }
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employeesList.where((employee) {
        return employee['name'].toLowerCase().contains(searchTerm) ||
            employee['position'].toLowerCase().contains(searchTerm) ||
            employee['id'].toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _timeIn(String employeeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .add({
        'date': DateTime.now(),
        'time_in': FieldValue.serverTimestamp(),
        'time_out': null,
      });
    } catch (e) {
      print('Error during Time In: $e');
    }
  }

  Future<void> _timeOut(
      String employeeId, String employeeName, double salaryPerDay) async {
    try {
      QuerySnapshot dtrSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_out', isNull: true)
          .get();

      if (dtrSnapshot.docs.isNotEmpty) {
        DocumentReference dtrDocRef = dtrSnapshot.docs.first.reference;
        await dtrDocRef.update({
          'time_out': FieldValue.serverTimestamp(),
        });

        // Calculate pay after setting time_out
        // _calculateAndShowDailyPay(employeeId, employeeName, salaryPerDay);
      }
    } catch (e) {
      print('Error during Time Out: $e');
    }
  }

  Future<void> _calculateAndShowDailyPay(
      String employeeId, String employeeName, double salaryPerDay) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time_in', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (attendanceSnapshot.docs.isEmpty) {
        _showPayModal(
            context, employeeId, employeeName, 0.0, salaryPerDay, 0.0);
        return;
      }

      // Check if any record already has status "paid"
      for (var attendanceDoc in attendanceSnapshot.docs) {
        var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        if (attendanceData['status'] == 'paid') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('$employeeName has already been paid for today.')),
          );
          return;
        }
      }

      double totalHoursWorked = 0.0;

      // Calculate total hours worked
      for (var attendanceDoc in attendanceSnapshot.docs) {
        var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        Timestamp timeInTimestamp = attendanceData['time_in'];
        Timestamp? timeOutTimestamp = attendanceData['time_out'];

        if (timeOutTimestamp != null) {
          DateTime timeIn = timeInTimestamp.toDate();
          DateTime timeOut = timeOutTimestamp.toDate();
          double hoursWorked = timeOut.difference(timeIn).inMinutes / 60.0;
          totalHoursWorked += hoursWorked;
        }
      }

      // Calculate total pay
      double totalPay = (totalHoursWorked >= 8)
          ? salaryPerDay + ((totalHoursWorked - 8) * (salaryPerDay / 8) * 1.05)
          : (salaryPerDay / 8) * totalHoursWorked;

      _showPayModal(context, employeeId, employeeName, totalHoursWorked,
          salaryPerDay, totalPay);
    } catch (e) {
      print('Error calculating daily pay for $employeeId: $e');
    }
  }

  void _showPayModal(
      BuildContext context,
      String employeeId,
      String employeeName,
      double hoursWorked,
      double salaryPerDay,
      double totalPay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Daily Pay Calculation for $employeeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hours Worked: ${hoursWorked.toStringAsFixed(2)}'),
              Text(
                  'Daily Salary Rate: ${NumberFormat.currency(symbol: "\$").format(salaryPerDay)}'),
              Text(
                  'Total Pay: ${NumberFormat.currency(symbol: "\$").format(totalPay)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (totalPay == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'No payment recorded for $employeeName as the total pay is 0.'),
                    ),
                  );
                  Navigator.pop(
                      context); // Close the modal after showing the message
                  return;
                }

                await _recordPayment(employeeId, employeeName, totalPay);
                Navigator.pop(context); // Close the modal after payment
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Payment recorded for $employeeName successfully.')),
                );
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordPayment(
      String employeeId, String employeeName, double totalPay) async {
    try {
      // Check if the total pay is 0 and skip recording the payment
      if (totalPay == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No payment recorded for $employeeName as the total pay is 0.'),
          ),
        );
        print('No payment recorded as total pay is 0.');
        return;
      }

      QuerySnapshot dtrSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_out', isNull: false)
          .orderBy('time_out', descending: true)
          .limit(1)
          .get();

      if (dtrSnapshot.docs.isNotEmpty) {
        DocumentReference dtrDocRef = dtrSnapshot.docs.first.reference;

        // Update the time record status to "paid"
        await dtrDocRef.update({
          'status': 'paid',
        });

        // Record the payment in the outflow collection
        await FirebaseFirestore.instance.collection('outflow').add({
          'category': 'employee wage',
          'date': Timestamp.now(),
          'employee': employeeName,
          'employeeid': employeeId,
          'price': totalPay,
        });

        // Update payment status in local state
        setState(() {
          _paymentStatus[employeeId] = true;
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //       content:
        //           Text('Payment recorded for $employeeName successfully.')),
        // );

        print('Payment recorded successfully in outflow.');
      }
    } catch (e) {
      print('Error recording payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer(); // Opens the drawer
                      },
                    );
                  },
                ),
                Text(
                  'Employees',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
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
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by employee name, id, or position',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _onSearchChanged();
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _addEmployee();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF4F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Add Employee',
                        style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Colors.white)),
                      ),
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20), // Spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/driverpayroll');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Driver Payroll',
                        style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.payment_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(border: Border.all()),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border:
                          const Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        title('Employee ID', 3),
                        title('Name', 3),
                        title('Position', 3),
                        title('Exp. Time In', 3),
                        title('Exp. Time Out', 3),
                        title('Attendance', 3),
                        title('Details', 2),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : ListView.builder(
                            itemCount: _filteredEmployees.length,
                            itemBuilder: (context, index) {
                              var employee = _filteredEmployees[index];
                              var employeeId = employee['id'];
                              var name = employee['name'];
                              var position = employee['position'];
                              var expTimeIn = employee['exp_time_in'];
                              var expTimeOut = employee['exp_time_out'];
                              double salaryPerDay = employee['salary_per_day'];
                              String? imageUrl = employee['imageUrl'];

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 10),
                                    // Display Employee Image
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      ClipOval(
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.image_not_supported,
                                                size: 50);
                                          },
                                        ),
                                      )
                                    else
                                      const Icon(Icons.person, size: 50),

                                    const SizedBox(width: 10),

                                    // Employee Details
                                    Expanded(
                                      flex: 2,
                                      child: _buildText(employeeId, 2),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildTitleText(name, 2),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildText(position, 2),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildText(expTimeIn, 2),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildText(expTimeOut, 2),
                                    ),

                                    // Time In/Time Out and Pay Buttons
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              if (_attendanceStatus[
                                                          employeeId] ==
                                                      null ||
                                                  !_attendanceStatus[
                                                      employeeId]!) {
                                                await _timeIn(employeeId);
                                                setState(() {
                                                  _attendanceStatus[
                                                      employeeId] = true;
                                                });
                                              } else {
                                                await _timeOut(employeeId, name,
                                                    salaryPerDay);
                                                setState(() {
                                                  _attendanceStatus[
                                                      employeeId] = false;
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _attendanceStatus[
                                                              employeeId] ==
                                                          true
                                                      ? Colors.red
                                                      : Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                            ),
                                            child: Text(
                                              _attendanceStatus[employeeId] ==
                                                      true
                                                  ? 'Time Out'
                                                  : 'Time In',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 5),

                                          // Conditionally display the Pay button
                                          if (position.toLowerCase() !=
                                                  'driver' &&
                                              position.toLowerCase() !=
                                                  'contractual driver')
                                            ElevatedButton(
                                              onPressed:
                                                  _paymentStatus[employeeId] ==
                                                          true
                                                      ? () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Payment Status'),
                                                                content: Text(
                                                                    '$name has already been paid for today. No additional payment is allowed.'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'OK'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                      : () async {
                                                          await _calculateAndShowDailyPay(
                                                              employeeId,
                                                              name,
                                                              salaryPerDay);
                                                        },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _paymentStatus[
                                                            employeeId] ==
                                                        true
                                                    ? Colors.red
                                                    : Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              child: const Text(
                                                'Pay',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Details Icon
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/employeeprofile',
                                          arguments: employee,
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
    );
  }

  Widget title(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 20,
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTitleText(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _addEmployee() {
    TextEditingController nameController = TextEditingController();
    TextEditingController contactController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController salaryController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController expTimeInController = TextEditingController();
    TextEditingController expTimeOutController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    Uint8List? _imageBytes;
    String? _imageFileName;
    String? _errorMessage; // Error message to display
    bool _isUploading = false;

    // Function to pick an image
    Future<void> _pickImage(
        void Function(void Function()) setModalState) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        _imageBytes = result.files.first.bytes;
        _imageFileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        setModalState(() {});
      }
    }

    // Function to upload the image to Firebase Storage
    Future<void> _uploadImage() async {
      if (_imageBytes == null || _imageFileName == null) return;

      _isUploading = true;
      try {
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('employee_images/$_imageFileName');

        await storageReference.putData(_imageBytes!);
        _isUploading = false;
      } catch (e) {
        _isUploading = false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add New Employee'),
              content: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contactController,
                        decoration:
                            const InputDecoration(labelText: 'Contact Number'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration:
                            const InputDecoration(labelText: 'Email Address'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),

                      // Dropdown for selecting position
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        items: _positionsList.map((position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedPosition = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Conditionally display the Salary field
                      if (_selectedPosition != null &&
                          _selectedPosition!.toLowerCase() != 'driver' &&
                          _selectedPosition!.toLowerCase() !=
                              'contractual driver')
                        TextField(
                          controller: salaryController,
                          decoration: const InputDecoration(
                              labelText: 'Salary Per Day'),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: birthDateController,
                        decoration:
                            const InputDecoration(labelText: 'Birth Date'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: expTimeInController,
                        decoration: const InputDecoration(
                            labelText: 'Expected Time In (Optional)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: expTimeOutController,
                        decoration: const InputDecoration(
                            labelText: 'Expected Time Out (Optional)'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _pickImage(setModalState),
                        child: const Text('Choose Image'),
                      ),
                      const SizedBox(height: 10),
                      if (_imageBytes != null)
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (_imageFileName != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Selected file: $_imageFileName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        contactController.text.isEmpty ||
                        addressController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty ||
                        _selectedPosition == null ||
                        (_selectedPosition!.toLowerCase() != 'driver' &&
                            _selectedPosition!.toLowerCase() !=
                                'contractual driver' &&
                            salaryController.text.isEmpty) ||
                        birthDateController.text.isEmpty ||
                        _imageBytes == null) {
                      setModalState(() {
                        _errorMessage =
                            'Please fill in all required fields, including profile image and salary if applicable.';
                      });
                      return;
                    }

                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      String userUid = userCredential.user!.uid;

                      // Upload image if selected
                      await _uploadImage();

                      await FirebaseFirestore.instance
                          .collection('employees')
                          .add({
                        'uid': userUid,
                        'name': nameController.text,
                        'contact_number': contactController.text,
                        'address': addressController.text,
                        'email_address': emailController.text,
                        'position': _selectedPosition,
                        'salary_per_day':
                            _selectedPosition!.toLowerCase() != 'driver' &&
                                    _selectedPosition!.toLowerCase() !=
                                        'contractual driver'
                                ? salaryController.text
                                : '0.0',
                        'birth_date': birthDateController.text,
                        'exp_time_in': expTimeInController.text,
                        'exp_time_out': expTimeOutController.text,
                        'status': 'active',
                        'image': _imageFileName ?? '',
                        'created_at': FieldValue.serverTimestamp(),
                      });

                      Navigator.of(context).pop();
                      _fetchEmployees();
                    } catch (e) {
                      setModalState(() {
                        _errorMessage = 'Failed to add employee: $e';
                      });
                    }
                  },
                  child: const Text('Add Employee'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
