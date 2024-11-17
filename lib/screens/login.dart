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
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }

        // Query the 'employees' collection in Firestore
        QuerySnapshot employeeSnapshot = await _firestore
            .collection('employees')
            .where('email_address', isEqualTo: _emailController.text.trim())
            .get();

        if (employeeSnapshot.docs.isNotEmpty) {
          var employeeData =
              employeeSnapshot.docs.first.data() as Map<String, dynamic>;
          String employeeId = employeeSnapshot.docs.first.id;
          String userName = employeeData['name'] ?? userCredential.user!.email!;
          String position = employeeData['position'] ?? 'employee';

          // Set the username and role in UserModel
          Provider.of<UserModel>(context, listen: false).setUserName(userName);
          Provider.of<UserModel>(context, listen: false)
              .setUserRole(position.toLowerCase());
          Provider.of<UserModel>(context, listen: false)
              .setUserId(employeeId.toLowerCase());

          // Navigate based on role
          if (position.toLowerCase() == 'driver' ||
              position.toLowerCase() == 'contractual driver') {
            Navigator.pushReplacementNamed(context, '/driver', arguments: {
              'name': userName,
              'id': employeeId,
            });
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // No employee found with the given email
          await _auth.signOut();
          setState(() {
            _errorMessage = 'You are not authorized to access this system.';
          });
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase authentication errors
        switch (e.code) {
          case 'user-not-found':
            setState(() {
              _errorMessage = 'No user found with this email.';
            });
            break;
          case 'wrong-password':
            setState(() {
              _errorMessage = 'Incorrect password. Please try again.';
            });
            break;
          case 'invalid-email':
            setState(() {
              _errorMessage = 'The email address is not valid.';
            });
            break;
          case 'user-disabled':
            setState(() {
              _errorMessage = 'This user account has been disabled.';
            });
            break;
          case 'too-many-requests':
            setState(() {
              _errorMessage = 'Too many requests. Please try again later.';
            });
            break;
          case 'network-request-failed':
            setState(() {
              _errorMessage =
                  'Network error. Please check your internet connection.';
            });
            break;
          default:
            setState(() {
              _errorMessage = 'Authentication error: ${e.message}';
            });
            break;
        }
      } catch (e) {
        // Handle any other errors
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
                const Text(
                  'Admin / Driver Login',
                  style: TextStyle(
                    fontSize: 28.0,
                  ),
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
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
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Use backgroundColor instead of primary
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white), // Set text color
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
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
                    const Text(
                      'Admin / Driver Login',
                      style: TextStyle(
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .green, // Use backgroundColor instead of primary
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white), // Set text color
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
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
                decoration: const BoxDecoration(
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
                      const Color.fromARGB(255, 3, 73, 5)
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
