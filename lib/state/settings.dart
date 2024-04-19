import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todochat/state/tasks.dart';
import 'package:todochat/todochat.dart';

class SettingsState extends ChangeNotifier {
  void redrawWidgetTree(BuildContext context) {
    appInitialized = false;
    context.read<TasksState>().clear(context);
    notifyListeners();
  }
}
