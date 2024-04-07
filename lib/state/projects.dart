import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:todochat/HttpClient.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/todochat.dart';

class ProjectsState extends ChangeNotifier {
  List<Project> items = [];
  Project currentProject = Project();

  void setCurrentProject(Project? value) {
    if (value == null)
      currentProject = Project();
    else
      currentProject = value;
    notifyListeners();
  }

  void setCurrentProjectByID(int? ID) {
    if (ID == null || ID == 0)
      currentProject = Project();
    else
      currentProject = items.lastWhere((e) => e.ID == ID);
    notifyListeners();
  }

  Future<Project> loadItems(
      {int currentProjectID = 0, bool refresh = true}) async {
    items.clear();

    Response response;
    try {
      response =
          await httpClient.get(setUriProperty(serverURI, path: 'projects'));
    } catch (e) {
      return currentProject;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var items_json = data["items"];

      for (var item in items_json) {
        items.add(Project(Description: item["Description"], ID: item["ID"]));
      }

      if (items.isEmpty && currentProject.isNotEmpty) {
        currentProject = Project();
      } else if (currentProject.isEmpty && currentProjectID != 0) {
        final foundItem =
            items.firstWhereOrNull((e) => e.ID == currentProjectID);
        if (foundItem != null) currentProject = foundItem;
      } else if (currentProject.isEmpty ||
          items.firstWhereOrNull((e) => e.ID == currentProject.ID) == null)
        currentProject = items.first;
    }
    if (refresh) {
      notifyListeners();
    }
    return currentProject;
  }

  void addNewInEditMode({bool OnStartPosiiton = false}) {
    items.insert(OnStartPosiiton ? 0 : items.length,
        Project(editMode: true, isNewItem: true));
  }

  Future<Project?> createProject(String Description) async {
    if (sessionID == "") {
      return null;
    }

    Project project = Project(Description: Description);

    Response response;
    try {
      response = await httpClient.post(
          setUriProperty(serverURI, path: 'createProject'),
          body: jsonEncode(project));
    } catch (e) {
      return null;
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      project.ID = data["ID"];
      items.insert(0, project);
      //setCurrentProject(project);
      return project;
    }

    return null;
  }

  void deleteEditorItem() {
    items.removeWhere((item) => item.editMode == true);
  }
}
