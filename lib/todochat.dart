import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todochat/LoginRegistrationPage.dart';

Uri serverURI = Uri();
String sessionID = "";
int currentUserID = 0;
String currentUserName = "";
bool autoLogin = true;
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

class AppLifecyclePage extends StatefulWidget {
  final Widget child;
  const AppLifecyclePage({required this.child, super.key});

  @override
  State<AppLifecyclePage> createState() => _AppLifecyclePageState();
}

class _AppLifecyclePageState extends State<AppLifecyclePage> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();

    // Initialize the AppLifecycleListener class and pass callbacks
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
  }

  @override
  void dispose() {
    // Do not forget to dispose the listener
    _listener.dispose();

    super.dispose();
  }

  // Listen to the app lifecycle state changes
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _onDetached();
        break;
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.inactive:
        _onInactive();
        break;
      case AppLifecycleState.hidden:
        _onHidden();
        break;
      case AppLifecycleState.paused:
        _onPaused();
    }
  }

  void _onDetached() {
    if (!autoLogin) {
      logoff();
    }
  }

  void _onResumed() {}

  void _onInactive() => print('inactive');

  void _onHidden() => print('hidden');

  void _onPaused() => print('paused');

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
