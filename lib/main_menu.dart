import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todochat/settings_page.dart';
import 'package:todochat/state/tasks.dart';
import 'LoginRegistrationPage.dart';
import 'customWidgets.dart';
import 'utils.dart';
import 'todochat.dart';

//enum MenuItemsEnum { Exit, Logout }

class MainMenu extends StatelessWidget {
  final List<PopupMenuItem>? items;

  const MainMenu({Key? key, this.items}) : super(key: key);

  @override
  Widget build(BuildContext context_) {
    var context = NavigationService.navigatorKey.currentContext ?? context_;
    //var app = context.watch()<AppState>();

    List<PopupMenuEntry> mainMenuCommonItems = [
      if (currentUserName.isNotEmpty)
        PopupMenuItem(
          child: Text(
            currentUserName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      if (currentUserName.isNotEmpty) const PopupMenuDivider(),
      PopupMenuItem(
        child: const Text("Logout"),
        onTap: () async {
          await Future.delayed(Duration.zero);
          sessionID = "";
          openLoginPage(context);
        },
      ),
      PopupMenuItem(
        child: const Text("Settings"),
        onTap: () async {
          await Future.delayed(Duration.zero);
          await openSettings(context);
        },
      ),
      PopupMenuItem(
        child: const Text("Mark all read"),
        onTap: () async {
          await Future.delayed(Duration.zero);
          final tasks = context.read<TasksState>();
          tasks.markAllRead(context);
        },
      )
    ];

    return PopupMenuButton(
        color: Colors.white,
        popUpAnimationStyle: AnimationStyle.noAnimation,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        // add icon, by default "3 dot" icon
        icon: Icon(
          Icons.more_vert,
          color: Colors.grey[800],
        ),
        itemBuilder: (context) {
          if (items == null) {
            return mainMenuCommonItems;
          } else {
            var res = [...mainMenuCommonItems, ...items!];
            res.add(
              const PopupMenuItem(
                onTap: ExitApp,
                child: Text("Exit"),
              ),
            );
            return res;
          }
        });
  }
}

/*class MainMenu extends StatelessWidget {
  List<PopupMenuItem> items = const <PopupMenuItem>[];

  MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        // add icon, by default "3 dot" icon
        // icon: Icon(Icons.book)
        itemBuilder: (context) {
      return [
        PopupMenuItem<MenuItemsEnum>(
          value: MenuItemsEnum.Logout,
          child: const Text("Logout"),
          onTap: () async {
            sessionID = "";
            await Future.delayed(Duration.zero);
            openLoginPage(context);
          },
        ),
        const PopupMenuItem<MenuItemsEnum>(
          value: MenuItemsEnum.Exit,
          child: Text("Exit"),
        ),
      ];
    } /*, onSelected: (value) {
      if (value == MenuItemsEnum.Logout) {
        sessionID = "";
        openLoginPage(context);
      } else if (value == MenuItemsEnum.Exit) {
        ExitApp();
      }
    }*/
        );
  }
}*/
