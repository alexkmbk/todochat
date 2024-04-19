import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todochat/main_menu.dart';
import 'package:todochat/state/msglist_provider.dart';
import 'package:todochat/todochat.dart';

class MessagesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MessagesAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final task = context.watch<MsgListProvider>().task;
    return AppBar(
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.black,
        ),
      ), //const MainMenu(),
      backgroundColor: const Color.fromARGB(240, 255, 255, 255),
      title: Row(children: [
        Text(
          "Task:",
          style: const TextStyle(fontSize: 18),
        ),
        Flexible(
            child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  task.description,
                  style: const TextStyle(color: hyperrefColor, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ))),
      ]),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
