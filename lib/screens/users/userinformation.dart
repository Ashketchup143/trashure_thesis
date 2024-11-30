import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserInformation extends StatefulWidget {
  @override
  _UserInformationState createState() => _UserInformationState();
}

class _UserInformationState extends State<UserInformation> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _categoryController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _areaController; // Add for area field
  late TextEditingController _balanceController;
  late TextEditingController _landmarkController;
  late GeoPoint _location;
  late String _selectedStatus;
  List<String> _locations = []; // List to store locations from Firestore
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? user;
  Map<String, dynamic>? originalUserData;

  final List<String> _statusOptions = ['Booked', 'Done', 'Unbooked'];

  void _fetchLocations() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      setState(() {
        _locations = snapshot.docs
            .map((doc) => doc['location']
                .toString()
                .toLowerCase()) // Convert to lowercase
            .toList();
      });
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _categoryController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _balanceController = TextEditingController();
    _landmarkController = TextEditingController();
    _areaController = TextEditingController();
    _selectedStatus = 'Unbooked';
    _fetchLocations(); // Fetch locations during initialization
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user == null) {
      user =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (user != null) {
        originalUserData = Map<String, dynamic>.from(user!);
        _firstNameController.text = user!['firstName'] ?? 'No First Name';
        _lastNameController.text = user!['lastName'] ?? 'No Last Name';
        _categoryController.text = user!['category'] ?? 'No Category';
        _contactController.text = user!['contact'] ?? 'No Contact';
        _emailController.text = user!['email'] ?? 'No Email';
        _addressController.text = user!['address'] ?? 'No Address';
        _balanceController.text = user!['balance']?.toString() ?? '0.0';
        _landmarkController.text = user!['landmark'] ?? 'No Landmark';
        _areaController.text = user!['area'] ?? 'No Area'; // Set area field
        _location = user!['location'] ?? GeoPoint(0, 0);
        _selectedStatus = user!['status'] ?? 'Unbooked';
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  bool _hasChanged() {
    return _firstNameController.text != originalUserData!['firstName'] ||
        _lastNameController.text != originalUserData!['lastName'] ||
        _categoryController.text != originalUserData!['category'] ||
        _contactController.text != originalUserData!['contact'] ||
        _emailController.text != originalUserData!['email'] ||
        _addressController.text != originalUserData!['address'] ||
        _balanceController.text != originalUserData!['balance']?.toString() ||
        _landmarkController.text != originalUserData!['landmark'] ||
        _areaController.text != originalUserData!['area'] || // Compare area
        _location.latitude != originalUserData!['location']?.latitude ||
        _location.longitude != originalUserData!['location']?.longitude ||
        _selectedStatus != originalUserData!['status'];
  }

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
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'category': _categoryController.text,
        'contact': _contactController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'balance': double.tryParse(_balanceController.text) ?? 0.0,
        'landmark': _landmarkController.text,
        'area': _areaController.text.toLowerCase(), // Save as lowercase
        'location': _location,
        'status': _selectedStatus,
      });

      _showDialog('Success', 'User information has been updated.');
      setState(() {
        _isEditing = false;
        originalUserData = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'category': _categoryController.text,
          'contact': _contactController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'balance': double.tryParse(_balanceController.text) ?? 0.0,
          'landmark': _landmarkController.text,
          'area': _areaController.text.toLowerCase(), // Save lowercase
          'location': _location,
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
          'User Information',
          style: GoogleFonts.poppins(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.green,
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isEditing && user != null) {
                  _saveChanges(user!['id']);
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
                          _buildProfileField('User ID', user!['id'] ?? 'N/A',
                              isEditable: false),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'First Name', _firstNameController.text,
                              controller: _firstNameController),
                          SizedBox(height: 16),
                          _buildProfileField(
                              'Last Name', _lastNameController.text,
                              controller: _lastNameController),
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
                          _buildProfileField(
                              'Landmark', _landmarkController.text,
                              controller: _landmarkController),

                          SizedBox(height: 16),
                          _buildAreaField(), // Add the area field here
                          SizedBox(height: 16),
                          _buildLocationField('Location', _location),
                          SizedBox(height: 16),
                          _buildStatusField('Status', _selectedStatus),
                          SizedBox(height: 16),
                          Text(
                            'Bookings:',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          _buildBookingsList(user!['id']),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBookingsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Fetch all bookings
        var allBookings = snapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _filterBookingsByUser(allBookings, userId),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var userBookings = futureSnapshot.data!;

            if (userBookings.isEmpty) {
              return Text(
                'No bookings found for this user.',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(fontSize: 16),
                ),
              );
            }

            // Sort bookings by date (ascending)
            userBookings.sort((a, b) {
              DateTime dateA = (a['date'] as Timestamp).toDate();
              DateTime dateB = (b['date'] as Timestamp).toDate();
              return dateB.compareTo(dateA); // Descending order
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: userBookings.length,
              itemBuilder: (context, index) {
                var bookingData = userBookings[index];
                var bookingId = bookingData['bookingId'];
                var driver = bookingData['driver'] ?? 'Unknown Driver';
                var vehicle = bookingData['vehicle'] ?? 'Unknown Vehicle';
                var date = (bookingData['date'] as Timestamp).toDate();
                var formattedDate = DateFormat('MM/dd/yyyy').format(date);
                var status = bookingData['status'] ?? 'Unknown';

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('Date', style: _headerTextStyle())),
                          Expanded(
                              child: Text('Booking ID',
                                  style: _headerTextStyle())),
                          Expanded(
                              child: Text('Driver', style: _headerTextStyle())),
                          Expanded(
                              child:
                                  Text('Vehicle', style: _headerTextStyle())),
                          Expanded(
                              child: Text('Status', style: _headerTextStyle())),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          Expanded(child: Text(formattedDate)),
                          Expanded(child: Text(bookingId)),
                          Expanded(child: Text(driver)),
                          Expanded(child: Text(vehicle)),
                          Expanded(
                              child: Text(status,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(height: 10),
                      ExpansionTile(
                        title: Text(
                          'Recyclables',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildRecyclablesList(
                                bookingId, userId, status),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _filterBookingsByUser(
      List<DocumentSnapshot> bookings, String userId) async {
    List<Map<String, dynamic>> userBookings = [];

    for (var booking in bookings) {
      var userDoc =
          await booking.reference.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var bookingData = booking.data() as Map<String, dynamic>;
        bookingData['bookingId'] = booking.id;
        userBookings.add(bookingData);
      }
    }

    return userBookings;
  }

  TextStyle _headerTextStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.black87,
    );
  }

  Widget _buildRecyclablesList(String bookingId, String userId, String status) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String userStatus = userData['status'] ?? 'Unknown';
        print('User Data: $userData');

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .collection('users')
              .doc(userId)
              .collection('recyclables')
              .snapshots(),
          builder: (context, recyclableSnapshot) {
            if (!recyclableSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            var recyclables = recyclableSnapshot.data!.docs;

            if (recyclables.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('No recyclables found for this booking.'),
              );
            }

            double totalAmount = 0;
            double totalWeight = 0;

            recyclables.forEach((recyclable) {
              var data = recyclable.data() as Map<String, dynamic>;
              var weight = data['final_weight'] ?? data['weight'] ?? 0.0;
              var price = data['price'] ?? 0.0;
              var itemPrice = weight * price;

              totalWeight += weight;
              totalAmount += itemPrice;
            });

            // Calculate the adjusted total amount based on user category and mode
            // Calculate the adjusted total amount based on user category or mode
            double adjustedTotalAmount;
            bool isServiceFeeApplicable = true;

// Check if service fee is applicable
            if (userData['category']?.toLowerCase() == 'business' ||
                userData['mode']?.toLowerCase() == 'donate') {
              // No service fee for business category or donate mode
              adjustedTotalAmount = totalAmount;
              isServiceFeeApplicable = false;
            } else {
              // Deduct service fee for other cases
              adjustedTotalAmount = totalAmount - 40;
              isServiceFeeApplicable = true;
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Type', style: _headerTextStyle())),
                    Expanded(child: Text('Weight', style: _headerTextStyle())),
                    Expanded(
                        child: Text('Price per kg', style: _headerTextStyle())),
                    Expanded(child: Text('Total', style: _headerTextStyle())),
                  ],
                ),
                Divider(),
                ...recyclables.map((recyclable) {
                  var data = recyclable.data() as Map<String, dynamic>;
                  var type = data['type'] ?? 'Unknown';
                  var weight = data['final_weight'] ?? data['weight'] ?? 0.0;
                  var price = data['price'] ?? 0.0;
                  var itemPrice = weight * price;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(type)),
                        Expanded(
                            child: Text('${weight.toStringAsFixed(2)} kg')),
                        Expanded(child: Text('₱${price.toStringAsFixed(2)}')),
                        Expanded(
                            child: Text('₱${itemPrice.toStringAsFixed(2)}')),
                      ],
                    ),
                  );
                }).toList(),
                Divider(),
                Row(
                  children: [
                    Expanded(
                        child: Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('${totalWeight.toStringAsFixed(2)} kg',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: SizedBox()), // Empty cell for alignment
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isServiceFeeApplicable) ...[
                            Text(
                              '- 40 (Service Fee)',
                              style: TextStyle(color: Colors.red),
                            ),
                            Text(
                              '₱${adjustedTotalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'User Status: ${userData['status'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  Widget _buildLocationField(String fieldName, GeoPoint location) {
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
          child: Text(
            'Lat: ${location.latitude}, Long: ${location.longitude}',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            'Area:',
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
              ? DropdownButton<String>(
                  value: _locations.contains(_areaController.text.toLowerCase())
                      ? _areaController.text.toLowerCase()
                      : null, // Normalize case for value check
                  hint: Text("Select Area"),
                  items: _locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location, // Use lowercase value
                      child: Text(location), // Display in lowercase
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _areaController.text = newValue ?? 'No Area';
                    });
                  },
                )
              : Text(
                  _areaController.text.isEmpty
                      ? 'No Area'
                      : _areaController.text
                          .toLowerCase(), // Display in lowercase
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
        ),
      ],
    );
  }

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
                          : _statusOptions[0],
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
                          _selectedStatus = newValue ?? 'Unbooked';
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

  // Function to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.blue;
      case 'booked':
        return Colors.green;
      case 'unbooked':
      default:
        return Color(0xFFF5D322);
    }
  }
}
