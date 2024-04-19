// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:todochat/customWidgets.dart';
// import 'package:todochat/models/project.dart';
// import 'package:todochat/state/projects.dart';
// import 'package:choice/choice.dart';
// import 'package:todochat/todochat.dart';

// class ProjectsMenu extends StatefulWidget {
//   //final TextEditingController controller = TextEditingController();
//   const ProjectsMenu({super.key});

//   @override
//   State<ProjectsMenu> createState() => _ProjectsMenuState();
// }

// class _ProjectsMenuState extends State<ProjectsMenu> {
//   final OverlayPortalController _tooltipController = OverlayPortalController();

//   final _link = LayerLink();

//   /// width of the button after the widget rendered
//   //double? _buttonWidth;

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ProjectsState>(builder: (context, state, child) {
//       return CompositedTransformTarget(
//         link: _link,
//         child: OverlayPortal(
//           controller: _tooltipController,
//           overlayChildBuilder: (BuildContext context) {
//             return CompositedTransformFollower(
//               link: _link,
//               targetAnchor: Alignment.bottomCenter,
//               followerAnchor: Alignment.topCenter,
//               child: TapRegion(
//                 onTapOutside: (tap) {
//                   _tooltipController.hide();
//                 },
//                 child: ProjectsMenuOverlayForm(
//                   controller: _tooltipController,
//                   state: state,
//                 ),
//               ),
//             );
//           },
//           child: Align(
//               alignment: Alignment.topCenter,
//               child: TextButton.icon(
//                 onPressed: onTap,
//                 label: Text(
//                   state.currentProject.Description,
//                   style: const TextStyle(color: Colors.black, fontSize: 15),
//                 ),
//                 icon: const Icon(
//                   Icons.keyboard_arrow_down,
//                   color: Colors.black,
//                 ),
//                 //style: TextStyle(color: Colors.white),
//               )),
//         ),
//       );
//     });
//   }

//   void onTap() {
//     //_buttonWidth = context.size?.width;
//     _tooltipController.toggle();
//   }
// }

// class ProjectsMenuOverlayForm extends StatefulWidget {
//   final OverlayPortalController controller;
//   final ProjectsState state;
//   const ProjectsMenuOverlayForm(
//       {required this.controller, required this.state, super.key});

//   @override
//   State<ProjectsMenuOverlayForm> createState() =>
//       _ProjectsMenuOverlayFormState();
// }

// class _ProjectsMenuOverlayFormState extends State<ProjectsMenuOverlayForm> {
//   bool editMode = false;
//   final TextEditingController controller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final projects = widget.state;
//     return Align(
//       alignment: Alignment.topCenter,
//       child: Container(
//         width: isDesktopMode ? 400 : screenWidth,
//         padding: const EdgeInsets.all(8),
//         decoration: ShapeDecoration(
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//             side: const BorderSide(
//               width: 1.5,
//               color: Colors.black26,
//             ),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           shadows: const [
//             BoxShadow(
//               color: Color(0x11000000),
//               blurRadius: 32,
//               offset: Offset(0, 20),
//               spreadRadius: -8,
//             ),
//           ],
//         ),
//         child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Projects", style: const TextStyle(fontSize: 12)),
//               const Divider(),
//               InlineChoice<Project>.single(
//                 clearable: true,
//                 value: projects.currentProject,
//                 onChanged: (val) {
//                   widget.state.setCurrentProject(val);
//                   widget.controller.hide();
//                 },
//                 itemCount: projects.items.length,
//                 itemBuilder: (selection, i) {
//                   final item = projects.items[i];
//                   if (item.editMode) {
//                     controller.text = item.Description;
//                   }
//                   return ChoiceChip(
//                     selected: selection.selected(item),
//                     onSelected: selection.onSelected(item),
//                     label: item.editMode
//                         ? TextFieldEx(
//                             controller: controller,
//                             onFieldSubmitted: (value) {
//                               final description = value.trim();
//                               if (description.isNotEmpty)
//                                 projects.createProject(value.trim());
//                               setState(() {
//                                 editMode = false;
//                                 projects.deleteEditorItem();
//                               });
//                             },
//                           )
//                         : Text(item.Description),
//                   );
//                 },
//                 trailingBuilder: editMode
//                     ? null
//                     : (state) {
//                         return IconButton(
//                             tooltip: 'Add project',
//                             icon: const Icon(Icons.add_circle_outline),
//                             onPressed: () {
//                               setState(() {
//                                 projects.addNewInEditMode();
//                                 editMode = true;
//                               });
//                             });
//                       },
//                 listBuilder: ChoiceList.createWrapped(
//                   spacing: 10,
//                   runSpacing: 10,
//                   padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
//                 ),
//               ),
//               const Divider(),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(width: 15),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Validate returns true if the form is valid, or false otherwise.
//                       },
//                       child: const Text('Submit'),
//                     ),
//                   ],
//                 ),
//               ),
//             ]),
//       ),
//     );
//   }
// }


// // return Consumer<ProjectsState>(builder: (context, state, child) {
// //       return Align(
// //           alignment: Alignment.topLeft,
// //           child: TextButton.icon(
// //             onPressed: () async {},

// //             label: Text(
// //               state.currentProject.Description,
// //               style: const TextStyle(color: Colors.black, fontSize: 15),
// //             ),
// //             icon: const Icon(
// //               Icons.keyboard_arrow_down,
// //               color: Colors.black,
// //             ),
// //             //style: TextStyle(color: Colors.white),
// //           ));

// //       // final List<DropdownMenuItem<int>> menuItems = [];
// //       // final List<double> itemsHeights = [];

// //       // for (var project in state.items) {
// //       //   itemsHeights.add(30);
// //       //   menuItems.add(DropdownMenuItem<int>(
// //       //     value: project.ID,
// //       //     child: Text(
// //       //       project.Description,
// //       //       textAlign: TextAlign.right,
// //       //     ),
// //       //   ));
// //       // }

// //       // menuItems.add(const DropdownMenuItem<int>(
// //       //   enabled: false,
// //       //   child: Divider(),
// //       // ));
// //       // itemsHeights.add(4);

// //       // menuItems.add(
// //       //   DropdownMenuItem<int>(
// //       //     alignment: Alignment.bottomRight,
// //       //     value: 0,
// //       //     child: TextButton(
// //       //       child: Text("..."),
// //       //       onPressed: () async {
// //       //         var res = await Navigator.push(
// //       //           context,
// //       //           MaterialPageRoute(builder: (context) => ProjectsPage()),
// //       //         );
// //       //         if (res != null) {
// //       //           context.read<ProjectsState>().setCurrentProject(res);
// //       //         }
// //       //       },
// //       //     ),
// //       //     // child: new RichText(
// //       //     //   text: new TextSpan(
// //       //     //     text: 'Projects...',
// //       //     //     style: new TextStyle(color: Colors.blue),
// //       //     //     recognizer: new TapGestureRecognizer()
// //       //     //       ..onTap = () async {
// //       //     //         var res = await Navigator.push(
// //       //     //           context,
// //       //     //           MaterialPageRoute(builder: (context) => ProjectsPage()),
// //       //     //         );
// //       //     //         if (res != null) {
// //       //     //           context.read<ProjectsState>().setCurrentProject(res);
// //       //     //         }
// //       //     //       },
// //       //     //   ),
// //       //     // ),
// //       //   ),
// //       // );
// //       // itemsHeights.add(30);
// //       // return DropdownButtonHideUnderline(
// //       //   child: DropdownButton2<int>(
// //       //     menuItemStyleData: MenuItemStyleData(
// //       //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
// //       //       customHeights: itemsHeights,
// //       //     ),
// //       //     dropdownStyleData:
// //       //         DropdownStyleData(openInterval: const Interval(0.0, 0.0)),
// //       //     isExpanded: true,
// //       //     hint: Text(
// //       //       'Select project',
// //       //       style: TextStyle(
// //       //         color: Theme.of(context).hintColor,
// //       //       ),
// //       //     ),
// //       //     items: menuItems,
// //       //     value: state.currentProject.ID,
// //       //     onChanged: (int? ID) {
// //       //       if (ID != null && ID != 0)
// //       //         context.read<ProjectsState>().setCurrentProjectByID(ID);
// //       //     },
// //       //     buttonStyleData: const ButtonStyleData(
// //       //       overlayColor: MaterialStateColor.transparent,
// //       //       padding: EdgeInsets.symmetric(horizontal: 16),
// //       //       height: 40,
// //       //     ),
// //       //   ),
// //       // );
// //       // List<DropdownMenuEntry<int>> dropdownMenuEntries = [];
// //       // for (var project in state.items) {
// //       //   dropdownMenuEntries.add(DropdownMenuEntry<int>(
// //       //     value: project.ID,
// //       //     label: project.Description,
// //       //   ));
// //       // }

// //       // dropdownMenuEntries.add(DropdownMenuEntry<int>(
// //       //   value: 0,
// //       //   label: "...",
// //       //   leadingIcon: IconButton(
// //       //     icon: Icon(Icons.add),
// //       //     onPressed: () {},
// //       //   ),
// //       //   trailingIcon: InkWell(
// //       //     child: new Text('Projects...'),
// //       //     onTap: () {},
// //       //   ),
// //       // ));

// //       // return DropdownMenu<int>(
// //       //   //controller: controller,
// //       //   enableFilter: true,
// //       //   requestFocusOnTap: true,
// //       //   //leadingIcon: const Icon(Icons.search),
// //       //   //label: const Text('Icon'),
// //       //   initialSelection: state.currentProject.ID,
// //       //   inputDecorationTheme: const InputDecorationTheme(
// //       //     fillColor: Colors.white,
// //       //     filled: false,
// //       //     border: InputBorder.none,
// //       //     //contentPadding: EdgeInsets.symmetric(vertical: 5.0),
// //       //   ),
// //       //   onSelected: (int? ID) {
// //       //     if (ID != null && ID != 0)
// //       //       context.read<ProjectsState>().setCurrentProjectByID(ID);
// //       //   },
// //       //   dropdownMenuEntries: dropdownMenuEntries,
// //       // );
// //     });