import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
        _nameController.text = employee!['name'];
        _positionController.text = employee!['position'];
        _addressController.text = employee!['address'];
        _birthDateController.text = employee!['birth_date'];
        _contactController.text = employee!['contact_number'];
        _emailController.text = employee!['email_address'];
        _salaryController.text = employee!['salary_per_hour'];
        _expTimeInController.text = employee!['exp_time_in'];
        _expTimeOutController.text = employee!['exp_time_out'];
      }
    }
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
        // Update original data to reflect the latest changes
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
        title: Text(
          'Employee Profile',
          style: GoogleFonts.poppins(
              textStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          if (employee != null)
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
