import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String _userName = '';

  String get userName => _userName;

  void setUserName(String name) {
    _userName = name;
    notifyListeners(); // Notify widgets when the user name is updated
  }
}
