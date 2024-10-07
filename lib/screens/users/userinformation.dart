import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserInformation extends StatefulWidget {
  @override
  _UserInformationState createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late String _selectedStatus; // Updated: Status as String
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? user;
  Map<String, dynamic>? originalUserData;

  // Define status options
  final List<String> _statusOptions = [
    'Booked',
    'Completed',
    'In Progress',
    'Delayed',
    'Unbooked'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _selectedStatus = 'Unbooked'; // Default status
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user == null) {
      user =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (user != null) {
        originalUserData = Map<String, dynamic>.from(user!);

        // Set initial values of the controllers with the user data
        _nameController.text = user!['name'] ?? '';
        _categoryController.text = user!['category'] ?? '';
        _contactController.text = user!['contact'] ?? '';
        _emailController.text = user!['email'] ?? '';
        _addressController.text = user!['address'] ?? '';
        _selectedStatus = user!['status'] ?? 'Unbooked';
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
    return _nameController.text != originalUserData!['name'] ||
        _categoryController.text != originalUserData!['category'] ||
        _contactController.text != originalUserData!['contact'] ||
        _emailController.text != originalUserData!['email'] ||
        _addressController.text != originalUserData!['address'] ||
        _selectedStatus != originalUserData!['status'];
  }

  // Save updated user information to Firestore
  void _saveChanges(String userId) async {
    if (!_hasChanged()) {
      _showDialog('No changes', 'No information has been changed.');
      _isEditing = false;
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text,
        'category': _categoryController.text,
        'contact': _contactController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'status': _selectedStatus,
      });

      _showDialog('Success', 'User information has been updated.');
      setState(() {
        _isEditing = false;
        originalUserData = {
          'name': _nameController.text,
          'category': _categoryController.text,
          'contact': _contactController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'status': _selectedStatus,
        };
      });
    } catch (e) {
      _showDialog('Error', 'Failed to update user information.');
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

  // Get status color, return default color if empty or null
  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) {
      return Color(0xFFF5D322); // Default color for "Unbooked"
    }
    switch (status.toLowerCase()) {
      case 'booked':
        return Color.fromARGB(255, 66, 167, 250);
      case 'completed':
        return Color.fromARGB(255, 76, 181, 80);
      case 'in progress':
        return Colors.grey;
      case 'delayed':
        return Color.fromARGB(255, 249, 81, 70);
      case 'unbooked':
        return Color(0xFFF5D322);
      default:
        return Color.fromARGB(255, 150, 141, 61);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Information',
          style: GoogleFonts.poppins(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.green,
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing && user != null) {
                  _saveChanges(user!['uid']);
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
                    if (user != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileField('User ID', user!['uid'],
                              isEditable: false),
                          SizedBox(height: 16),
                          _buildProfileField('Name', _nameController.text,
                              controller: _nameController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Category', _categoryController.text,
                              controller: _categoryController),
                          SizedBox(height: 16),
                          _buildProfileField('Contact', _contactController.text,
                              controller: _contactController),
                          SizedBox(height: 16),
                          _buildProfileField('Email', _emailController.text,
                              controller: _emailController),
                          SizedBox(height: 16),
                          _buildProfileField('Address', _addressController.text,
                              controller: _addressController),
                          SizedBox(height: 16),
                          _buildStatusField('Status', _selectedStatus),
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

  // Widget for status field with dropdown and colored container
  Widget _buildStatusField(String fieldName, String selectedStatus) {
    String status = selectedStatus.isEmpty ? 'Unbooked' : selectedStatus;
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
          child: Row(
            children: [
              _isEditing
                  ? DropdownButton<String>(
                      value: _statusOptions.contains(_selectedStatus)
                          ? _selectedStatus
                          : _statusOptions[0], // Ensure a valid selection
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStatus = newValue ??
                              'Unbooked'; // Default to 'Unbooked' if null
                        });
                      },
                    )
                  : Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        status.isEmpty ? 'Unbooked' : status,
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
