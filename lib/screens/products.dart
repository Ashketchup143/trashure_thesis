import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/screens/productinformation.dart';
import 'package:trashure_thesis/sidebar.dart'; // Import your custom sidebar
import 'dart:io';
import 'dart:typed_data'; // For kIsWeb
import 'package:file_picker/file_picker.dart'; // Add this for file picker
import 'package:firebase_storage/firebase_storage.dart'; // Add this for Firebase Storage
import 'package:flutter/foundation.dart';

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

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<DocumentSnapshot> _allCategories = [];
  String _searchTerm = '';
  String? _selectedCategory;
  String? _imageFileName;

  // Add these two variables to manage image uploading
  String? _imageUrl; // Holds the image URL
  bool _isUploading = false; // Tracks the upload status
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      _allProducts = snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id, // Include the document ID as 'id'
        };
      }).toList();
      _filteredProducts = _allProducts; // Initially, all products are displayed
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
    String searchTerm = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        String productName = product['product_name'].toString().toLowerCase();
        String category = product['category'].toString().toLowerCase();
        return productName.contains(searchTerm) ||
            category.contains(searchTerm);
      }).toList();
    });
  }

  // Add this method to handle image selection and uploading
  Future<void> _pickAndUploadImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        // Generate a unique file name based on the current timestamp
        String filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageReference =
            _storage.ref().child('product_images/$filename');

        SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );

        // For web
        if (kIsWeb) {
          Uint8List? fileBytes = result.files.first.bytes;
          if (fileBytes != null) {
            UploadTask uploadTask =
                storageReference.putData(fileBytes, metadata);
            await uploadTask;
          }
        } else {
          // For mobile
          File file = File(result.files.single.path!);
          UploadTask uploadTask = storageReference.putFile(file, metadata);
          await uploadTask;
        }

        // Set the filename (not the full URL) in the state
        setState(() {
          _imageFileName = filename;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
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
                            'Products',
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
                                          String productId = product[
                                              'id']; // Correct way to get id
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

                                              // Now pass the entire product map
                                              return _buildProductTile(product);
                                            },
                                          );
                                        },
                                      ),
                              )
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

// Inside _buildProductTile
  Widget _buildProductTile(Map<String, dynamic> product) {
    String productId = product['id'];
    String productName = product['product_name'];
    String category = product['category'];
    String unit = product['unit'];
    String details = product['details'];
    String picture = product['picture'];

    return FutureBuilder<double>(
      future: _fetchLatestPrice(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error fetching price');
        }
        double price = snapshot.data ?? 0.0;

        return ListTile(
          leading: FutureBuilder<String?>(
            future:
                _getProductImage(picture), // Fetch the image URL by filename
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data != null) {
                  // Display the fetched image
                  return ClipOval(
                    child: Image.network(
                      snapshot.data!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  // Fallback to default image if no URL is found
                  return Icon(Icons.image_not_supported, size: 50);
                }
              } else {
                // Display a loading indicator while fetching the image URL
                return CircularProgressIndicator();
              }
            },
          ),
          title: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  productName,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(flex: 1, child: Container()),
              Expanded(
                flex: 2,
                child: Text(category),
              ),
              Expanded(
                flex: 2,
                child: Text('₱${price.toStringAsFixed(2)}/$unit'),
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
                  _showEditProductDialog(context, productId, productName,
                      category, price.toString(), unit, details, picture);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteProductDialog(context, productId);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                ), // Added Details Icon
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductInformation(
                        productId: productId,
                        productName: productName,
                        details: details,
                        category: category,
                        imageUrl: picture, // Pass file name to details screen
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getProductImage(String imageFileName) async {
    try {
      String downloadUrl = await _storage
          .ref()
          .child('product_images/$imageFileName')
          .getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
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

  void _showEditProductDialog(
      BuildContext context,
      String productId,
      String productName,
      String category,
      String price,
      String unit,
      String details,
      String picture) {
    final TextEditingController priceController =
        TextEditingController(text: price);
    final TextEditingController detailsController =
        TextEditingController(text: details);
    String? _imageFileName; // Filename for the uploaded image
    String? _imageUrl; // URL of the uploaded image
    bool _isUploading = false; // Track the upload status
    String _selectedUnit = unit; // Default unit value

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Product'),
              content: SingleChildScrollView(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Column(
                    children: [
                      // Product Name (Read-only)
                      TextField(
                        controller: TextEditingController(text: productName),
                        decoration: InputDecoration(labelText: 'Product Name'),
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      // Category (Read-only)
                      TextField(
                        controller: TextEditingController(text: category),
                        decoration: InputDecoration(labelText: 'Category'),
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      // Price (Editable)
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      // Unit (Dropdown for Unit Selection)
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
                      // Details (Editable)
                      TextField(
                        controller: detailsController,
                        decoration: InputDecoration(labelText: 'Details'),
                      ),
                      SizedBox(height: 10),
                      // Image Upload (Display image before uploading)
                      ElevatedButton(
                        onPressed: _isUploading
                            ? null
                            : () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                );

                                if (result != null) {
                                  setState(() {
                                    _isUploading = true;
                                  });

                                  // For web
                                  if (kIsWeb) {
                                    Uint8List? fileBytes =
                                        result.files.first.bytes;
                                    String filename = result.files.first.name;

                                    // Upload image to Firebase Storage
                                    Reference storageReference = FirebaseStorage
                                        .instance
                                        .ref()
                                        .child('product_images/$filename');
                                    UploadTask uploadTask =
                                        storageReference.putData(fileBytes!);
                                    await uploadTask.whenComplete(() async {
                                      _imageUrl = await storageReference
                                          .getDownloadURL();
                                      setState(() {
                                        _imageFileName = filename;
                                        _isUploading = false;
                                      });
                                    });
                                  }
                                }
                              },
                        child: _isUploading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Choose Image'),
                      ),
                      SizedBox(height: 10),
                      // Display the selected image if available
                      if (_imageUrl != null)
                        Image.network(
                          _imageUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF4F)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF4F)),
                  onPressed: () async {
                    String newDetails = detailsController.text.trim();
                    double newPrice =
                        double.tryParse(priceController.text.trim()) ?? 0.0;

                    // Fetch percentage profit from settings
                    double percentageProfit = await _getPercentageProfit();

                    // Calculate the price based on percentage profit
                    double calculatedPrice =
                        newPrice * (1 - percentageProfit / 100);

                    // Update the product document
                    DocumentReference productRef =
                        _productsCollection.doc(productId);

                    await productRef.update({
                      'unit': _selectedUnit, // Updated unit
                      'details': newDetails, // Updated details
                      if (_imageFileName != null)
                        'picture': _imageFileName!, // Updated picture
                    });

                    // Add price to the 'prices' subcollection if it has changed
                    await productRef.collection('prices').add({
                      'original_price': newPrice,
                      'price': calculatedPrice,
                      'percentage_profit': percentageProfit,
                      'time': FieldValue.serverTimestamp(),
                    });

                    _fetchProducts(); // Refresh products after editing
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add Product Dialog updated to upload image only when the 'Add Product' button is clicked
  void _showAddProductDialog(BuildContext context) {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController originalPriceController =
        TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    String _selectedUnit = 'kg'; // Default unit
    String? _selectedCategory; // For category dropdown
    PlatformFile? _selectedFile; // This will hold the picked file info
    Uint8List? _imageBytes; // To display the image in case of web

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Product name input with lowercased submission
                    TextField(
                      controller: productNameController,
                      decoration: InputDecoration(labelText: 'Product Name'),
                    ),
                    SizedBox(height: 10),

                    // Dropdown for Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      onChanged: (newValue) {
                        setModalState(() {
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

                    // Original price input
                    TextField(
                      controller: originalPriceController,
                      decoration: InputDecoration(labelText: 'Original Price'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),

                    // Dropdown for Unit
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      onChanged: (newValue) {
                        setModalState(() {
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

                    // Details input
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(labelText: 'Details'),
                    ),
                    SizedBox(height: 10),

                    // Image Upload Button
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );

                        if (result != null) {
                          // Assign selected file and convert to bytes for display
                          setModalState(() {
                            _selectedFile = result.files.first;
                            _imageBytes = result.files.first.bytes;
                          });
                        }
                      },
                      child: Text('Choose Image'),
                    ),
                    SizedBox(height: 20),

                    // Display the uploaded image
                    if (_imageBytes != null)
                      Image.memory(
                        _imageBytes!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    if (_selectedFile != null) Text(_selectedFile!.name),
                  ],
                ),
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
                    String productName =
                        productNameController.text.trim().toLowerCase();
                    double originalPrice =
                        double.tryParse(originalPriceController.text.trim()) ??
                            0;
                    String details = detailsController.text.trim();

                    if (productName.isNotEmpty && _selectedFile != null) {
                      // At this point, upload the image and calculate the price before adding to Firestore
                      // Upload the image to Firebase Storage
                      String fileName =
                          '${DateTime.now().millisecondsSinceEpoch}.jpg';
                      Reference storageReference =
                          _storage.ref().child('product_images/$fileName');
                      UploadTask uploadTask =
                          storageReference.putData(_imageBytes!);
                      await uploadTask;

                      // Get the image URL after upload
                      String downloadUrl =
                          await storageReference.getDownloadURL();

                      // Fetch percentage profit from settings collection using the provided function
                      double percentageProfit = await _getPercentageProfit();

                      // Calculate the final price
                      double price =
                          originalPrice * (1 - percentageProfit / 100);

                      // Save the product to Firestore
                      DocumentReference productRef =
                          await _productsCollection.add({
                        'product_name': productName,
                        'category': _selectedCategory,
                        'unit': _selectedUnit,
                        'details': details,
                        'picture': fileName, // Save the image filename
                      });

                      // Add the calculated price to the subcollection
                      await productRef.collection('prices').add({
                        'original_price': originalPrice,
                        'price': price,
                        'percentage_profit': percentageProfit,
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
      },
    );
  }

// Helper function to get the percentage_profit from the settings collection
  Future<double> _getPercentageProfit() async {
    try {
      // Fetch the document with ID 'percentage_profit' from the 'settings' collection
      DocumentSnapshot settingsSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('percentage_profit') // Access the document directly by ID
          .get();

      // Check if the document exists and contains the field
      if (settingsSnapshot.exists && settingsSnapshot.data() != null) {
        return settingsSnapshot['percentage_profit'] ??
            20.0; // Return the percentage_profit value
      } else {
        throw Exception("Document or field 'percentage_profit' not found.");
      }
    } catch (e) {
      print('Error fetching percentage_profit: $e');
      return 20.0; // Default to 20% if there's an error
    }
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
                // Get the product document to retrieve the image filename
                DocumentSnapshot productSnapshot =
                    await _productsCollection.doc(productId).get();

                if (productSnapshot.exists) {
                  String? imageFileName =
                      productSnapshot['picture']; // Get the filename

                  // If there's an image associated, delete it from Firebase Storage
                  if (imageFileName != null && imageFileName.isNotEmpty) {
                    try {
                      await FirebaseStorage.instance
                          .ref('product_images/$imageFileName')
                          .delete();
                      print('Image deleted from storage');
                    } catch (e) {
                      print('Error deleting image: $e');
                    }
                  }

                  // Delete the product document from Firestore
                  await _productsCollection.doc(productId).delete();
                  _fetchProducts(); // Refresh products after deletion
                  Navigator.of(context).pop();
                } else {
                  print('Product does not exist.');
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
