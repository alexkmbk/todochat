import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todochat/state/tasks.dart';
import 'package:todochat/todochat.dart';

import 'customWidgets.dart';

class SearchField extends StatelessWidget {
  final TextEditingController searchController;
  const SearchField({required this.searchController, super.key});

  @override
  Widget build(BuildContext context) {
    final taskListProvider = Provider.of<TasksState>(context, listen: false);
    // final msgListProvider =
    //     Provider.of<MsgListProvider>(context, listen: false);
    return SizedBox(
      height: 50, // <-- TextField height
      child: TextFieldEx(
          focusNode: searchFocusNode,
          textInputAction: TextInputAction.done,
          controller: searchController,
          hintText: "Search",
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.search),
          onCleared: () {
            //taskListProvider.setCurrentTask(null, context);
            taskListProvider.clear(context);
            taskListProvider.searchMode = false;
            // setState(() {
            //   taskListProvider.searchMode = false;
            //   widget.tasksPageState.showSearch = isDesktopMode;
            // });
            taskListProvider.refresh();
            taskListProvider.requestTasks(context);
          },
          onFieldSubmitted: (value) {
            taskListProvider.search = value;
            if (value.isNotEmpty) {
              //msgListProvider.clear();
              taskListProvider.searchMode = true;
              taskListProvider.clear(context);
              taskListProvider.refresh();
              taskListProvider.searchTasks(value, context);
              // if (isDesktopMode) {
              //   msgListProvider.task = taskListProvider.currentTask ?? Task();
              //   msgListProvider.requestMessages(taskListProvider, context);
              // }
            } else {
              taskListProvider.searchMode = false;
            }
            //FocusScope.of(context).requestFocus();
          }),
    );
  }
}
