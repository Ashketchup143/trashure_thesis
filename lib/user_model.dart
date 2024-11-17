import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String _userName = '';
  String _userRole = '';
  String _userId = '';

  String get userName => _userName;
  String get userRole => _userRole;
  String get userId => _userId;

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  // Method to clear user data
  void clearUserData() {
    _userName = '';
    _userRole = '';
    _userId = '';
    notifyListeners();
  }
}
