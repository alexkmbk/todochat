import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:todochat/HttpClient.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/todochat.dart';

class ProjectCubit extends Cubit<Project> {
  List<Project> items = [];
  Project currentProject = Project();

  ProjectCubit() : super(Project());

  void setCurrentProject(Project? value) {
    if (value == null)
      currentProject = Project();
    else
      currentProject = value;
    emit(currentProject);
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
    } else {
      addError(Exception('projects request error'), StackTrace.current);
    }
    if (refresh) {
      emit(currentProject);
    }
    return currentProject;
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('$error, $stackTrace');
    super.onError(error, stackTrace);
  }
}
