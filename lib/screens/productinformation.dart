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
  String _currentImageUrl = "";

  @override
  void initState() {
    super.initState();
    _detailsController.text = widget.details;
    _categoryController.text = widget.category;
    _imageUrlController.text = widget.imageUrl;
    _selectedCategory = widget.category; // Set default category
    _currentImageUrl = widget.imageUrl; // Initialize the current image URL
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
      double latestPrice = priceSnapshot.docs.first['original_price'] ?? 0.0;
      setState(() {
        _currentPrice = latestPrice;
        _priceController.text = _currentPrice.toStringAsFixed(2);
      });
    }
  }

  Future<void> _updateProductDetails() async {
    // Trim and get the updated values
    String updatedDetails = _detailsController.text.trim();
    String updatedCategory = _selectedCategory;
    String updatedImageUrl = _imageFileName ?? _currentImageUrl;
    double newPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;

    // Check if there are any actual changes
    bool hasDetailsChanged = updatedDetails != widget.details;
    bool hasCategoryChanged = updatedCategory != widget.category;
    bool hasImageChanged = _imageFileName != null;
    bool hasPriceChanged = newPrice != _currentPrice;

    // If nothing has changed, exit the function early
    if (!hasDetailsChanged &&
        !hasCategoryChanged &&
        !hasImageChanged &&
        !hasPriceChanged) {
      // Show "Edit Successful" modal
      _showModalDialog('No Changes', 'Details stay the same.');
      return;
    }

    // Fetch percentage profit if price has changed
    double calculatedPrice = newPrice;
    if (hasPriceChanged) {
      double percentageProfit = await _getPercentageProfit();
      calculatedPrice = newPrice * (1 - percentageProfit / 100);
    }

    if (_imageFileName != null) {
      // Upload the image and update Firestore
      await _uploadImage(widget.productId);

      setState(() {
        _currentImageUrl = _imageFileName!;
      });
    }

    // Update product details in Firestore if there are changes
    Map<String, dynamic> updateData = {};
    if (hasDetailsChanged) updateData['details'] = updatedDetails;
    if (hasCategoryChanged) updateData['category'] = updatedCategory;
    if (hasImageChanged) updateData['picture'] = _currentImageUrl;

    // Perform updates only if necessary
    if (updateData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(updateData);
    }

    // Update the price history if the price has changed
    if (hasPriceChanged) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('prices')
          .add({
        'price': calculatedPrice,
        'original_price': newPrice,
        'percentage_profit': await _getPercentageProfit(),
        'time': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentPrice = calculatedPrice;
      });
    }

    // Show "Edit Successful" modal
    _showModalDialog(
        'Edit Successful', 'Product details updated successfully.');
  }

  void _showModalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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

        // Update the filename in Firestore
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update({'picture': _imageFileName});

        setState(() {
          _isUploading = false;
          _currentImageUrl = _imageFileName!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Image uploaded and filename updated successfully!')),
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
      Uint8List? fileBytes = result.files.first.bytes;
      String filename = result.files.first.name;

      // Store the image filename and bytes, but don't upload yet
      setState(() {
        _imageFileName = filename;
        _imageBytes = fileBytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selected successfully!')),
      );
    }
  }

  Future<double> _getPercentageProfit() async {
    DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('percentage_profit')
        .get();

    if (settingsDoc.exists && settingsDoc.data() != null) {
      return settingsDoc['percentage_profit'] ??
          20.0; // Default to 20% if not found
    }
    return 20.0; // Default percentage if not found
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
              future: _getImageDownloadUrl(_currentImageUrl),
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
            Text(
              'Name: ${widget.productName}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            _isEditing
                ? TextFormField(
                    controller: _detailsController,
                    maxLines: 1,
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
                  .30, // Set a fixed height for the scrollable container
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
