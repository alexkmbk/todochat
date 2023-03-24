import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:todochat/tasklist_provider.dart';
//import 'package:todochat/text_selection_controls.dart';
import 'package:todochat/todochat.dart';
import 'HttpClient.dart' as HTTPClient;
import 'package:http/http.dart' as http;
import 'HttpClient.dart';
import 'customWidgets.dart';
import 'msglist_provider.dart';
import 'msglist_tile.dart';
import 'utils.dart';
import 'package:path/path.dart' as path;

typedef OnDeleteFn = Future<bool> Function(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController scrollController;

  //final Future<bool> Function(int messageID) onDelete;
  /*final Future<Uint8List> Function(String localFileName,
      {Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) getFile;*/

  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList({
    Key? key,
    required this.scrollController,
    required this.itemPositionsListener,
  }) : super(key: key);

  @override
  InifiniteMsgListState createState() {
    return InifiniteMsgListState();
  }
}

class InifiniteMsgListState extends State<InifiniteMsgList> {
  //late MsgListProvider _msgListProvider;

  final _messageInputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ItemScrollController itemsScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final messageTextFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final msgListProvider =
        Provider.of<MsgListProvider>(context, listen: false);

    if (msgListProvider.task == null || msgListProvider.task?.ID == 0) {
      return const Center(child: Text("No any task was selected"));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (msgListProvider.foundMessageID > 0 &&
            msgListProvider.items.length > 1) {
          msgListProvider.jumpTo(msgListProvider.foundMessageID);
          msgListProvider.foundMessageID = 0;
        }
      });

      if (msgListProvider.loading) {
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
            onTap: () => msgListProvider.unselectItems(),
            child: ScrollablePositionedList.builder(
                reverse: true,
                itemScrollController: widget.scrollController,
                itemPositionsListener: widget.itemPositionsListener,
                itemCount: msgListProvider.items.length,
                extraScrollSpeed:
                    Platform().isAndroid || Platform().isIOS ? 0 : 40,
                itemBuilder: (context, index) {
                  if (msgListProvider.items.isEmpty) {
                    return const Text("");
                  }
                  var item = msgListProvider.items[index];
                  /*if (item.tempID.isNotEmpty && item.loadinInProcess) {
              return LoadingFileBubble(
                index: index,
                isCurrentUser: item.userID == currentUserID,
                message: item,
                msgListProvider: msgListProvider,
                getFile: widget.getFile,
              );
            } else {*/
                  return MsgListTile(
                    index: index,
                    isCurrentUser: item.userID == currentUserID,
                    message: item,
                    msgListProvider: msgListProvider,
                    messageTextFieldFocusNode: messageTextFieldFocusNode,
                    onDismissed: (direction) async {
                      if (await msgListProvider.deleteMesage(item.ID)) {
                        msgListProvider.deleteItem(item.ID);
                      }
                    },
                  );
                }
                /*} else if (index == items.length && end) {
            return const Center(child: Text('End of list'));*/
                //}
                /*else {
            _getMoreItems();
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }*/
                //return const Center(child: Text('End of list'));
                // },
                ),
          ),
        ),
        // Edit message box
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
              /*border: Border(
                
                top: BorderSide(color: Colors.grey),
                bottom: BorderSide(color: Colors.grey),
              ),*/
            ),
            child: Column(children: [
              if (msgListProvider.quotedText.isNotEmpty ||
                  msgListProvider.parentsmallImageName.isNotEmpty)
                Row(children: [
                  if (msgListProvider.parentsmallImageName.isNotEmpty)
                    networkImage(
                        serverURI.scheme +
                            '://' +
                            serverURI.authority +
                            "/FileStorage/" +
                            msgListProvider.parentsmallImageName,
                        height: Platform().isAndroid ? 30 : 60),
                  Expanded(
                      child: Text(
                    msgListProvider.quotedText,
                    style: const TextStyle(color: Colors.grey),
                  )),
                  SizedBox(
                      width: 20,
                      child: IconButton(
                          onPressed: () {
                            msgListProvider.quotedText = "";
                            msgListProvider.parentsmallImageName = "";
                            msgListProvider.refresh();
                          },
                          icon: const Icon(Icons.close)))
                ]),
              if (msgListProvider.quotedText.isNotEmpty) const Divider(),
              Row(
                children: [
                  if (msgListProvider.task != null)
                    NewMessageActionsMenu(
                      msgListProvider: msgListProvider,
                    ),
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter,
                            control: false): () {
                          if (_messageInputController.text.isNotEmpty) {
                            msgListProvider.createMessage(
                              text: _messageInputController.text,
                              task: msgListProvider.task,
                            );
                            _messageInputController.text = "";
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.escape,
                            control: false): () {
                          if (msgListProvider.quotedText.isNotEmpty ||
                              msgListProvider.parentsmallImageName.isNotEmpty) {
                            msgListProvider.quotedText = "";
                            msgListProvider.parentsmallImageName = "";
                            msgListProvider.refresh();
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
                              msgListProvider.addUploadingItem(
                                  Message(
                                      taskID: msgListProvider.taskID,
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
                                    msgListProvider.addUploadingItem(
                                        Message(
                                            taskID: msgListProvider.taskID,
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
                                      msgListProvider.addUploadingItem(
                                          Message(
                                              taskID: msgListProvider.taskID,
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
                        msgListProvider.createMessage(
                            text: _messageInputController.text,
                            task: msgListProvider.task);
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
                          msgListProvider.addUploadingItem(
                              Message(
                                  taskID: msgListProvider.taskID,
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
                        msgListProvider.addUploadingItem(
                            Message(
                                taskID: msgListProvider.taskID,
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
