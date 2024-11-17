import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';
  String address = 'Loading...';
  String birthDate = 'Loading...';
  String status = 'Loading...';
  String id = 'Loading...';
  double totalDriverShare = 0.0;
  List<Map<String, dynamic>> bookingsList = [];
  String imageUrl = '';
  File? _selectedImage;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      email = user.email ?? 'Unknown Email';

      QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('email_address', isEqualTo: email)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        var driverData =
            driverSnapshot.docs.first.data() as Map<String, dynamic>;
        id = driverSnapshot.docs.first.id;

        setState(() {
          name = driverData['name'] ?? 'Unknown Driver';
          phone = driverData['contact_number'] ?? 'No phone number';
          address = driverData['address'] ?? 'No address provided';
          birthDate = driverData['birth_date'] ?? 'No birth date provided';
          status = driverData['status'] ?? 'Unknown';
          phoneController.text = phone;
          addressController.text = address;
        });

        // Fetch image URL if the 'image' field is present
        String imageFileName = driverData['image'] ?? '';
        if (imageFileName.isNotEmpty) {
          try {
            imageUrl = await FirebaseStorage.instance
                .ref('employee_images/$imageFileName')
                .getDownloadURL();
            setState(() {});
          } catch (e) {
            print('Error fetching image URL: $e');
          }
        }

        // Fetch the bookings associated with the driver
        await _fetchDriverBookings();
      }
    }
  }

  Future<void> _fetchDriverBookings() async {
    try {
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: id)
          .get();

      double totalShare = 0.0;
      List<Map<String, dynamic>> fetchedBookings = [];

      for (var doc in bookingsSnapshot.docs) {
        var bookingData = doc.data() as Map<String, dynamic>;
        double driverShare =
            double.tryParse(bookingData['driver_share']?.toString() ?? '0.0') ??
                0.0;
        totalShare += driverShare;

        Timestamp timestamp = bookingData['date'] ?? Timestamp.now();
        String formattedDate =
            DateFormat('MM/dd/yyyy, EEEE').format(timestamp.toDate());

        fetchedBookings.add({
          'bookingId': doc.id,
          'date': formattedDate,
          'status': bookingData['status'] ?? 'Unknown',
          'vehicle': bookingData['vehicle'] ?? 'N/A',
          'overall_weight': double.tryParse(
                  bookingData['overall_weight']?.toString() ?? '0.0') ??
              0.0,
          'overall_price': double.tryParse(
                  bookingData['overall_price']?.toString() ?? '0.0') ??
              0.0,
          'driver_share': driverShare,
        });
      }

      fetchedBookings.sort((a, b) {
        DateTime dateA = DateFormat('MM/dd/yyyy, EEEE').parse(a['date']);
        DateTime dateB = DateFormat('MM/dd/yyyy, EEEE').parse(b['date']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        totalDriverShare = totalShare;
        bookingsList = fetchedBookings;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
    }
  }

  Future<void> _updateDriverInfo() async {
    try {
      await FirebaseFirestore.instance.collection('employees').doc(id).update({
        'contact_number': phoneController.text,
        'address': addressController.text,
      });
      setState(() {
        phone = phoneController.text;
        address = addressController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.green,
        title: const Text(
          'Driver Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            height: MediaQuery.of(context).size.height * .90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Driver: $name',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Email: $email',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Phone: $phone',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Address: $address',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Birth Date: $birthDate',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Status: $status',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Total Driver Share: ₱${totalDriverShare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Bookings:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: bookingsList.isEmpty
                      ? const Center(child: Text('No bookings found.'))
                      : ListView.builder(
                          itemCount: bookingsList.length,
                          itemBuilder: (context, index) {
                            var booking = bookingsList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${booking['date']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Status: ${booking['status']}'),
                                    Text('Vehicle: ${booking['vehicle']}'),
                                    Text(
                                      'Overall Weight: ${booking['overall_weight'] is double ? booking['overall_weight'].toStringAsFixed(2) : 'N/A'} kg',
                                    ),
                                    Text(
                                      'Overall Price: ₱${booking['overall_price'] is double ? booking['overall_price'].toStringAsFixed(2) : 'N/A'}',
                                    ),
                                    Text(
                                      'Driver Share: ₱${booking['driver_share'] is double ? booking['driver_share'].toStringAsFixed(2) : 'N/A'}',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display selected image preview
              _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.person, size: 100),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Choose Image'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedImage != null) {
                  await _uploadImage(); // Upload image to Firebase Storage
                }
                await _updateDriverInfo(); // Update other profile info
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to pick an image using file_picker
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  // Function to upload the selected image to Firebase Storage
  Future<void> _uploadImage() async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'employee_images/${FirebaseAuth.instance.currentUser?.uid}.jpg');

      await storageRef.putFile(_selectedImage!);

      // Update Firestore with the file name or path
      await FirebaseFirestore.instance.collection('employees').doc(id).update({
        'image': '${FirebaseAuth.instance.currentUser?.uid}.jpg',
      });

      // Retrieve and update the image URL in the UI
      imageUrl = await storageRef.getDownloadURL();
      setState(() {});
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image.')),
      );
    }
  }
}
