import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todochat/state/tasks.dart';

class TasksFloatingButton extends StatelessWidget {
  const TasksFloatingButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksState>();
    return tasks.taskEditMode
        ? floatingActionButtonToSave(tasks, context)
        : FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: Colors.blue,
            onPressed: () {
              if (!tasks.taskEditMode) {
                tasks.addEditorItem();
              }
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          );
  }
}

Widget floatingActionButtonToSave(TasksState provider, BuildContext context) {
  return SizedBox(
      width: 100,
      child: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: const StadiumBorder(),
        onPressed: () {
          provider.saveEditingItem(context);
        },
        child: const Text(
          "Save",
          style: TextStyle(color: Colors.white),
        ),
      ));
}
