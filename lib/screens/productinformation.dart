import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data'; // For web
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage

class ProductInformation extends StatefulWidget {
  final String productId;
  final String productName;
  final String details;
  final String category;
  final String imageUrl;

  ProductInformation({
    required this.productId,
    required this.productName,
    required this.details,
    required this.category,
    required this.imageUrl,
  });

  @override
  _ProductInformationState createState() => _ProductInformationState();
}

class _ProductInformationState extends State<ProductInformation> {
  bool _isEditing = false;
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _imageUrlController = TextEditingController();
  double _currentPrice = 0.0;
  String? _imageFileName; // For image file name
  bool _isUploading = false;
  List<DocumentSnapshot> _allCategories = []; // For category dropdown
  String _selectedCategory = ""; // Selected category from dropdown
  Uint8List? _imageBytes; // To store the selected image bytes

  @override
  void initState() {
    super.initState();
    _detailsController.text = widget.details;
    _categoryController.text = widget.category;
    _imageUrlController.text = widget.imageUrl;
    _selectedCategory = widget.category; // Set default category
    _fetchLatestPrice(); // Fetch the most recent price
    _fetchCategories(); // Fetch the categories for dropdown
  }

  Future<void> _fetchCategories() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('category').get();
    setState(() {
      _allCategories = snapshot.docs;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // If exiting edit mode, save the changes to Firestore
        _updateProductDetails();
      }
    });
  }

  Future<void> _fetchLatestPrice() async {
    QuerySnapshot priceSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('prices')
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (priceSnapshot.docs.isNotEmpty) {
      double latestPrice = priceSnapshot.docs.first['price'] ?? 0.0;
      setState(() {
        _currentPrice = latestPrice;
        _priceController.text = _currentPrice.toStringAsFixed(2);
      });
    }
  }

  Future<void> _updateProductDetails() async {
    if (_detailsController.text.trim().isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _priceController.text.trim().isNotEmpty) {
      double newPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // Upload image if there's a new one selected
      if (_imageFileName != null && _imageBytes != null) {
        await _uploadImage(widget.productId);
      }

      // Update product details in Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'details': _detailsController.text.trim(),
        'category': _selectedCategory,
        'picture': _imageFileName ?? widget.imageUrl,
      });

      // If the price has changed, add the new price to the prices subcollection
      if (newPrice != _currentPrice) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .collection('prices')
            .add({
          'price': newPrice,
          'original_price':
              newPrice, // Assuming the original price is entered manually
          'percentage_profit':
              20.0, // You can replace this with fetched value from your settings
          'time': FieldValue.serverTimestamp(),
        });
        setState(() {
          _currentPrice = newPrice;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product details updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details, Category, and Price cannot be empty')),
      );
    }
  }

  Future<void> _uploadImage(String productId) async {
    if (_imageFileName != null && _imageBytes != null) {
      try {
        setState(() {
          _isUploading = true;
        });

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images/$_imageFileName');
        await storageRef.putData(_imageBytes!);

        // Get the download URL for the uploaded image
        String downloadUrl = await storageRef.getDownloadURL();

        // Update the image URL in Firestore
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({'picture': downloadUrl});

        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndDisplayImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false, // Single image
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        Uint8List? fileBytes = result.files.first.bytes;
        String filename = result.files.first.name;

        // Store the image filename in state, to display the file name
        setState(() {
          _imageFileName = filename;
        });

        // Now the image file is stored, but we delay the upload until the user confirms
        _imageBytes = fileBytes;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected successfully!')),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

// Modify this function to get the image download URL using the filename
  Future<String> _getImageDownloadUrl(String fileName) async {
    try {
      String downloadUrl = await FirebaseStorage.instance
          .ref()
          .child('product_images/$fileName')
          .getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Error fetching image URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Product Details - ${widget.productName}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Check if there's an image URL, and fetch it from Firebase if necessary
            FutureBuilder<String>(
              future: _getImageDownloadUrl(widget.imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error fetching image: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  return Image.network(snapshot.data!, width: 200, height: 200);
                }
                return Text('No Image Available');
              },
            ),

            SizedBox(height: 10),
            Text(
              'Name: ${widget.productName}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            _isEditing
                ? TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Edit Details',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    'Details: ${_detailsController.text}',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 10),
            _isEditing
                ? DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: _allCategories.map((categoryDoc) {
                      return DropdownMenuItem<String>(
                        value: categoryDoc['category_name'],
                        child: Text(categoryDoc['category_name']),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Edit Category',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    'Category: ${_selectedCategory}',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 10),
            _isEditing
                ? Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickAndDisplayImage,
                        child: _isUploading
                            ? CircularProgressIndicator()
                            : Text('Choose Image'),
                      ),
                      SizedBox(width: 10),
                      if (_imageFileName != null)
                        Text('Image Selected: $_imageFileName'),
                    ],
                  )
                : Text(
                    'Image URL: ${_imageFileName ?? widget.imageUrl}',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 10),
            _isEditing
                ? TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Edit Current Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  )
                : Text(
                    'Current Price: ₱${_currentPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 20),
            Text(
              'Price History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height *
                  .32, // Set a fixed height for the scrollable container
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(8),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.productId)
                    .collection('prices')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var priceHistory = snapshot.data!.docs;

                  if (priceHistory.isEmpty) {
                    return Center(child: Text('No price history available.'));
                  }

                  return ListView.builder(
                    itemCount: priceHistory.length,
                    itemBuilder: (context, index) {
                      var priceData =
                          priceHistory[index].data() as Map<String, dynamic>;
                      double price = priceData['price'] ?? 0.0;
                      double originalPrice = priceData['original_price'] ?? 0.0;
                      double percentageProfit =
                          priceData['percentage_profit'] ?? 20.0;
                      Timestamp? timestamp = priceData['time'] as Timestamp?;
                      String formattedTime = timestamp != null
                          ? DateFormat('MM/dd/yyyy, hh:mm a')
                              .format(timestamp.toDate())
                          : 'N/A';

                      return ListTile(
                        leading: Icon(Icons.monetization_on),
                        title: Text('₱${price.toStringAsFixed(2)}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Original Price: ₱${originalPrice.toStringAsFixed(2)}'),
                            Text('Percentage Profit: $percentageProfit%'),
                            Text('Time: $formattedTime'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
