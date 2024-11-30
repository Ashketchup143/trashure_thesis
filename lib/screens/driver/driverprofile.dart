import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      }
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
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center contents horizontally
              children: [
                SizedBox(
                  height: 100,
                ),
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Driver: $name',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 26, // Larger font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: $email',
                  style: const TextStyle(fontSize: 18), // Larger font size
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: $phone',
                  style: const TextStyle(fontSize: 18), // Larger font size
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: $address',
                  style: const TextStyle(fontSize: 18), // Larger font size
                ),
                const SizedBox(height: 8),
                Text(
                  'Birth Date: $birthDate',
                  style: const TextStyle(fontSize: 18), // Larger font size
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: $status',
                  style: const TextStyle(fontSize: 18), // Larger font size
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
