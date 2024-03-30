import 'package:flutter/material.dart';
import 'package:todochat/searchField.dart';
import 'package:todochat/tasklist_provider.dart';
import 'package:provider/provider.dart';
import 'main_menu.dart';
import 'ProjectsList.dart';
import 'todochat.dart';

class TasksPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  TasksPageAppBar({Key? key}) : super(key: key);

  @override
  State<TasksPageAppBar> createState() => _TasksPageAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TasksPageAppBarState extends State<TasksPageAppBar> {
  TextEditingController searchController = TextEditingController();
  bool showSearch = isDesktopMode;
  Widget getProjectField() {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
    return Align(
        alignment: Alignment.topLeft,
        child: TextButton.icon(
          onPressed: () async {
            var res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectsPage()),
            );
            if (res != null && taskListProvider.project != res) {
              taskListProvider.project = res;
              taskListProvider.projectID = res.ID;
              taskListProvider.clear(context);
              await taskListProvider.requestTasks(context, true);
              //taskListProvider.setProjectID(res.ID);
              await settings.setInt("projectID", res.ID);
            }
            setState(() {});
          },

          label: taskListProvider.project == null
              ? const Text("")
              : Text(
                  taskListProvider.project?.Description ?? "",
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.black,
          ),
          //style: TextStyle(color: Colors.white),
        ));
  }

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
          style: TextStyle(fontSize: 15, color: Colors.black),
        ),
        Flexible(
            fit: FlexFit.tight,
            //flex: 6,
            child: getProjectField())
      ]);
    } else if (showSearch) {
      return SearchField(
        searchController: searchController,
      );
    } else {
      return getProjectField();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<TaskListProvider>(context, listen: false);
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
