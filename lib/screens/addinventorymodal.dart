import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart';

class AddInventoryModal extends StatefulWidget {
  @override
  _AddInventoryModalState createState() => _AddInventoryModalState();
}

class _AddInventoryModalState extends State<AddInventoryModal> {
  List<Map<String, dynamic>> selectedProducts = [];
  CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  List<Map<String, dynamic>> productsList = [];
  String errorMessage = "";
  List<String> categoriesList = [];
  String? selectedCategory;

  double totalWeight = 0.0;
  double totalPrice = 0.0;
  @override
  void initState() {
    super.initState();
    fetchCategories().then((categories) {
      setState(() {
        categoriesList = categories;
      });
    });

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
        'unit': data['unit'],
        'picture': data['picture'],
      };
    }).toList();
  }

  Future<List<String>> fetchCategories() async {
    QuerySnapshot snapshot = await _productsCollection.get();

    Set<String> categories = snapshot.docs
        .map((doc) =>
            (doc.data() as Map<String, dynamic>)['category'] as String? ??
            'Other')
        .toSet();
    return categories.toList();
  }

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
        'category': null,
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

  Future<void> _addOrUpdateInventory({
    required String type,
    required String category,
    required double weight,
  }) async {
    CollectionReference inventory =
        FirebaseFirestore.instance.collection('inventory');

    // Normalize the type to lowercase before storing it
    String normalizedType = type.toLowerCase();

    // Query inventory for the type in lowercase
    QuerySnapshot inventoryDocs =
        await inventory.where('type', isEqualTo: normalizedType).limit(1).get();

    if (inventoryDocs.docs.isNotEmpty) {
      // If the type already exists, update the weight
      DocumentReference typeDoc = inventoryDocs.docs.first.reference;

      await typeDoc.update({
        'weight': FieldValue.increment(weight),
      });

      // Add weight change to weight history
      await typeDoc.collection('weight_history').add({
        'weight': weight,
        'operation': 'add',
        'timestamp': FieldValue.serverTimestamp(),
        'category': 'Onsite Collection',
      });
    } else {
      // If the type doesn't exist, create a new document
      DocumentReference newDocRef = await inventory.add({
        'category': category,
        'type': normalizedType, // Store type in lowercase
        'weight': weight,
      });

      // Add the weight change to weight history
      await newDocRef.collection('weight_history').add({
        'weight': weight,
        'operation': 'add',
        'timestamp': FieldValue.serverTimestamp(),
        'category': 'Onsite Collection',
      });
    }
  }

  Future<void> _addProductsToInventory() async {
    setState(() {
      errorMessage = "";
    });

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

    double overallPrice = 0.0;
    double overallWeight = 0.0;
    List<Map<String, dynamic>> recyclables = [];

    for (var productInfo in selectedProducts) {
      var productId = productInfo['productId'];
      var product = productsList.firstWhere(
          (element) => element['product_id'] == productId,
          orElse: () => {});
      var weightToAdd =
          double.tryParse(productInfo['weightController'].text) ?? 0.0;

      overallWeight += weightToAdd;
      overallPrice += weightToAdd * productInfo['price'];

      recyclables.add({
        'type': product['product_name'],
        'weight': weightToAdd,
        'price': productInfo['price'],
        'category': product['category'] ?? 'recyclables',
      });

      await _addOrUpdateInventory(
        type: product['product_name'],
        category: product['category'] ?? 'recyclables',
        weight: weightToAdd,
      );
    }

    String userName = Provider.of<UserModel>(context, listen: false).userName;

    // Add document to 'outflow' collection
    DocumentReference outflowRef =
        await FirebaseFirestore.instance.collection('outflow').add({
      'category': 'onsite collection',
      'date': FieldValue.serverTimestamp(),
      'employee': userName,
      'price': overallPrice,
      'status': 'pending',
      'weight': overallWeight,
    });

    // Add each recyclable item to the 'recyclables' subcollection of 'outflow'
    for (var recyclable in recyclables) {
      await outflowRef.collection('recyclables').add({
        'type': recyclable['type'],
        'weight': recyclable['weight'],
        'price': recyclable['price'],
        'category': recyclable['category'],
      });
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'You have successfully added the following items to the inventory:'),
              const SizedBox(height: 10),
              ...recyclables.map((recyclable) => Text(
                    "- ${recyclable['type']} (${recyclable['weight']} kg) at ₱${recyclable['price'].toStringAsFixed(2)} per unit",
                  )),
              const SizedBox(height: 10),
              Text('Total Weight: ${overallWeight.toStringAsFixed(2)} kg'),
              Text('Total Price: ₱${overallPrice.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(); // Close the modal after confirmation
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * .8,
        width: MediaQuery.of(context).size.width * .8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Products to Inventory',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                  icon: const Icon(Icons.add),
                  color: Colors.green,
                ),
                const Text('Add another product'),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProductsToInventory,
              child: const Text('Add to Inventory'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Weight: ${totalWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Dropdown
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Select Product',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: DropdownButton<String>(
            value: selectedProducts[index]['category'],
            hint: Text('Select Category'),
            isExpanded: true,
            underline: SizedBox(),
            items: categoriesList.map((category) {
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

        // Product Dropdown
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
            underline: SizedBox(),
            items: productsList.where((product) {
              return product['category'] == selectedProducts[index]['category'];
            }).map((product) {
              return DropdownMenuItem<String>(
                value: product['product_id'],
                child: Text("${product['product_name']}"),
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
          'Price per unit: ₱${selectedProducts[index]['price'].toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        SizedBox(height: 5),

        // Weight Input and Total Price Display
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
                  setState(() {
                    _calculateTotals(); // Recalculate totals when weight changes
                  });
                },
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Total: ₱${_calculateTotalPrice(index).toStringAsFixed(2)}',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  double _calculateTotalPrice(int index) {
    double weight = double.tryParse(
            selectedProducts[index]['weightController']?.text ?? '0') ??
        0;
    double pricePerUnit = selectedProducts[index]['price'];
    return weight * pricePerUnit;
  }

  void _calculateTotals() {
    totalWeight = selectedProducts.fold(0.0, (sum, product) {
      double weight =
          double.tryParse(product['weightController']?.text ?? '0') ?? 0.0;
      return sum + weight;
    });

    totalPrice = selectedProducts.fold(0.0, (sum, product) {
      double weight =
          double.tryParse(product['weightController']?.text ?? '0') ?? 0.0;
      double price = product['price'] ?? 0.0;
      return sum + (weight * price);
    });
  }
}
