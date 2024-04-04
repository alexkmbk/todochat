import 'package:flutter/material.dart';
import 'package:todochat/state/projects.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todochat/models/project.dart';

class ProjectsMenu extends StatelessWidget {
  //final TextEditingController controller = TextEditingController();
  const ProjectsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectCubit, Project>(
        builder: (context, currentProject) {
      List<DropdownMenuEntry<Project>> dropdownMenuEntries = [];
      var bloc = context.read<ProjectCubit>();
      var items = bloc.items;
      // dropdownMenuEntries =
      //     bloc.items.map<DropdownMenuEntry<Project>>((Project project) {
      //   return DropdownMenuEntry<Project>(
      //     value: Project.from(project),
      //     label: project.Description,
      //     // leadingIcon: IconButton(
      //     //   icon: Icon(Icons.edit),
      //     //   onPressed: () {},
      //     // ),
      //   );
      // }).toList();

      for (var project in items) {
        final value = Project.from(project);
        dropdownMenuEntries.add(DropdownMenuEntry<Project>(
          value: value,
          label: value.Description,
          // leadingIcon: IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: () {},
          // ),
        ));
      }

      dropdownMenuEntries.add(DropdownMenuEntry<Project>(
          value: Project(),
          label: "",
          trailingIcon: TextButton(
            child: Text("..."),
            onPressed: () {
              print("onPressed");
            },
          )
          //label: "...",
          // leadingIcon: IconButton(
          //   icon: Icon(Icons.edit),
          //   onPressed: () {},
          // ),
          ));

      return DropdownMenu<Project>(
        //controller: controller,
        enableFilter: true,
        requestFocusOnTap: true,
        //leadingIcon: const Icon(Icons.search),
        //label: const Text('Icon'),
        initialSelection: currentProject,
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Colors.white,
          filled: false,
          border: InputBorder.none,
          //contentPadding: EdgeInsets.symmetric(vertical: 5.0),
        ),
        onSelected: (Project? project) {
          context.read<ProjectCubit>().setCurrentProject(project);
        },
        dropdownMenuEntries: dropdownMenuEntries,
      );
    });
  }
}
