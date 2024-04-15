import 'package:flutter/material.dart';
import 'package:todochat/todochat.dart';

class SettingsState extends ChangeNotifier {
  void redrawWidgetTree() {
    appInitialized = false;
    notifyListeners();
  }
}
