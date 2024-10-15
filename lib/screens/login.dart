import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart'; // Import the user model

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _errorMessage = '';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Attempt to sign in the user with the provided email and password
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Special handling for the master user (super admin)
        if (_emailController.text.trim() == 'anmlim@addu.edu.ph') {
          Provider.of<UserModel>(context, listen: false)
              .setUserName('Super Admin'); // Set the username
          Provider.of<UserModel>(context, listen: false)
              .setUserRole('admin'); // Set role as 'admin'
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }

        // Query the 'employees' collection in Firestore
        QuerySnapshot employeeSnapshot = await _firestore
            .collection('employees')
            .where('email_address', isEqualTo: _emailController.text.trim())
            .get();

        if (employeeSnapshot.docs.isNotEmpty) {
          // User exists in employees collection
          var employeeData =
              employeeSnapshot.docs.first.data() as Map<String, dynamic>;
          String employeeId = employeeSnapshot.docs.first.id;
          String userName = employeeData['name'] ?? userCredential.user!.email!;
          String position = employeeData['position'] ?? 'employee';

          // Set the username and position in the UserModel
          Provider.of<UserModel>(context, listen: false).setUserName(userName);
          Provider.of<UserModel>(context, listen: false)
              .setUserRole(position.toLowerCase());

          if (position.toLowerCase() == 'driver') {
            // Navigate to the driver dashboard if the user is a driver
            Navigator.pushReplacementNamed(
              context,
              '/driver',
              arguments: {
                'name': userName,
                'id': employeeId,
              },
            );
          } else {
            // Navigate to the regular dashboard for other roles
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // No document found in the employees collection with the given email
          await _auth.signOut();
          setState(() {
            _errorMessage = 'You are not authorized to access this system.';
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred during login';
        });
      } catch (e) {
        // Handle other errors, such as network issues
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine if it's a small (mobile) or large (desktop) screen
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: screenWidth <
              600 // If screen width is less than 600px, only show login form
          ? _buildMobileLayout() // Show mobile layout
          : _buildDesktopLayout(), // Show desktop layout
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/trashure.png',
                  width: 200,
                  height: 150,
                ),
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 28.0,
                  ),
                ),
                SizedBox(height: 24.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                      // Color from Trashure palette
                      ),
                  child: Text('Login'),
                ),
                SizedBox(height: 16.0),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side with login form
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.white, // Background color from Trashure palette
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/trashure.png',
                      width: 250,
                      height: 300,
                    ),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 28.0,
                      ),
                    ),
                    SizedBox(height: 24.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                          // Color from Trashure palette
                          ),
                      child: Text('Login'),
                    ),
                    SizedBox(height: 16.0),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right side with image and gradient
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              // Background image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/unnamed.jpg'), // Replace with your image
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent, // Start with clear
                      Color.fromARGB(255, 3, 73, 5)
                          .withOpacity(0.7), // Transition to green
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
