import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todochat/HttpClient.dart';
import 'package:todochat/LoginRegistrationPage.dart';
import 'package:todochat/models/project.dart';
import 'package:todochat/models/task.dart';
import 'package:todochat/projects_list.dart';
import 'package:todochat/settings_page.dart';
import 'package:todochat/state/tasks.dart';
import 'package:todochat/todochat.dart';
import 'package:todochat/utils.dart';
import 'package:web_socket_channel/status.dart' as status;

class AppState extends ChangeNotifier {
  Timer? timer;
  bool forceTaskRequest = false;
  bool appInitialized = false;

  void redrawWidgetTree(BuildContext context,
      [initialize = true, logoff = true]) {
    if (initialize) {
      if (logoff) {
        logoff();
      }

      forceTaskRequest = true;
      appInitialized = false;
      final tasklist = context.read<TasksState>();
      tasklist.clear(context);
      final currentProject = Project();
      settings.setInt("projectID", currentProject.ID);
      settings.setInt("currentTaskID", 0);
      settings.setString("sessionID", "");
      tasklist.project = currentProject;
      if (logoff) {
        openLoginPage(context).then((value) {
          if (value) {
            notifyListeners();
          }
        });
      } else {
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  Future<bool> init(BuildContext context) async {
    if (appInitialized) return true;

    if (timer != null) {
      timer!.cancel();
    }

    if (ws != null) {
      ws!.sink.close(status.normalClosure);
      ws = null;
      httpClient.close();
      isWSConnected = false;
    }
    settings = await SharedPreferences.getInstance();

    var screenModeIndex =
        settings.getInt("ScreenMode") ?? ScreenModes.Auto.index;

    isDesktopMode = GetDesktopMode(ScreenModes.values[screenModeIndex]);

    if (sessionID.isEmpty) {
      var sessionID_ = settings.getString("sessionID");
      if (sessionID_ == null) {
        sessionID = "";
      } else
        sessionID = sessionID_;
    }

    var httpScheme = settings.getString("httpScheme");
    var host = settings.getString("host");
    var port = settings.getInt("port");
    autoLogin = settings.getBool("autoLogin") ?? true;

    String taskId = "";

    if (isWeb() && (host == null || host.isEmpty)) {
      host = Uri.base.host;
      port = Uri.base.port;
      httpScheme = Uri.base.scheme;
    }
    if (isWeb()) {
      final segments = Uri.base.pathSegments;
      if (segments.isNotEmpty) {
        taskId = segments[0];
      }
    }

    if (port == null || port == 0) {
      port = null;
    }
    //var isServerURI = true;
    if (host == null || host.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage(key: UniqueKey())),
      );
      return false;
    } else {
      serverURI = Uri(scheme: httpScheme, host: host, port: port);
    }
    bool login = false;
    Project currentProject = Project(ID: settings.getInt("projectID") ?? 0);

    if (sessionID.isNotEmpty && autoLogin) {
      httpClient.defaultHeaders = {"sessionID": sessionID};
      try {
        login = await checkLogin(
            project: currentProject, returnUnreadMessages: true);
      } catch (e) {
        return Future.error(e.toString());
      }
    }
    if (!login) {
      await openLoginPage(context);
    }

    final tasks = context.read<TasksState>();

    if (isServerURI && sessionID.isNotEmpty) {
      connectWebSocketChannel(serverURI).then((value) {
        listenWs(tasks, context);
      });
    }

    Task? task;

    if (isWeb() && taskId.isNotEmpty && login) {
      // convert to int and remove leading zeros
      taskId = taskId.replaceAll(RegExp(r'^0+'), '');
      final taskIdInt = int.tryParse(taskId);

      if (taskIdInt != null) {
        task = await tasks.getTaskByID(taskIdInt);
        if (task != null && task.projectID == 0) {
          task = null;
        }
      }
    }

    if (task != null) {
      tasks.currentTaskID = task.ID;
      currentProject = await getProject(task.projectID) ?? Project();
    } else {
      tasks.currentTaskID = settings.getInt("currentTaskID") ?? 0;
    }

    if (currentProject.isEmpty) {
      currentProject = await requestFirstItem() ?? Project();
    }

    tasks.showClosed = settings.getBool("showClosed") ?? true;
    tasks.setCurrentProject(currentProject, context, forceTaskRequest);

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      reconnect(tasks, context);
    });

    appInitialized = true;
    forceTaskRequest = false;

    return true;
  }
}
