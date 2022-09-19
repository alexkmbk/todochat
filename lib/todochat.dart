import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uri serverURI = Uri();
String sessionID = "";
int currentUserID = 0;
String currentUserName = "";
bool isDesktopMode = false;
bool appInitialized = false;
const Color closedTaskColor = Color.fromARGB(255, 183, 242, 176);
//const Color uncompletedTaskColor = Color.fromARGB(255, 248, 248, 147);
const Color uncompletedTaskColor = Colors.white;
const Color appBarColor = Color.fromARGB(240, 255, 255, 255);
const Color unreadTaskColor = Color.fromARGB(255, 250, 161, 27);
late SharedPreferences settings;

final searchFocusNode = FocusNode();
