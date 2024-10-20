import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _detailsController.text = widget.details;
    _categoryController.text = widget.category;
    _imageUrlController.text = widget.imageUrl;

    _fetchLatestPrice(); // Fetch the most recent price
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
        _categoryController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty) {
      double newPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update({
        'details': _detailsController.text.trim(),
        'category': _categoryController.text.trim(),
        'picture': _imageUrlController.text.trim(),
      });

      // If the price has changed, add the new price to the prices subcollection
      if (newPrice != _currentPrice) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .collection('prices')
            .add({
          'price': newPrice,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details - ${widget.productName}'),
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
            if (widget.imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  widget.imageUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
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
                ? TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Edit Category',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    'Category: ${_categoryController.text}',
                    style: TextStyle(fontSize: 18),
                  ),
            SizedBox(height: 10),
            _isEditing
                ? TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Edit Image URL',
                      border: OutlineInputBorder(),
                    ),
                  )
                : Text(
                    'Image URL: ${_imageUrlController.text}',
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
              height: 200, // Set a fixed height for the scrollable container
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
                      Timestamp? timestamp = priceData['time'] as Timestamp?;
                      String formattedTime = timestamp != null
                          ? DateFormat('MM/dd/yyyy, hh:mm a')
                              .format(timestamp.toDate())
                          : 'N/A';

                      return ListTile(
                        leading: Icon(Icons.monetization_on),
                        title: Text('₱${price.toStringAsFixed(2)}'),
                        subtitle: Text('Time: $formattedTime'),
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
