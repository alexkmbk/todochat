import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:http/http.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:todochat/tasklist_provider.dart';

import 'package:todochat/todochat.dart';
import 'msglist_actions_menu.dart';
import 'customWidgets.dart';
import 'msglist_provider.dart';
import 'msglist_tile.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;

class MsgList extends StatefulWidget {
  final MsgListProvider msglist;
  final FlutterListViewController flutterListViewController;

  const MsgList(
      {Key? key,
      required this.msglist,
      required this.flutterListViewController})
      : super(key: key);

  @override
  MsgListState createState() {
    return MsgListState();
  }
}

class MsgListState extends State<MsgList> {
  final _messageInputController = TextEditingController();
  final messageTextFieldFocusNode = FocusNode();

  @override
  void initState() {
    widget.flutterListViewController.sliverController
        .onPaintItemPositionsCallback = (height, positions) {
      // height is widget's height
      // positions is the items which render in viewports
      if (positions.last.index >= widget.msglist.items.length - 5) {
        final tasklist = Provider.of<TaskListProvider>(context, listen: false);

        widget.msglist.requestMessages(tasklist, context);
      }
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final msglist = widget.msglist;
    if (msglist.task == null || msglist.task?.ID == 0) {
      return const Center(child: Text("No any task was selected"));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (msglist.foundMessageID > 0 && msglist.items.length > 1) {
          msglist.jumpTo(msglist.foundMessageID);
          msglist.foundMessageID = 0;
        }
      });

      if (msglist.loading) {
        return const Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(),
            ));
      }
      return Column(children: <Widget>[
        Expanded(
          child: GestureDetector(
              onTap: () => msglist.unselectItems(),
              child: FlutterListView(
                  reverse: true,
                  controller: widget.flutterListViewController,
                  delegate: FlutterListViewDelegate(
                    (BuildContext context, int index) {
                      if (msglist.items.isEmpty) {
                        return const Text("No any task was selected");
                      }
                      var item = msglist.items[index];
                      return MsgListTile(
                        index: index,
                        isCurrentUser: item.userID == currentUserID,
                        message: item,
                        msgListProvider: msglist,
                        messageTextFieldFocusNode: messageTextFieldFocusNode,
                        onDismissed: (direction) async {
                          if (await msglist.deleteMesage(item.ID)) {
                            msglist.deleteItem(item.ID);
                          }
                        },
                      );
                    },
                    childCount: widget.msglist.items.length,
                  ))),
        ),
        // Edit message box
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(children: [
              if (msglist.quotedText.isNotEmpty ||
                  msglist.parentsmallImageName.isNotEmpty)
                Row(children: [
                  if (msglist.parentsmallImageName.isNotEmpty)
                    networkImage(
                        '${serverURI.scheme}://${serverURI.authority}/FileStorage/${msglist.parentsmallImageName}',
                        height: Platform().isAndroid ? 30 : 60),
                  Expanded(
                      child: Text(
                    msglist.quotedText,
                    style: const TextStyle(color: Colors.grey),
                  )),
                  SizedBox(
                      width: 20,
                      child: IconButton(
                          onPressed: () {
                            msglist.quotedText = "";
                            msglist.parentsmallImageName = "";
                            msglist.refresh();
                          },
                          icon: const Icon(Icons.close)))
                ]),
              if (msglist.quotedText.isNotEmpty) const Divider(),
              Row(
                children: [
                  if (msglist.task != null)
                    ActionsMenu(
                      msglist: msglist,
                    ),
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter,
                            control: false): () {
                          if (_messageInputController.text.isNotEmpty) {
                            msglist.createMessage(
                              text: _messageInputController.text,
                              task: msglist.task,
                            );
                            _messageInputController.text = "";
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.escape,
                            control: false): () {
                          if (msglist.quotedText.isNotEmpty ||
                              msglist.parentsmallImageName.isNotEmpty) {
                            msglist.quotedText = "";
                            msglist.parentsmallImageName = "";
                            msglist.refresh();
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.keyV,
                            control: true): () async {
                          ClipboardData? data =
                              await Clipboard.getData('text/plain');

                          if (data != null &&
                              data.text != null &&
                              data.text!.trim().isNotEmpty) {
                            String text = data.text ?? "";
                            _messageInputController.text = text.trim();
                            _messageInputController.selection =
                                TextSelection.fromPosition(TextPosition(
                                    offset:
                                        _messageInputController.text.length));
                          } else {
                            final bytes = await Pasteboard.image;
                            if (bytes != null) {
                              msglist.addUploadingItem(
                                  Message(
                                      taskID: msglist.taskID,
                                      userID: currentUserID,
                                      fileName: "clipboard_image.png",
                                      loadingFile: true,
                                      isImage: true),
                                  bytes);
                            } else {
                              final files = await Pasteboard.files();
                              if (files.isNotEmpty) {
                                for (final file in files) {
                                  var fileData = await readFile(file);
                                  if (fileData.isNotEmpty) {
                                    msglist.addUploadingItem(
                                        Message(
                                            taskID: msglist.taskID,
                                            userID: currentUserID,
                                            fileName: path.basename(file),
                                            loadingFile: true,
                                            isImage: isImageFile(file)),
                                        fileData);
                                  }
                                }
                              } else {
                                var html = await Pasteboard.html;
                                if (html != null && html.isNotEmpty) {
                                  String imageURL = getImageURLFromHTML(html);
                                  if (imageURL.isNotEmpty) {
                                    Response response;
                                    try {
                                      response = await get(Uri.parse(imageURL));
                                    } catch (e) {
                                      toast(e.toString(), context);
                                      return;
                                    }

                                    if (response.statusCode == 200) {
                                      msglist.addUploadingItem(
                                          Message(
                                              taskID: msglist.taskID,
                                              userID: currentUserID,
                                              fileName: "clipboard_image.png",
                                              loadingFile: true,
                                              isImage: true),
                                          response.bodyBytes);
                                    }
                                  } else {
                                    _messageInputController.text = html.trim();
                                    _messageInputController.selection =
                                        TextSelection.fromPosition(TextPosition(
                                            offset: _messageInputController
                                                .text.length));
                                  }
                                }
                              }
                            }
                          }
                        },
                      },
                      child: TextField(
                        focusNode: messageTextFieldFocusNode,
                        autofocus: true,
                        controller: _messageInputController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // OutlineInputBorder(),
                          hintText: 'Message',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_messageInputController.text.isNotEmpty) {
                        msglist.createMessage(
                            text: _messageInputController.text,
                            task: msglist.task);
                        _messageInputController.text = "";
                      }
                    },
                    tooltip: 'New message',
                    icon: const Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result == null) {
                        return;
                      }

                      if (!isWeb() && result.files.single.path != null) {
                        var fileName = result.files.single.path?.trim() ?? "";

                        if (fileName.isNotEmpty) {
                          var res = await readFile(fileName);
                          msglist.addUploadingItem(
                              Message(
                                  taskID: msglist.taskID,
                                  userID: currentUserID,
                                  fileName: path.basename(fileName),
                                  loadingFile: true,
                                  isImage: isImageFile(fileName)),
                              res);
                          _messageInputController.text = "";
                        }
                      } else if (result.files.single.bytes != null &&
                          result.files.single.bytes!.isNotEmpty) {
                        var fileName = result.files.single.name;
                        msglist.addUploadingItem(
                            Message(
                                taskID: msglist.taskID,
                                userID: currentUserID,
                                fileName: path.basename(fileName),
                                loadingFile: true,
                                isImage: isImageFile(fileName)),
                            result.files.single.bytes!);
                        _messageInputController.text = "";
                      }
                    },
                    tooltip: 'Add file',
                    icon: const Icon(Icons.attach_file),
                  )
                ],
              ),
            ]),
          ),
        ),
      ]);
    }
  }
}
