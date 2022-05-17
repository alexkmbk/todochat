import 'package:flutter/material.dart';
import 'package:todochat/SettingsPage.dart';
import 'LoginPage.dart';
import 'main.dart';
import 'utils.dart';

//enum MenuItemsEnum { Exit, Logout }

class MainMenu extends StatelessWidget {
  final List<PopupMenuItem>? items;

  const MainMenu({Key? key, this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<PopupMenuItem> mainMenuCommonItems = [
      PopupMenuItem(
        child: const Text("Settings"),
        onTap: () async {
          await Future.delayed(Duration.zero);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
      PopupMenuItem(
        child: const Text("Logout"),
        onTap: () async {
          await Future.delayed(Duration.zero);
          sessionID = "";
          openLoginPage(context);
        },
      ),
      const PopupMenuItem(
        onTap: ExitApp,
        child: Text("Exit"),
      ),
    ];

    return PopupMenuButton(
        // add icon, by default "3 dot" icon
        icon: Icon(
          Icons.more_vert,
          color: Colors.grey[800],
        ),
        itemBuilder: (context) {
          if (items == null) {
            return mainMenuCommonItems;
          } else {
            return [...mainMenuCommonItems, ...items!];
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
