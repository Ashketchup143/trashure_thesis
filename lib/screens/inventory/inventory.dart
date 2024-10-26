import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> inventory = []; // Stores the data from Firestore
  List<Map<String, dynamic>> filteredInventory = [];
  Map<String, bool> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    fetchInventory(); // Fetch data from Firestore
    _searchController.addListener(() {
      _filterInventory(); // Add listener to filter based on search input
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to fetch inventory data from Firestore
  Future<void> fetchInventory() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('inventory').get();

      // Extract and map Firestore documents to a List of Maps
      List<Map<String, dynamic>> fetchedInventory = snapshot.docs.map((doc) {
        return {
          'id': doc.id, // Use the document ID
          'category': doc['category'] ?? 'N/A',
          'type': doc['type'] ?? 'N/A',
          'weight': doc['weight'] ?? 0.0,
        };
      }).toList();

      setState(() {
        inventory = fetchedInventory;
        filteredInventory = inventory; // Initially show all inventory items
      });
    } catch (e) {
      print('Error fetching inventory: $e');
    }
  }

  // Method to filter the inventory based on the search input
  void _filterInventory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredInventory = inventory.where((item) {
        final category = item['category']?.toLowerCase() ?? '';
        final type = item['type']?.toLowerCase() ?? '';
        return category.contains(query) || type.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    Text(
                      'Inventory',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Search Bar
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 430,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(17.5),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by type or category',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    Spacer(), // Push the button to the right
                    ElevatedButton(
                      onPressed: _openSellProductModal,
                      child: Text(
                        'Sell Product',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Bordered Container for Titles and List
                Container(
                  height: MediaQuery.of(context).size.height * .8,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    border: Border.all(), // Add border
                  ),
                  child: Column(
                    children: [
                      // Inventory Titles
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            title('Category', 2),
                            title('Type', 2),
                            title('Weight', 1),
                            title('Details', 1),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.black), // Separator line
                      SizedBox(height: 10),
                      // Use StreamBuilder to dynamically display inventory list
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('inventory')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            var fetchedInventory =
                                snapshot.data?.docs.map((doc) {
                              return {
                                'id': doc.id,
                                'category': doc['category'] ?? 'N/A',
                                'type': doc['type'] ?? 'N/A',
                                'weight': doc['weight'] ?? 0.0,
                              };
                            }).toList();

                            filteredInventory = fetchedInventory ?? [];

                            if (_searchController.text.isNotEmpty) {
                              filteredInventory =
                                  filteredInventory.where((item) {
                                final category =
                                    item['category']?.toLowerCase() ?? '';
                                final type = item['type']?.toLowerCase() ?? '';
                                final query =
                                    _searchController.text.toLowerCase();
                                return category.contains(query) ||
                                    type.contains(query);
                              }).toList();
                            }

                            if (filteredInventory.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'No items found',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filteredInventory.length,
                              itemBuilder: (context, index) {
                                final item = filteredInventory[index];
                                return _buildCustomCheckboxTile(item);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for rendering titles
  Widget title(String text, int fl) {
    return Expanded(
      flex: fl,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Custom CheckboxTile for each inventory item
  Widget _buildCustomCheckboxTile(Map<String, dynamic> item) {
    String itemId = item['id'] ?? 'N/A';
    String category = item['category'] ?? 'N/A';
    String type = item['type'] ?? 'N/A';
    String weight = item['weight'].toStringAsFixed(2) ?? 'N/A';

    if (_selectedOptions[itemId] == null) {
      _selectedOptions[itemId] = false;
    }

    return CheckboxListTile(
      value: _selectedOptions[itemId],
      activeColor: Colors.green,
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[itemId] = value ?? false;
        });
      },
      title: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              weight,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                // Handle navigation to item details
              },
            ),
          ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      selectedTileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  void _openSellProductModal() async {
    final selectedItems = filteredInventory
        .where((item) => _selectedOptions[item['id']] == true)
        .toList();

    if (selectedItems.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Items Selected'),
            content: Text('Please select at least one item to sell.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      final TextEditingController customerNameController =
          TextEditingController();
      final TextEditingController descriptionController =
          TextEditingController();
      final TextEditingController paymentMethodController =
          TextEditingController();
      final Map<String, TextEditingController> weightControllers = {};
      final Map<String, TextEditingController> priceControllers = {};
      final Map<String, double?> originalPrices = {}; // Store original prices
      final Map<String, double?> percentageProfits =
          {}; // Store percentage profits
      final Map<String, double?> suggestedPrices = {}; // Store final prices
      final Map<String, String?> errorMessages = {}; // To hold error messages

      // Initialize the controllers for each selected item and fetch the most recent prices
      for (var item in selectedItems) {
        weightControllers[item['id']] = TextEditingController();
        priceControllers[item['id']] = TextEditingController();
        errorMessages[item['id']] = null; // Initialize empty error messages

        // Fetch the most recent price from Firestore subcollection 'prices'
        final recentPriceSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(item['id']) // Assuming the item ID matches the product ID
            .collection('prices')
            .orderBy('time', descending: true)
            .limit(1) // Get the most recent price based on the 'time' field
            .get();

        // Store the most recent price details if found
        if (recentPriceSnapshot.docs.isNotEmpty) {
          final recentPriceData = recentPriceSnapshot.docs.first.data();
          originalPrices[item['id']] =
              recentPriceData['original_price']?.toDouble();
          percentageProfits[item['id']] =
              recentPriceData['percentage_profit']?.toDouble();
          suggestedPrices[item['id']] = recentPriceData['price']?.toDouble();
        } else {
          originalPrices[item['id']] = null; // If no price found, set to null
          percentageProfits[item['id']] = null;
          suggestedPrices[item['id']] = null;
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                insetPadding:
                    EdgeInsets.symmetric(horizontal: 50), // Make it wider
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // Set modal width
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sell Products',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Additional fields for customer name, description, and payment method
                      TextField(
                        controller: customerNameController,
                        decoration: InputDecoration(
                          labelText: 'Customer Name (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: paymentMethodController,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: selectedItems.map((item) {
                              String itemId = item['id'];
                              String category = item['category'];
                              String type = item['type'];
                              double currentWeight = item['weight'];
                              double? originalPrice = originalPrices[itemId];
                              double? percentageProfit =
                                  percentageProfits[itemId];
                              double? suggestedPrice = suggestedPrices[itemId];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '$category - $type (Available: $currentWeight kg)'),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller: weightControllers[itemId],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Weight to sell (kg)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller: priceControllers[itemId],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: originalPrice != null
                                                ? 'Original Price: ₱$originalPrice'
                                                : 'Enter Price per kg',
                                            border: OutlineInputBorder(),
                                            // Suggest original_price in price field if available
                                          ),
                                          // Prefill the original price in the text field if available
                                          onTap: () {
                                            if (originalPrice != null) {
                                              priceControllers[itemId]!.text =
                                                  originalPrice.toString();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  if (percentageProfit != null &&
                                      suggestedPrice != null)
                                    Text(
                                      'Profit: ${percentageProfit.toStringAsFixed(2)}%, Suggested Price: ₱$suggestedPrice',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  if (errorMessages[itemId] != null &&
                                      errorMessages[itemId]!.isNotEmpty)
                                    Text(
                                      errorMessages[itemId]!,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  SizedBox(height: 20),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Buttons for Cancel and Confirm actions, directly added within the dialog content
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Validate input before proceeding to sell the product
                              bool isValid = _validateSellProductInput(
                                  selectedItems,
                                  weightControllers,
                                  priceControllers,
                                  errorMessages,
                                  setState);

                              if (isValid) {
                                _sellProduct(
                                    selectedItems,
                                    weightControllers,
                                    priceControllers,
                                    customerNameController,
                                    descriptionController,
                                    paymentMethodController);
                                Navigator.of(context)
                                    .pop(); // Close the modal after processing
                              }
                            },
                            child: Text('Confirm Sell'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

// Function to validate sell product input
  bool _validateSellProductInput(
      List<Map<String, dynamic>> selectedItems,
      Map<String, TextEditingController> weightControllers,
      Map<String, TextEditingController> priceControllers,
      Map<String, String?> errorMessages,
      Function(void Function()) setState) {
    bool isValid = true;

    for (var item in selectedItems) {
      String itemId = item['id'];
      double currentWeight = item['weight'];
      double? inputWeight =
          double.tryParse(weightControllers[itemId]?.text ?? '');
      double? inputPrice =
          double.tryParse(priceControllers[itemId]?.text ?? '');

      if (inputWeight == null ||
          inputWeight <= 0 ||
          inputWeight > currentWeight) {
        setState(() {
          errorMessages[itemId] = 'Invalid weight. Check available inventory.';
        });
        isValid = false;
      } else if (inputPrice == null || inputPrice <= 0) {
        setState(() {
          errorMessages[itemId] = 'Invalid price. Please enter a valid number.';
        });
        isValid = false;
      } else {
        setState(() {
          errorMessages[itemId] = ''; // Clear the error if validation passes
        });
      }
    }

    return isValid;
  }

  Future<void> _sellProduct(
      List<Map<String, dynamic>> selectedItems,
      Map<String, TextEditingController> weightControllers,
      Map<String, TextEditingController> priceControllers,
      TextEditingController customerNameController,
      TextEditingController descriptionController,
      TextEditingController paymentMethodController) async {
    double overallTotal = 0.0;
    List<Map<String, dynamic>> soldItems = [];

    for (var item in selectedItems) {
      String itemId = item['id'];
      double currentWeight = item['weight'];
      double inputWeight =
          double.tryParse(weightControllers[itemId]?.text ?? '0') ?? 0;
      double inputPrice =
          double.tryParse(priceControllers[itemId]?.text ?? '0') ?? 0;

      double itemTotal = inputWeight * inputPrice;
      overallTotal += itemTotal;

      // Update the inventory in Firestore
      DocumentReference itemDoc =
          FirebaseFirestore.instance.collection('inventory').doc(itemId);

      await itemDoc.update({
        'weight': FieldValue.increment(-inputWeight), // Subtract the weight
      });

      // Add entry to the weight_history subcollection
      await itemDoc.collection('weight_history').add({
        'weight': inputWeight,
        'operation': 'minus',
        'price': inputPrice,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add sold item details
      soldItems.add({
        'type': item['type'],
        'weight': inputWeight,
        'price': inputPrice,
        'item_total': itemTotal,
      });
    }

    // Add inflow entry without 'authorized_by'
    DocumentReference inflowRef =
        await FirebaseFirestore.instance.collection('inflow').add({
      'customer_name': customerNameController.text.isNotEmpty
          ? customerNameController.text
          : 'N/A',
      'date': FieldValue.serverTimestamp(),
      'description': descriptionController.text.isNotEmpty
          ? descriptionController.text
          : 'N/A',
      'overall_total': overallTotal,
      'payment_method': paymentMethodController.text.isNotEmpty
          ? paymentMethodController.text
          : 'N/A',
    });

    // Add sold items to the subcollection 'sold'
    for (var soldItem in soldItems) {
      await inflowRef.collection('sold').add(soldItem);
    }
  }
}
