import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/screens/addinventorymodal.dart';
import 'package:trashure_thesis/screens/inventory/inventorydetails.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart';

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

  // Updated field definitions for Representative Name, Company Name, Payment Method, and Reference Number
  final TextEditingController representativeNameController =
      TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  String selectedPaymentMethod = 'Cash'; // Default to Cash
  final TextEditingController referenceNumberController =
      TextEditingController();

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

  Future<void> fetchInventory() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('inventory').get();

      List<Map<String, dynamic>> fetchedInventory = [];

      for (var doc in snapshot.docs) {
        String itemId = doc.id;
        String category = doc['category'] ?? 'N/A';
        String type = doc['type'] ?? 'N/A';
        double currentWeight = (doc['weight'] ?? 0.0).toDouble();

        // Fetch the weight history subcollection for this item
        QuerySnapshot weightHistorySnapshot = await FirebaseFirestore.instance
            .collection('inventory')
            .doc(itemId)
            .collection('weight_history')
            .orderBy('timestamp', descending: true)
            .get();

        double previousWeight = currentWeight;
        double totalAddWeight = 0.0;
        double totalMinusWeight = 0.0;

        // Get today's date without time
        DateTime today = DateTime.now();
        DateTime currentDateOnly = DateTime(today.year, today.month, today.day);

        // Iterate over weight history documents
        for (var historyDoc in weightHistorySnapshot.docs) {
          var historyData = historyDoc.data() as Map<String, dynamic>;
          String operation = historyData['operation'] ?? '';
          double weightChange = (historyData['weight'] ?? 0.0).toDouble();
          Timestamp timestamp = historyData['timestamp'] as Timestamp;
          DateTime historyDate = timestamp.toDate();

          // Extract only the date part
          DateTime historyDateOnly =
              DateTime(historyDate.year, historyDate.month, historyDate.day);

          // Compare only the date part
          if (historyDateOnly == currentDateOnly) {
            if (operation == 'add') {
              totalAddWeight += weightChange;
            } else if (operation == 'minus') {
              totalMinusWeight += weightChange;
            }
          }
        }

        // Calculate the previous weight
        previousWeight = currentWeight - totalAddWeight + totalMinusWeight;

        // Add the inventory item with the calculated previous weight
        fetchedInventory.add({
          'id': itemId,
          'category': category,
          'type': type,
          'weight': currentWeight,
          'previous_weight': previousWeight,
        });
      }

      setState(() {
        inventory = fetchedInventory;
        filteredInventory = inventory;
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

  // Function to fetch the latest original price for a specific product
  Future<double?> _fetchLatestOriginalPrice(String productType) async {
    try {
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('product_name',
              isEqualTo: productType.toLowerCase()) // Case-insensitive match
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        DocumentReference productRef = productSnapshot.docs.first.reference;

        QuerySnapshot priceSnapshot = await productRef
            .collection('prices')
            .orderBy('time', descending: true)
            .limit(1)
            .get();

        if (priceSnapshot.docs.isNotEmpty) {
          return priceSnapshot.docs.first['original_price']?.toDouble();
        }
      }
    } catch (e) {
      print('Error fetching original price: $e');
    }
    return null; // Return null if no original_price found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    Text(
                      'Inventory',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                        decoration: const InputDecoration(
                          hintText: 'Search by type or category',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddInventoryModal(),
                        );
                      },
                      child: const Text(
                        'Onsite Collection',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 58, 142, 225),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _openSellProductModal,
                      child: const Text(
                        'Sell Product',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bordered Container for Titles and List
                Container(
                  height: MediaQuery.of(context).size.height * .82,
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
                            title('Current Weight', 1),
                            title('Details', 1),
                          ],
                        ),
                      ),

                      const Divider(
                          height: 1, color: Colors.black), // Separator line
                      const SizedBox(height: 10),
                      // Use StreamBuilder to dynamically display inventory list
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('inventory')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
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
                                    textStyle: const TextStyle(
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
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
    String currentWeight = (item['weight'] ?? 0.0).toStringAsFixed(2);

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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currentWeight,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Center(
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryDetails(
                      itemId: item['id'],
                      itemType: item['type'],
                    ),
                  ),
                );
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
            title: const Text('No Items Selected'),
            content: const Text('Please select at least one item to sell.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Initialize controllers and data structures for managing product information
      final TextEditingController representativeNameController =
          TextEditingController();
      final TextEditingController descriptionController =
          TextEditingController();
      final TextEditingController companyNameController =
          TextEditingController();
      final TextEditingController referenceNumberController =
          TextEditingController();
      final TextEditingController deliveryFeeController =
          TextEditingController();
      String selectedPaymentMethod = 'Cash';
      final Map<String, TextEditingController> weightControllers = {};
      final Map<String, TextEditingController> priceControllers = {};
      final Map<String, double?> originalPrices = {};
      final Map<String, String?> errorMessages = {};

      // Fetch all original prices before showing the dialog
      for (var item in selectedItems) {
        String itemId = item['id'];
        String itemType =
            item['type'].toLowerCase(); // Convert to lowercase for comparison
        weightControllers[itemId] = TextEditingController();
        priceControllers[itemId] = TextEditingController();
        errorMessages[itemId] = null;

        double? latestOriginalPrice = await _fetchLatestOriginalPrice(itemType);
        if (latestOriginalPrice != null) {
          originalPrices[itemId] = latestOriginalPrice;
          priceControllers[itemId]!.text =
              latestOriginalPrice.toStringAsFixed(2); // Set price to TextField
        } else {
          originalPrices[itemId] = null; // No price available
        }
      }

      // Now that all data is ready, proceed to show the dialog
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sell Products',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Representative Name Field
                        TextField(
                          controller: representativeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Representative Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Company Name Field
                        TextField(
                          controller: companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Payment Method Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedPaymentMethod,
                          items: [
                            DropdownMenuItem(
                              value: 'Cash',
                              child: const Text('Cash'),
                            ),
                            DropdownMenuItem(
                              value: 'Online Payment',
                              child: const Text('Online Payment'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPaymentMethod = newValue ?? 'Cash';
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Reference Number Field (visible only for Online Payment)
                        if (selectedPaymentMethod == 'Online Payment')
                          TextField(
                            controller: referenceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: selectedItems.map((item) {
                                String itemId = item['id'];
                                String category = item['category'];
                                String type = item['type'];
                                double currentWeight = item['weight'];
                                double? originalPrice = originalPrices[itemId];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '$category - $type (Available: $currentWeight kg)'),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller:
                                                weightControllers[itemId],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Weight to sell (kg)',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 1,
                                          child: TextField(
                                            controller:
                                                priceControllers[itemId],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Enter Price per kg',
                                              hintText: originalPrice != null
                                                  ? '₱${originalPrice.toStringAsFixed(2)}' // Display original price as hint
                                                  : 'Enter Price per kg',
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (errorMessages[itemId] != null &&
                                        errorMessages[itemId]!.isNotEmpty)
                                      Text(
                                        errorMessages[itemId]!,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Buttons for Cancel and Confirm actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
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
                                      representativeNameController,
                                      companyNameController,
                                      descriptionController,
                                      selectedPaymentMethod,
                                      referenceNumberController,
                                      deliveryFeeController);
                                  Navigator.of(context)
                                      .pop(); // Close the modal after processing
                                }
                              },
                              child: const Text('Confirm Sell'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ));
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
      TextEditingController representativeNameController,
      TextEditingController companyNameController,
      TextEditingController descriptionController,
      String selectedPaymentMethod,
      TextEditingController deliveryFeeController,
      TextEditingController referenceNumberController) async {
    double overallTotal = 0.0;
    List<Map<String, dynamic>> soldItems = [];

    // Retrieve the authorized_by username from UserModel
    String authorizedBy =
        Provider.of<UserModel>(context, listen: false).userName;

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

    // Add inflow entry with the updated fields, including `authorized_by`
    DocumentReference inflowRef =
        await FirebaseFirestore.instance.collection('inflow').add({
      'authorized_by': authorizedBy,
      'representative_name': representativeNameController.text.isNotEmpty
          ? representativeNameController.text
          : 'N/A',
      'company_name': companyNameController.text.isNotEmpty
          ? companyNameController.text
          : 'N/A',
      'date': FieldValue.serverTimestamp(),
      'overall_total': overallTotal,
      'payment_method': selectedPaymentMethod,
      'reference_number': selectedPaymentMethod == 'Online Payment'
          ? referenceNumberController.text
          : null,
    });

    // Add sold items to the 'sold' subcollection under the inflow document
    for (var soldItem in soldItems) {
      await inflowRef.collection('sold').add(soldItem);
    }
    // Check if delivery fee is greater than 0 and create outflow document
    double deliveryFee = double.tryParse(deliveryFeeController.text) ?? 0.0;
    if (deliveryFee > 0) {
      try {
        await _addOutflowDocument(
          authorizedBy: authorizedBy,
          deliveryFee: deliveryFee,
        );
        print("Outflow document created successfully for delivery fee.");
      } catch (e) {
        print("Error creating outflow document: $e");
      }
    }
  }

  Future<void> _addOutflowDocument({
    required String authorizedBy,
    required double deliveryFee,
  }) async {
    Map<String, dynamic> outflowData = {
      'authorized_by': authorizedBy,
      'amount': deliveryFee,
      'timestamp': FieldValue.serverTimestamp(),
      'category': 'Delivery Fee',
    };

    print("Attempting to create outflow document with data: $outflowData");

    await FirebaseFirestore.instance.collection('outflow').add(outflowData);

    print("Outflow document created successfully with data: $outflowData");
  }
}
