import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _fetchEmployees() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('employees').get();

    setState(() {
      _employeesList = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'position': doc['position'],
          'exp_time_in': doc['exp_time_in'],
          'exp_time_out': doc['exp_time_out'],
          'address': doc['address'],
          'birth_date': doc['birth_date'],
          'contact_number': doc['contact_number'],
          'email_address': doc['email_address'],
          'salary_per_hour': doc['salary_per_hour'],
        };
      }).toList();
      _filteredEmployees = _employeesList;
    });
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
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.menu,
                                    color: Colors.green, size: 25),
                                onPressed: () {
                                  Scaffold.of(context)
                                      .openDrawer(); // Opens the drawer
                                },
                              ),
                              Text(
                                'Employees',
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Search bar
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
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search by employee name, id, or position',
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (value) {
                                    _onSearchChanged();
                                  },
                                ),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  _addEmployee(); // Call add employee function
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4CAF4F),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Employee',
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white)),
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
                                onPressed: () {
                                  // Handle payroll action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0062FF),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  textStyle: TextStyle(fontSize: 16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 8),
                                    Text(
                                      'Payroll',
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white)),
                                    ),
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Container(
                            height: MediaQuery.of(context).size.height * .8,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(border: Border.all()),
                            child: Column(
                              children: [
                                // Title row
                                Container(
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
                                  child: ListView.builder(
                                    itemCount: _filteredEmployees.length,
                                    itemBuilder: (context, index) {
                                      var employee = _filteredEmployees[index];
                                      var employeeid = employee['id'];
                                      var name = employee['name'];
                                      var position = employee['position'];
                                      var expTimeIn = employee['exp_time_in'];
                                      var expTimeOut = employee['exp_time_out'];

                                      _selectedOptions[employeeid] ??= false;
                                      _attendanceStatus[employeeid] ??= false;

                                      return _buildCustomCheckboxTile(
                                        employeeid,
                                        employeeid,
                                        name,
                                        position,
                                        expTimeIn,
                                        expTimeOut,
                                        employee,
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
              )),
    );
  }

  Widget title(String text, int fl) {
    return Expanded(
      flex: fl,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide()),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
                textStyle: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckboxTile(
    String option,
    String employeeid,
    String empname,
    String position,
    String exptimein,
    String exptimeout,
    Map<String, dynamic> employee,
  ) {
    return Column(
      children: [
        CheckboxListTile(
          value: _selectedOptions[option],
          activeColor: Colors.green,
          onChanged: (bool? value) {
            setState(() {
              _selectedOptions[option] = value!;
            });
          },
          title: Row(
            children: [
              _buildText(employeeid, 2),
              _buildTitleText(empname, 2),
              _buildText(position, 2),
              _buildText(exptimein, 2),
              _buildText(exptimeout, 2),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _attendanceStatus[option] = !_attendanceStatus[option]!;
                    });

                    String todayDate =
                        DateFormat('yyyy-MM-dd').format(DateTime.now());

                    if (_attendanceStatus[option]!) {
                      // Time Out
                      try {
                        DocumentReference employeeDocRef = FirebaseFirestore
                            .instance
                            .collection('employees')
                            .doc(employeeid);

                        // Get the 'daily_time_record' document for today
                        QuerySnapshot dtrSnapshot = await employeeDocRef
                            .collection('daily_time_record')
                            .where('date', isEqualTo: todayDate)
                            .limit(1)
                            .get();

                        if (dtrSnapshot.docs.isNotEmpty) {
                          // Update 'time_out' field
                          DocumentReference dtrDocRef =
                              dtrSnapshot.docs.first.reference;
                          await dtrDocRef.update({
                            'time_out': FieldValue.serverTimestamp(),
                          });
                        } else {
                          // No existing record found, create a new one with time_out
                          await employeeDocRef
                              .collection('daily_time_record')
                              .add({
                            'date': todayDate,
                            'time_in': null,
                            'time_out': FieldValue.serverTimestamp(),
                          });
                        }
                      } catch (e) {
                        print('Error during Time Out: $e');
                      }
                    } else {
                      // Time In
                      try {
                        DocumentReference employeeDocRef = FirebaseFirestore
                            .instance
                            .collection('employees')
                            .doc(employeeid);

                        // Check if there's already a 'daily_time_record' for today
                        QuerySnapshot dtrSnapshot = await employeeDocRef
                            .collection('daily_time_record')
                            .where('date', isEqualTo: todayDate)
                            .limit(1)
                            .get();

                        if (dtrSnapshot.docs.isEmpty) {
                          // No existing record, create one
                          await employeeDocRef
                              .collection('daily_time_record')
                              .add({
                            'date': todayDate,
                            'time_in': FieldValue.serverTimestamp(),
                            'time_out': null,
                          });
                        } else {
                          // Existing record found, update 'time_in'
                          DocumentReference dtrDocRef =
                              dtrSnapshot.docs.first.reference;
                          await dtrDocRef.update({
                            'time_in': FieldValue.serverTimestamp(),
                          });
                        }
                      } catch (e) {
                        print('Error during Time In: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _attendanceStatus[option]!
                        ? Colors.red // Time Out
                        : Colors.blue, // Time In
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    _attendanceStatus[option]! ? 'Time Out' : 'Time In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    // Navigate to the employee profile screen and pass employee data
                    Navigator.pushNamed(
                      context,
                      '/employeeprofile',
                      arguments: {
                        'id': employee['id'],
                        'name': employee['name'],
                        'position': employee['position'],
                        'address': employee['address'],
                        'birth_date': employee['birth_date'],
                        'contact_number': employee['contact_number'],
                        'email_address': employee['email_address'],
                        'salary_per_hour': employee['salary_per_hour'],
                        'exp_time_in': employee['exp_time_in'],
                        'exp_time_out': employee['exp_time_out'],
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildText(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _addEmployee() {
    TextEditingController nameController = TextEditingController();
    TextEditingController contactController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController positionController = TextEditingController();
    TextEditingController salaryController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController expTimeInController = TextEditingController();
    TextEditingController expTimeOutController = TextEditingController();
    TextEditingController passwordController =
        TextEditingController(); // New controller for password

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(labelText: 'Contact Number'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email Address'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                        labelText: 'Password'), // New field for password
                    obscureText: true, // Hide password input
                  ),
                  TextField(
                    controller: positionController,
                    decoration: InputDecoration(labelText: 'Position'),
                  ),
                  TextField(
                    controller: salaryController,
                    decoration: InputDecoration(labelText: 'Salary Per Hour'),
                  ),
                  TextField(
                    controller: birthDateController,
                    decoration: InputDecoration(labelText: 'Birth Date'),
                  ),
                  TextField(
                    controller: expTimeInController,
                    decoration: InputDecoration(
                        labelText: 'Expected Time In (Optional)'),
                  ),
                  TextField(
                    controller: expTimeOutController,
                    decoration: InputDecoration(
                        labelText: 'Expected Time Out (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Ensure required fields are filled in
                if (nameController.text.isEmpty ||
                    contactController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController
                        .text.isEmpty || // Ensure password is provided
                    positionController.text.isEmpty ||
                    salaryController.text.isEmpty ||
                    birthDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please fill in all required fields')));
                  return;
                }

                try {
                  // Create user in Firebase Authentication
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text,
                    password:
                        passwordController.text, // Use the provided password
                  );
                  String userUid = userCredential.user!.uid;

                  // Add new employee to Firestore with the UID
                  await FirebaseFirestore.instance.collection('employees').add({
                    'uid': userUid, // Store the UID for reference
                    'name': nameController.text,
                    'contact_number': contactController.text,
                    'address': addressController.text,
                    'email_address': emailController.text,
                    'position': positionController.text,
                    'salary_per_hour': salaryController.text,
                    'password': passwordController.text,
                    'birth_date': birthDateController.text,
                    'exp_time_in': expTimeInController.text.isNotEmpty
                        ? expTimeInController.text
                        : "",
                    'exp_time_out': expTimeOutController.text.isNotEmpty
                        ? expTimeOutController.text
                        : "",
                  });

                  Navigator.of(context).pop(); // Close dialog
                  _fetchEmployees(); // Refresh the employee list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add employee: $e')),
                  );
                }
              },
              child: Text(
                'Add Employee',
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without adding
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Time In: Adds or updates the "time_in" field for the current date
  Future<void> _timeIn(String employeeId) async {
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference employeeRef =
        FirebaseFirestore.instance.collection('employees').doc(employeeId);

    // Reference the subcollection and document for the current date
    DocumentReference dailyRecordRef =
        employeeRef.collection('daily_time_record').doc(currentDate);

    try {
      // Fetch the document to check if it exists
      DocumentSnapshot dailyRecord = await dailyRecordRef.get();

      // Check if the document exists
      if (!dailyRecord.exists) {
        // No document for today exists, create the subcollection and the document
        await dailyRecordRef.set({
          'time_in': Timestamp.now(),
          'time_out': null, // Initialize time_out as null
        });
        print("Subcollection 'daily_time_record' created with time_in");
      } else {
        // If the record exists, just update the time_in field
        await dailyRecordRef.update({
          'time_in': Timestamp.now(),
        });
        print("time_in updated in the subcollection 'daily_time_record'");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Time In recorded for $employeeId')),
      );
    } catch (e) {
      // Log the error
      print('Error creating subcollection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record Time In: $e')),
      );
    }
  }

// Time Out: Adds or updates the "time_out" field for the current date
  Future<void> _timeOut(String employeeId) async {
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    DocumentReference employeeRef =
        FirebaseFirestore.instance.collection('employees').doc(employeeId);

    // Reference the subcollection and document for the current date
    DocumentReference dailyRecordRef =
        employeeRef.collection('daily_time_record').doc(currentDate);

    try {
      // Fetch the document to check if it exists
      DocumentSnapshot dailyRecord = await dailyRecordRef.get();

      if (dailyRecord.exists) {
        // If the record exists, update the time_out field
        await dailyRecordRef.update({
          'time_out': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Time Out recorded for $employeeId')),
        );
        print("time_out updated in the subcollection 'daily_time_record'");
      } else {
        // If no Time In is found for today, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No Time In found for today!')),
        );
        print("No time_in found for today; cannot record time_out");
      }
    } catch (e) {
      // Log the error
      print('Error updating time_out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record Time Out: $e')),
      );
    }
  }
}
