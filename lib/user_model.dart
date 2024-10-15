import 'package:flutter/foundation.dart';

class UserModel with ChangeNotifier {
  String _userName = '';
  String _userRole = ''; // Add role as a field

  String get userName => _userName;
  String get userRole => _userRole; // Getter for role

  void setUserName(String userName) {
    _userName = userName;
    notifyListeners(); // Notify listeners when username changes
  }

  void setUserRole(String userRole) {
    _userRole = userRole; // Update the role
    notifyListeners(); // Notify listeners when role changes
  }
}
