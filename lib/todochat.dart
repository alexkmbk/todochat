import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uri serverURI = Uri();
String sessionID = "";
int currentUserID = 0;
String currentUserName = "";
bool isDesktopMode = false;
double screenWidth = 0;
double screenHeight = 0;
bool appInitialized = false;
const Color closedTaskColor = Color.fromARGB(255, 183, 242, 176);
//const Color uncompletedTaskColor = Color.fromARGB(255, 248, 248, 147);
const Color uncompletedTaskColor = Colors.white;
const Color appBarColor = Color.fromARGB(240, 255, 255, 255);
const Color unreadTaskColor = Color.fromARGB(255, 250, 161, 27);
late SharedPreferences settings;

final searchFocusNode = FocusNode();

enum ScreenModes { Auto, Desktop, Mobile }

bool GetDesktopMode(ScreenModes screenMode) {
  // final w = View.of(context).physicalGeometry.width *
  //     View.of(context).devicePixelRatio;

  var instance = WidgetsBinding.instance;
  var mediaQueryData = MediaQueryData.fromView(instance.window);
  screenWidth = mediaQueryData.size.width;
  screenHeight = mediaQueryData.size.height;

  if (screenMode == ScreenModes.Auto) {
    if (screenWidth > 1000) {
      return true;
    }
  } else if (screenMode == ScreenModes.Desktop) return true;

  return false;
}
