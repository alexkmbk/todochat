import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:todochat/customWidgets.dart';
import 'package:todochat/msglist_provider.dart';
import 'package:todochat/projects_menu.dart';
import 'package:todochat/searchField.dart';
import 'package:provider/provider.dart';
import 'package:todochat/state/tasks.dart';
import 'main_menu.dart';
import 'projects_list.dart';
import 'todochat.dart';

class TasksPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TasksPageAppBar({Key? key}) : super(key: key);

  @override
  State<TasksPageAppBar> createState() => _TasksPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TasksPageAppBarState extends State<TasksPageAppBar> {
  TextEditingController searchController = TextEditingController();
  bool showSearch = isDesktopMode;
  Widget getAppBarTitle() {
    if (isDesktopMode) {
      return Row(children: [
        Flexible(
            fit: FlexFit.tight,
            flex: 4,
            child: SearchField(
              searchController: searchController,
            )),
        const Text(
          "Project: ",
          style: const TextStyle(fontSize: 15, color: Colors.black),
        ),
        Flexible(
            //fit: FlexFit.tight,
            //flex: 6,
            child: const ProjectField())
      ]);
    } else if (showSearch) {
      return SearchField(
        searchController: searchController,
      );
    } else {
      return ProjectField();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskListProvider = Provider.of<TasksState>(context, listen: false);
    return AppBar(
      //toolbarHeight: 10, //MediaQuery.of(context).size.height * .1,
      backgroundColor: const Color.fromARGB(240, 255, 255, 255),
      //title: Text("ToDo Chat"),
      title: getAppBarTitle(),
      /*const Expanded(
              child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.white),
//                filled: true,
//                fillColor: Colors.white,
                    border: InputBorder.none,
                    suffixIcon: Icon(
                      Icons.search,
                    ),
                  )))),*/
      leading: MainMenu(
        key: UniqueKey(),
        items: [
          PopupMenuItem(
            child: Text(taskListProvider.showClosed
                ? "Hide completed"
                : "Show completed"),
            onTap: () async {
              taskListProvider.showClosed = !taskListProvider.showClosed;
              settings.setBool("showClosed", taskListProvider.showClosed);
              taskListProvider.clear(context);
              if (taskListProvider.search.isNotEmpty) {
                taskListProvider.searchTasks(taskListProvider.search, context);
              } else {
                taskListProvider.requestTasks(context, true);
              }
            },
          ),
        ],
      ),
      actions: [
        if (!isDesktopMode && showSearch)
          IconButton(
            onPressed: () {
              setState(() {
                showSearch = true;
              });
            },
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
            tooltip: "Search",
          )
        else if (!isDesktopMode && showSearch)
          IconButton(
              onPressed: () {
                setState(() {
                  showSearch = false;
                });
              },
              icon: const Icon(
                Icons.arrow_right,
                color: Colors.black,
              ),
              tooltip: "Project"),
        if (isDesktopMode)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 35,
              child: ElevatedButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7))),
                    elevation: MaterialStateProperty.resolveWith<double>(
                      (Set<MaterialState> states) {
                        // if the button is pressed the elevation is 10.0, if not
                        // it is 5.0
                        if (states.contains(MaterialState.pressed)) {
                          return 10.0;
                        }
                        return 5.0;
                      },
                    ),
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                /*style: OutlinedButton.styleFrom(
                  fixedSize: const Size(60, 30),
                  side: const BorderSide(width: 1.0, color: Colors.white),
                  shape: const StadiumBorder(),
                ),*/
                onPressed: () {
                  if (!taskListProvider.taskEditMode) {
                    taskListProvider.addEditorItem();
                  }
                },
                child: Row(
                  children: const [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    Text(
                      "New task",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                  //tooltip: "New task",
                ),
              ),
            ),
          )
      ],
    );
  }
}

class ProjectField extends StatefulWidget {
  const ProjectField({super.key});

  @override
  State<ProjectField> createState() => _ProjectFieldState();
}

class _ProjectFieldState extends State<ProjectField> {
  @override
  Widget build(BuildContext context) {
    var tasks = context.read<TasksState>();

    return ActionChip(
      onPressed: () async {
        final res = await ProjectsPage.choice(context: context);
        if (res != null) {
          tasks.setCurrentProject(res, context);
        }
        setState(() {});
      },
      label: Text(tasks.project.Description),
    );
  }
  //   return Align(
  //       alignment: Alignment.centerLeft,
  //       child: new RichText(
  //         text: new TextSpan(
  //           children: [
  //             new TextSpan(
  //               text: tasks.project.Description,
  //               style: new TextStyle(
  //                   color: Color.fromRGBO(51, 102, 204, 1.0), fontSize: 16),
  //               recognizer: new TapGestureRecognizer()
  //                 ..onTap = () async {
  //                   final res = await ProjectsPage.choice(context: context);
  //                   if (res != null) {
  //                     tasks.setCurrentProject(res, context);
  //                   }
  //                   setState(() {});
  //                 },
  //             ),
  //           ],
  //         ),
  //       ));
  // }
}
