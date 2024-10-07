import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart'; // Import your custom sidebar

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('category');

  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _allProducts = [];
  List<DocumentSnapshot> _filteredProducts = [];
  List<DocumentSnapshot> _allCategories = [];
  String _searchTerm = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchProducts() async {
    QuerySnapshot snapshot = await _productsCollection.get();
    setState(() {
      _allProducts = snapshot.docs;
      _filteredProducts = _allProducts;
    });
  }

  Future<void> _fetchCategories() async {
    QuerySnapshot snapshot = await _categoryCollection.get();
    setState(() {
      _allCategories = snapshot.docs;
    });
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

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text.trim().toLowerCase();
      _filteredProducts = _allProducts.where((product) {
        String productName = product['product_name'].toString().toLowerCase();
        String category = product['category'].toString().toLowerCase();
        return productName.contains(_searchTerm) ||
            category.contains(_searchTerm);
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
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Row(
                        children: [
                          IconButton(
                            icon:
                                Icon(Icons.menu, color: Colors.green, size: 25),
                            onPressed: () {
                              Scaffold.of(context)
                                  .openDrawer(); // Opens the drawer
                            },
                          ),
                          Text(
                            'Settings',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
                                hintText: 'Search by product name or category',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                _onSearchChanged();
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              _showAddProductDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF4F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              textStyle: TextStyle(fontSize: 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 8),
                                Text(
                                  'Add Product',
                                  style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white)),
                                ),
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              _showAddCategoryDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0062FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              textStyle: TextStyle(fontSize: 16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 8),
                                Text(
                                  'Add Category',
                                  style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white)),
                                ),
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all()),
                          child: Column(
                            children: [
                              Container(
                                color: Colors.grey[300],
                                child: Row(
                                  children: [
                                    _titleCell('Product Name', 3),
                                    _titleCell('Category', 2),
                                    _titleCell('Price', 2),
                                    _titleCell('Details', 4),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _filteredProducts.isEmpty
                                    ? Center(child: Text('No products found'))
                                    : ListView.builder(
                                        itemCount: _filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          var product =
                                              _filteredProducts[index];
                                          String productId = product.id;
                                          String productName =
                                              product['product_name'];
                                          String category = product['category'];
                                          String unit = product['unit'];
                                          String details = product['details'];
                                          String picture = product['picture'];

                                          return FutureBuilder<double>(
                                            future:
                                                _fetchLatestPrice(productId),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }
                                              if (snapshot.hasError) {
                                                return Text(
                                                    'Error fetching price');
                                              }
                                              double price =
                                                  snapshot.data ?? 0.0;

                                              return _buildProductTile(
                                                  productId,
                                                  productName,
                                                  category,
                                                  price,
                                                  unit,
                                                  details,
                                                  picture);
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleCell(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
                textStyle: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  String _truncateDetails(String details, {int limit = 10}) {
    if (details.split(' ').length > limit) {
      return details.split(' ').take(limit).join(' ') + '...';
    }
    return details;
  }

  Widget _buildProductTile(
      String productId,
      String productName,
      String category,
      double price,
      String unit,
      String details,
      String picture) {
    return ListTile(
      leading: picture.isNotEmpty
          ? ClipOval(
              child: Image.network(
                picture,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          : Icon(Icons.image_not_supported, size: 50),
      title: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              productName,
              style: GoogleFonts.poppins(
                  textStyle: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 2,
            child: Text(category),
          ),
          Expanded(
            flex: 2,
            child: Text('Php${price}/${unit}'),
          ),
          Expanded(
            flex: 4,
            child: Text(_truncateDetails(details)),
          ),
        ],
      ),
      tileColor: Color.fromARGB(255, 255, 255, 255),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditProductDialog(context, productId, productName, category,
                  price.toString(), unit, details, picture);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteProductDialog(context, productId);
            },
          ),
        ],
      ),
    );
  }

  // Function to show a dialog to add a new category
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF4F),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF4F),
              ),
              onPressed: () async {
                String categoryName =
                    categoryController.text.trim().toLowerCase();

                if (categoryName.isNotEmpty) {
                  // Add the new category to the 'category' collection
                  await FirebaseFirestore.instance.collection('category').add({
                    'category_name': categoryName,
                  });
                  // Refresh the product list or categories if needed
                }
                Navigator.of(context).pop();
              },
              child: Text('Add Category'),
            ),
          ],
        );
      },
    );
  }

  // Edit product dialog
  void _showEditProductDialog(
      BuildContext context,
      String productId,
      String productName,
      String category,
      String price,
      String unit,
      String details,
      String picture) {
    final TextEditingController productNameController =
        TextEditingController(text: productName);
    final TextEditingController priceController =
        TextEditingController(text: price);
    final TextEditingController detailsController =
        TextEditingController(text: details);
    final TextEditingController imageUrlController =
        TextEditingController(text: picture);

    String _selectedCategory = category; // Default category value
    String _selectedUnit = unit; // Default unit value

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  TextField(
                    controller: productNameController,
                    decoration: InputDecoration(labelText: 'Product Name'),
                  ),
                  SizedBox(height: 10),
                  // Dropdown for Category
                  DropdownButtonFormField<String>(
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
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  // Dropdown for Unit
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedUnit = newValue!;
                      });
                    },
                    items: ['kg', 'g', 'ton'].map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Unit'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: detailsController,
                    decoration: InputDecoration(labelText: 'Details'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: imageUrlController,
                    decoration:
                        InputDecoration(labelText: 'Image URL (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () async {
                String newProductName = productNameController.text.trim();
                double newPrice =
                    double.tryParse(priceController.text.trim()) ?? 0;
                String newDetails = detailsController.text.trim();
                String newImageUrl = imageUrlController.text.trim();

                DocumentReference productRef =
                    _productsCollection.doc(productId);

                if (newProductName.isNotEmpty && _selectedCategory.isNotEmpty) {
                  await productRef.update({
                    'product_name': newProductName,
                    'category': _selectedCategory, // Updated category
                    'unit': _selectedUnit, // Updated unit
                    'details': newDetails,
                    'picture': newImageUrl,
                  });

                  // Check if price has changed and add to 'prices' subcollection
                  if (newPrice != double.parse(price)) {
                    await productRef.collection('prices').add({
                      'price': newPrice,
                      'time': FieldValue.serverTimestamp(),
                    });
                  }

                  _fetchProducts(); // Refresh products after editing
                }
                Navigator.of(context).pop();
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog to add a new product
  void _showAddProductDialog(BuildContext context) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();
    String _selectedUnit = 'kg'; // Default unit

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Product'),
          content: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  TextField(
                    controller: productNameController,
                    decoration: InputDecoration(labelText: 'Product Name'),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    items: _allCategories.map((categoryDoc) {
                      return DropdownMenuItem<String>(
                        value: categoryDoc['category_name'],
                        child: Text(categoryDoc['category_name']),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedUnit = newValue!;
                      });
                    },
                    items: ['kg', 'g', 'ton'].map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Unit'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: detailsController,
                    decoration: InputDecoration(labelText: 'Details'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: imageUrlController,
                    decoration:
                        InputDecoration(labelText: 'Image URL (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () async {
                String productName = productNameController.text.trim();
                double price =
                    double.tryParse(priceController.text.trim()) ?? 0;
                String details = detailsController.text.trim();
                String imageUrl = imageUrlController.text.trim();

                if (productName.isNotEmpty && _selectedCategory != null) {
                  DocumentReference productRef = await _productsCollection.add({
                    'product_name': productName,
                    'category': _selectedCategory,
                    'details': details,
                    'picture': imageUrl,
                    'unit': _selectedUnit, // Unit from dropdown
                  });

                  // Add the price to the subcollection 'prices'
                  await productRef.collection('prices').add({
                    'price': price,
                    'time': FieldValue.serverTimestamp(),
                  });

                  _fetchProducts(); // Refresh products after adding a new one
                }
                Navigator.of(context).pop();
              },
              child: Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog to confirm deletion of a product
  void _showDeleteProductDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Product'),
          content: Text('Are you sure you want to delete this product?'),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _productsCollection.doc(productId).delete();
                _fetchProducts(); // Refresh products after deletion
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
