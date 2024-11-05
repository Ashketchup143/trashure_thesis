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
        'unit': data['unit'],
        'picture': data['picture'],
      };
    }).toList();
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

    String normalizedType = type.toLowerCase();

    QuerySnapshot inventoryDocs =
        await inventory.where('type', isEqualTo: normalizedType).limit(1).get();

    if (inventoryDocs.docs.isEmpty) {
      inventoryDocs = await inventory
          .where('type_lowercase', isEqualTo: normalizedType)
          .limit(1)
          .get();
    }

    if (inventoryDocs.docs.isNotEmpty) {
      DocumentReference typeDoc = inventoryDocs.docs.first.reference;

      await typeDoc.update({
        'weight': FieldValue.increment(weight),
      });

      await typeDoc.collection('weight_history').add({
        'weight': weight,
        'operation': 'add',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      DocumentReference newDocRef = await inventory.add({
        'category': category,
        'type': type,
        'type_lowercase': normalizedType,
        'weight': weight,
      });

      await newDocRef.collection('weight_history').add({
        'weight': weight,
        'operation': 'add',
        'timestamp': FieldValue.serverTimestamp(),
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

    DocumentReference onsiteCollectionRef =
        await FirebaseFirestore.instance.collection('onsite_collections').add({
      'overall_price': overallPrice,
      'overall_weight': overallWeight,
      'date': FieldValue.serverTimestamp(),
      'authorized_by': userName,
    });

    for (var recyclable in recyclables) {
      await onsiteCollectionRef.collection('recyclables').add(recyclable);
    }

    await FirebaseFirestore.instance.collection('outflow').add({
      'collectionId': onsiteCollectionRef.id,
      'category': 'onsite collection',
      'date': FieldValue.serverTimestamp(),
      'employee': userName,
      'price': overallPrice,
      'status': 'pending',
      'weight': overallWeight,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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
              child: Text('OK'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection(int index) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!
            .where((product) => !selectedProducts.any((selected) =>
                selected['productId'] == product['product_id'] &&
                selected['productId'] != selectedProducts[index]['productId']))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedProducts[index]['productId'],
              hint: const Text('Select Product'),
              isExpanded: true,
              items: products.map((product) {
                return DropdownMenuItem<String>(
                  value: product['product_id'],
                  child: Text(
                    "${product['product_name'].toString().toLowerCase()} (${product['category'].toString().toLowerCase()})",
                  ),
                );
              }).toList(),
              onChanged: (selectedProductId) async {
                double latestPrice =
                    await _fetchLatestPrice(selectedProductId!);

                setState(() {
                  selectedProducts[index]['productId'] = selectedProductId;
                  selectedProducts[index]['price'] = latestPrice;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: selectedProducts[index]['weightController'],
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {}); // Recalculate total when weight changes
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _removeProduct(index);
                  },
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (selectedProducts[index]['productId'] != null &&
                selectedProducts[index]['price'] != 0.0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price per unit: ₱${selectedProducts[index]['price'].toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total: ₱${_calculateTotalPrice(index).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  double _calculateTotalPrice(int index) {
    double weight = double.tryParse(
            selectedProducts[index]['weightController']?.text ?? '0') ??
        0;
    double pricePerUnit = selectedProducts[index]['price'];
    return weight * pricePerUnit;
  }
}
