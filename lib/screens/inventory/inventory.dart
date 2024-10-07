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
                      // Filtered Inventory List
                      filteredInventory.isEmpty
                          ? Padding(
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
                            )
                          : ListView.builder(
                              shrinkWrap: true, // Required for Column to work
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: filteredInventory.length,
                              itemBuilder: (context, index) {
                                final item = filteredInventory[index];
                                return _buildCustomCheckboxTile(item);
                              },
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
    String weight = item['weight'].toString() ?? 'N/A';

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
}
