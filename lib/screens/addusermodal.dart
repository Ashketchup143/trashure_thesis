import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserModal extends StatefulWidget {
  final String bookingId;

  AddUserModal({required this.bookingId});

  @override
  _AddUserModalState createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  List<Map<String, dynamic>> selectedProducts = [];
  CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  List<Map<String, dynamic>> productsList = [];
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchProducts().then((products) {
      setState(() {
        productsList = products;
        if (products.isNotEmpty) {
          addProduct(); // Add the first product entry by default
        }
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    QuerySnapshot snapshot = await _productsCollection.get();
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        'product_id': doc.id,
        'product_name': data['product_name'],
        'category': data['category'],
        'details': data['details'],
      };
    }).toList();
  }

  // Fetch the latest price from the 'prices' subcollection
  Future<double> _fetchLatestPrice(String productId) async {
    QuerySnapshot priceSnapshot = await _productsCollection
        .doc(productId)
        .collection('prices')
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (priceSnapshot.docs.isNotEmpty) {
      return priceSnapshot.docs.first['price'] ?? 0.0;
    }
    return 0.0;
  }

  void addProduct() {
    setState(() {
      selectedProducts.add({
        'productId': null,
        'weightController': TextEditingController(),
        'price': 0.0, // Default price as 0.0
      });
    });
  }

  void _removeProduct(int index) {
    setState(() {
      selectedProducts.removeAt(index);
    });
  }

  Future<void> _addUserWithProducts() async {
    // Reset error message
    setState(() {
      errorMessage = "";
    });

    // Validate products and weights
    if (selectedProducts.isEmpty ||
        selectedProducts.any((product) =>
            product['productId'] == null ||
            product['weightController'].text.isEmpty ||
            double.tryParse(product['weightController'].text) == null ||
            double.parse(product['weightController'].text) <= 0)) {
      setState(() {
        errorMessage = "Please select a product and enter a valid weight.";
      });
      return;
    }

    var userRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('users')
        .doc(); // Generate a new document ID for the user

    List<Map<String, dynamic>> recyclables = [];

    // Loop through the selected products and gather their data
    for (var productInfo in selectedProducts) {
      var productId = productInfo['productId'];
      var product = productsList.firstWhere(
          (element) => element['product_id'] == productId,
          orElse: () => {});
      var weight = double.tryParse(productInfo['weightController'].text) ?? 0.0;
      var price = productInfo['price'];

      if (productId != null) {
        recyclables.add({
          'type': product['product_name'].toString().toUpperCase(),
          'weight': weight,
          'price': price,
          'item_price': weight * price,
          'category': product['category'],
          'details': product['details'],
        });
      }
    }

    // Calculate total price and total weight safely
    double totalPrice = recyclables.fold(0.0, (prev, item) {
      double itemPrice = (item['item_price'] as double?) ?? 0.0;
      return prev + itemPrice;
    });

    double totalWeight = recyclables.fold(0.0, (prev, item) {
      double itemWeight = (item['weight'] as double?) ?? 0.0;
      return prev + itemWeight;
    });

    // Calculate calculated_total_price
    double calculatedTotalPrice = totalPrice - 40;

    // Add the user with their recyclables
    await userRef.set({
      'firstName': 'Guest',
      'lastName': '',
      'status': 'pending',
      'total_price': totalPrice, // Store total price
      'total_weight': totalWeight, // Store total weight
      'calculated_total_price':
          calculatedTotalPrice, // Store calculated total price
    });

    // Add each recyclable under the user's subcollection
    for (var recyclable in recyclables) {
      await userRef.collection('recyclables').add(recyclable);
    }

    Navigator.pop(context); // Close the modal after adding the user
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total price and weight for all selected products
    double totalPrice = selectedProducts.fold(0.0, (sum, product) {
      double weight =
          double.tryParse(product['weightController']?.text ?? '0') ?? 0.0;
      double price = product['price'] ?? 0.0;
      return sum + (weight * price);
    });

    double totalWeight = selectedProducts.fold(0.0, (sum, product) {
      return sum +
          (double.tryParse(product['weightController']?.text ?? '0') ?? 0.0);
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * .8,
        width: MediaQuery.of(context).size.width * .8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Guest User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectedProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductSelection(index);
                },
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: addProduct,
                  icon: Icon(Icons.add),
                  color: Colors.green,
                ),
                Text('Add another product'),
              ],
            ),
            SizedBox(height: 20),

            // Display Total Weight and Total Price below "Add Another Product" button
            Divider(),
            Text(
              'Total Weight: ${totalWeight.toStringAsFixed(2)} kg',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Divider(),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addUserWithProducts,
              child: Text('Add User'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection(int index) {
    // Calculate the total price and weight for all selected products
    double totalPrice = selectedProducts.fold(0.0, (sum, product) {
      double weight =
          double.tryParse(product['weightController']?.text ?? '0') ?? 0.0;
      double price = product['price'] ?? 0.0;
      return sum + (weight * price);
    });

    double totalWeight = selectedProducts.fold(0.0, (sum, product) {
      return sum +
          (double.tryParse(product['weightController']?.text ?? '0') ?? 0.0);
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Category Dropdown with decoration
      InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select Category',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButton<String>(
          value: selectedProducts[index]['category'],
          hint: Text('Select Category'),
          isExpanded: true,
          underline: SizedBox(), // Remove default underline
          items: productsList
              .map((product) => product['category'])
              .toSet()
              .map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (selectedCategory) {
            setState(() {
              selectedProducts[index]['category'] = selectedCategory;
              selectedProducts[index]['productId'] =
                  null; // Reset product selection
            });
          },
        ),
      ),
      SizedBox(height: 10),

      // Product Dropdown with decoration
      InputDecorator(
        decoration: InputDecoration(
          labelText: 'Select Product',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: DropdownButton<String>(
          value: selectedProducts[index]['productId'],
          hint: Text('Select Product'),
          isExpanded: true,
          underline: SizedBox(), // Remove default underline
          items: productsList.where((product) {
            // Filter products by the selected category and prevent duplicate additions
            return product['category'] == selectedProducts[index]['category'] &&
                !selectedProducts.any((selectedProduct) =>
                    selectedProduct['productId'] == product['product_id'] &&
                    selectedProducts[index]['productId'] !=
                        product['product_id']);
          }).map((product) {
            return DropdownMenuItem<String>(
              value: product['product_id'],
              child: Text(product['product_name']),
            );
          }).toList(),
          onChanged: (selectedProductId) async {
            double latestPrice = await _fetchLatestPrice(selectedProductId!);

            setState(() {
              selectedProducts[index]['productId'] = selectedProductId;
              selectedProducts[index]['price'] = latestPrice;
            });
          },
        ),
      ),
      SizedBox(height: 10),

      // Latest Price Display
      Text(
        'Latest Price: ₱${selectedProducts[index]['price'].toStringAsFixed(2)}',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),

      // Weight Input
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: selectedProducts[index]['weightController'],
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {}); // Update totals when weight changes
              },
            ),
          ),
          IconButton(
            onPressed: () {
              _removeProduct(index);
            },
            icon: Icon(Icons.delete),
            color: Colors.red,
          ),
        ],
      ),
      SizedBox(height: 10),
    ]);
  }
}
