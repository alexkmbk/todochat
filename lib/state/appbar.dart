import 'package:flutter/foundation.dart';
import 'package:todochat/models/project.dart';

class AppBarState extends ChangeNotifier {
  Map<Project, int> unreadMessagesByProjects = {};

  void updateUnread(Map<Project, int> unreadMessagesByProjects) {
    this.unreadMessagesByProjects = unreadMessagesByProjects;
    notifyListeners();
  }
}
