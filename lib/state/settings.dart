import 'package:flutter/material.dart';

class SettingsState extends ChangeNotifier {
  void redrawWidgetTree() {
    notifyListeners();
  }
}
