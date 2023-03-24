import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
//import 'package:text_selection_controls/text_selection_controls.dart';
import 'text_selection_controls.dart';
import 'package:todochat/tasklist_provider.dart';
import 'package:todochat/todochat.dart';
import 'package:todochat/utils.dart';

import 'customWidgets.dart';
import 'msglist_provider.dart';

class MsgListTile extends StatelessWidget {
  MsgListTile(
      {Key? key,
      required this.message,
      required this.onDismissed,
      required this.isCurrentUser,
      required this.msgListProvider,
      required this.index,
      required this.messageTextFieldFocusNode})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final MsgListProvider msgListProvider;
  final int index;
  final FocusNode messageTextFieldFocusNode;

  double progress = 1.0;
  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final DismissDirectionCallback onDismissed;
  /*final Future<Uint8List> Function(String localFileName,
      {Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) getFile;*/

  TextBox? calcLastLineEnd(String text, TextSpan textSpan, BuildContext context,
      BoxConstraints constraints) {
    final richTextWidget = Text.rich(textSpan).build(context) as RichText;
    final renderObject = richTextWidget.createRenderObject(context);
    renderObject.layout(constraints);
    var boxes = renderObject.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length));

/*final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
*/

    if (boxes.isEmpty) {
      return null;
    } else {
      return boxes.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final foundStruct = uploadingFiles[message.tempID];
    /*if (foundStruct != null && foundStruct.multipartRequest == null) {
      createMessageWithFile(
        text: message.text,
        fileData: foundStruct.loadingFileData,
        fileName: message.fileName,
        msgListProvider: msgListProvider,
        tempID: message.tempID,
      );
    }*/
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        // asymmetric padding
        padding: message.isTaskDescriptionItem
            ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
            : EdgeInsets.fromLTRB(
                isCurrentUser ? 64.0 : 16.0,
                4,
                isCurrentUser ? 16.0 : 64.0,
                4,
              ),
        child: Align(
            // align the child within the container
            alignment: message.isTaskDescriptionItem ||
                    message.messageAction !=
                        MessageAction.CreateUpdateMessageAction
                ? Alignment.center
                : isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child:
                drawBubble(context, constraints, foundStruct?.loadingFileData)),
      );
      //}
    });
  }

  Widget getMessageActionDescription(Message message) {
    switch (message.messageAction) {
      case MessageAction.ReopenTaskAction:
        return Text.rich(TextSpan(text: "The task was ", children: <InlineSpan>[
          const WidgetSpan(
            //baseline: TextBaseline.ideographic,
            alignment: PlaceholderAlignment.middle,
            child: Label(
              text: "Reopened",
              backgroundColor: Colors.orange,
            ),
          ),
          const WidgetSpan(child: Text(" by ")),
          WidgetSpan(
              child: Text(message.userName,
                  style: const TextStyle(color: Colors.blue))),
        ]));

      //'The task was reopen by ${message.userName}';
      case MessageAction.CancelTaskAction:
        return Text.rich(
            TextSpan(text: "The task was marked as ", children: <InlineSpan>[
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Label(
              text: "Cancelled",
              backgroundColor: Colors.grey,
            ),
          ),
          const WidgetSpan(child: Text(" by ")),
          WidgetSpan(
              child: Text(message.userName,
                  style: const TextStyle(color: Colors.blue))),
        ]));
      case MessageAction.CompleteTaskAction:
        return Text.rich(
            TextSpan(text: "The task was marked as ", children: <InlineSpan>[
          const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Label(text: "Done", backgroundColor: Colors.green)),
          const WidgetSpan(child: Text(" by ")),
          WidgetSpan(
              child: Text(message.userName,
                  style: const TextStyle(color: Colors.blue))),
        ]));
      case MessageAction.CloseTaskAction:
        return Text.rich(TextSpan(text: "The task was ", children: <InlineSpan>[
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Label(
              text: "Closed",
              backgroundColor: Colors.green,
            ),
          ),
          const WidgetSpan(child: Text(" by ")),
          WidgetSpan(
              child: Text(message.userName,
                  style: const TextStyle(color: Colors.blue))),
        ]));

      case MessageAction.RemoveCompletedLabelAction:
        return Text.rich(TextSpan(text: "The lable ", children: <InlineSpan>[
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Label(
              text: "Done",
              backgroundColor: Colors.green,
            ),
          ),
          const WidgetSpan(child: Text(" was removed by ")),
          WidgetSpan(
              child: Text(
            message.userName,
            style: const TextStyle(color: Colors.blue),
          )),
        ]));
      default:
        return const Text("");
    }
  }

  Color getBubbleColor() {
    if (message.isTaskDescriptionItem) {
      return msgListProvider.task!.completed
          ? closedTaskColor
          : uncompletedTaskColor;
    } else {
      return isCurrentUser
          ? const Color.fromARGB(255, 187, 239, 251)
          : const Color.fromARGB(255, 224, 224, 224);
    }
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints,
      Uint8List? loadingFileData) {
    if (message.messageAction != MessageAction.CreateUpdateMessageAction) {
      return DecoratedBox(
        // chat bubble decoration
        decoration: BoxDecoration(
          border: message.isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
          color: const Color.fromARGB(255, 228, 232, 233),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: getMessageActionDescription(message)),
      );
      // Text bubble
    } else if (message.fileName.isEmpty) {
      final text = message.isTaskDescriptionItem
          ? msgListProvider.task?.description
          : message.text;
      final textSpan = TextSpan(text: text);
      BoolRef isQuoteSelected = BoolRef();
      TextSelection textWidgetSelection =
          const TextSelection(baseOffset: 0, extentOffset: 0);
      final textWidget = SelectableText.rich(textSpan,
          selectionControls: messageSelectionControl(msgListProvider, text,
              message.ID, messageTextFieldFocusNode, context),
          onSelectionChanged:
              (TextSelection selection, SelectionChangedCause? cause) {
        textWidgetSelection = selection;
        isQuoteSelected.value =
            textWidgetSelection.start != textWidgetSelection.end;
      });
      /*final TextBox? lastBox =
          calcLastLineEnd(message.text, textSpan, context, constraints);
      bool fitsLastLine = false;
      if (lastBox != null) {
        fitsLastLine =
            constraints.maxWidth - lastBox.right > Timestamp.size.width + 10.0;
      }*/

      return GestureDetectorWithMenu(
        onSecondaryTapDown: (details) {
          msgListProvider.selectItem(message);
        },
        onCopy: () {
          message.isSelected = false;
          var text = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          if (textWidgetSelection.start != textWidgetSelection.end) {
            text = text.substring(
                textWidgetSelection.start, textWidgetSelection.end);
          }
          //Pasteboard.writeText(text);
          Clipboard.setData(ClipboardData(text: text)).then((value) {
            //toast("Text copied to clipboard", context, 500);
          });
        },
        onReply: () async {
          message.isSelected = false;
          msgListProvider.quotedText = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          msgListProvider.currentParentMessageID = message.ID;

          msgListProvider.refresh();
          //FocusScope.of(context).unfocus();
          searchFocusNode.unfocus();
          //messageTextFieldFocusNode.dispose();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        },
        onDelete: () => msgListProvider.deleteMesage(message.ID),
        isQuoteSelected: isQuoteSelected,
        onQuoteSelection: () async {
          message.isSelected = false;
          var text = message.isTaskDescriptionItem
              ? msgListProvider.task?.description ?? ""
              : message.text;
          text = text.substring(
              textWidgetSelection.start, textWidgetSelection.end);
          msgListProvider.quotedText = text;
          msgListProvider.currentParentMessageID = message.ID;
          //FocusScope.of(context).unfocus();
          searchFocusNode.unfocus();
          //messageTextFieldFocusNode.dispose();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        },
        /*return GestureDetector(
        onSecondaryTapDown: (details) async {
          msgListProvider.selectItem(message);
          final x = details.globalPosition.dx;
          final y = details.globalPosition.dy;
          final selected = await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(x, y, x, y),
            items: [
              PopupMenuItem<String>(
                  child: const Text('Copy'),
                  onTap: () async {
                    message.isSelected = false;
                    var text = message.isTaskDescriptionItem
                        ? msgListProvider.task?.description ?? ""
                        : message.text;
                    if (textWidgetSelection.start != textWidgetSelection.end) {
                      text = text.substring(
                          textWidgetSelection.start, textWidgetSelection.end);
                    }
                    //Pasteboard.writeText(text);
                    Clipboard.setData(ClipboardData(text: text)).then((value) {
                      //toast("Text copied to clipboard", context, 500);
                    });
                  }),
              if (textWidgetSelection.start != textWidgetSelection.end)
                PopupMenuItem<String>(
                    child: const Text('Quote selection'),
                    onTap: () async {
                      message.isSelected = false;
                      var text = message.isTaskDescriptionItem
                          ? msgListProvider.task?.description ?? ""
                          : message.text;
                      text = text.substring(
                          textWidgetSelection.start, textWidgetSelection.end);
                      msgListProvider.quotedText = text;
                      msgListProvider.currentParentMessageID = message.ID;
                      //FocusScope.of(context).unfocus();
                      searchFocusNode.unfocus();
                      //messageTextFieldFocusNode.dispose();
                      messageTextFieldFocusNode.requestFocus();
                      msgListProvider.refresh();
                    }),
              PopupMenuItem<String>(
                  child: const Text('Reply'),
                  onTap: () async {
                    message.isSelected = false;
                    msgListProvider.quotedText = message.isTaskDescriptionItem
                        ? msgListProvider.task?.description ?? ""
                        : message.text;
                    msgListProvider.currentParentMessageID = message.ID;

                    msgListProvider.refresh();
                    //FocusScope.of(context).unfocus();
                    searchFocusNode.unfocus();
                    //messageTextFieldFocusNode.dispose();
                    messageTextFieldFocusNode.requestFocus();
                    msgListProvider.refresh();
                  }),
              if (!message.isTaskDescriptionItem)
                const PopupMenuItem<String>(
                  value: 'Delete',
                  child: Text('Delete'),
                ),
            ],
          );
          if (selected == "Delete") {
            message.isSelected = false;
            var res = await confirmDismissDlg(context);
            if (res ?? false) {
              msgListProvider.deleteMesage(message.ID);
            }
          }
        },*/
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            border: message.isSelected
                ? Border.all(color: Colors.blueAccent, width: 3)
                : Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
            color: getBubbleColor(),
            borderRadius:
                BorderRadius.circular(message.isTaskDescriptionItem ? 0 : 8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            //child: IntrinsicWidth(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (message.quotedText != null && message.quotedText!.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          msgListProvider.jumpTo(message.parentMessageID);
                        },
                        child: Text(
                          message.quotedText ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ))),
              if (message.parentsmallImageName.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: networkImage(
                      serverURI.scheme +
                          '://' +
                          serverURI.authority +
                          "/FileStorage/" +
                          message.parentsmallImageName,
                      height: 60,
                      headers: {"sessionID": sessionID},
                      onTap: () {
                        msgListProvider.jumpTo(message.parentMessageID);
                      },
                    )),
              if (message.quotedText != null && message.quotedText!.isNotEmpty)
                const Divider(),
              if (!message.isTaskDescriptionItem &&
                  message.userName.isNotEmpty &&
                  (index == msgListProvider.items.length - 1 ||
                      msgListProvider.items[index + 1].userID !=
                          message.userID))
                Text(
                  message.userName,
                  style: const TextStyle(color: Colors.blue),
                ),
              //Stack(children: [
              if (message.isTaskDescriptionItem)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Created by ${msgListProvider.task!.authorName} at ${dateFormat(msgListProvider.task!.creation_date)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      SelectableText(
                        msgListProvider.task!.ID.toString().padLeft(6, '0'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ]),
              if (message.isTaskDescriptionItem) const SizedBox(height: 5),
              /*if (lastBox != null)
                      SizedBox.fromSize(
                          size: Size(
                            Timestamp.size.width + lastBox.right,
                            (fitsLastLine ? lastBox.top : lastBox.bottom) +
                                Timestamp.size.height +
                                5,
                          ),
                          child: Container()),*/
              textWidget,
              /*Positioned(
                      left: lastBox != null ? lastBox.right + 5 : 0,
                      //constraints.maxWidth - (Timestamp.size.width + 10.0),
                      top: lastBox != null
                          ? (fitsLastLine ? lastBox.top : lastBox.bottom) + 5
                          : 0.0,
                      child: Timestamp(message.created_at ?? DateTime.now()),
                    ),*/
              /*Align(
                      alignment: Alignment.bottomRight,
                      child: Timestamp(message.created_at ?? DateTime.now()),
                    )*/
            ]),
          ),
          //  ),
        ),
      );
      //);
    } else {
      // Image bubble
      if (message.isImage &&
          (message.smallImageName.isNotEmpty || loadingFileData != null)) {
        return loadingFileData != null
            ? Stack(children: [
                memoryImage(
                  loadingFileData,
                  height: 200,
                  onTap: () => onTapOnFileMessage(message, context),
                ),
                if (message.loadinInProcess)
                  const Positioned(
                      width: 15,
                      height: 15,
                      right: 10,
                      bottom: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                        //value: progress,
                      ))
              ])
            : NetworkImageWithMenu(
                serverURI.scheme +
                    '://' +
                    serverURI.authority +
                    "/FileStorage/" +
                    message.smallImageName,
                headers: {"sessionID": sessionID},
                onTap: () {
                  onTapOnFileMessage(message, context);
                },
                onCopy: () async {
                  final fileData = await msgListProvider
                      .getFile(message.smallImageName, context: context);
                  Pasteboard.writeImage(fileData);
                },
                onCopyOriginal: () {
                  final ProgressDialog pd = ProgressDialog(context: context);
                  //pr.show();
                  pd.show(max: 100, msg: 'File Downloading...');
                  List<int> fileData = []; // = Uint8List(0);
                  msgListProvider.getFile(message.localFileName,
                      context: context, onData: (value) {
                    fileData.addAll(value);
                  }, onDone: () async {
                    pd.close();
                    Pasteboard.writeImage(Uint8List.fromList(fileData));
                  });
                },
                onDelete: () => msgListProvider.deleteMesage(message.ID),
                onReply: () {
                  msgListProvider.parentsmallImageName = message.smallImageName;
                  msgListProvider.quotedText = message.text;
                  msgListProvider.currentParentMessageID = message.ID;
                  //messageTextFieldFocusNode.dispose();

                  searchFocusNode.unfocus();
                  messageTextFieldFocusNode.requestFocus();
                  msgListProvider.refresh();
                },
                width: message.smallImageWidth.toDouble(),
                height: message.smallImageHeight.toDouble(),
                previewImageData: message.previewSmallImageData);
      } else {
        // File bubble
        return GestureDetectorWithMenu(
            onTap: () => onTapOnFileMessage(message, context),
            onSecondaryTapDown: (details) {
              msgListProvider.selectItem(message);
            },
            onDelete: () => msgListProvider.deleteMesage(message.ID),
            addMenuItems: [
              if (Platform().isWindows)
                PopupMenuItem<String>(
                    child: const Text('Save as...'),
                    onTap: () async {
                      String? fileName = await FilePicker.platform
                          .saveFile(fileName: message.fileName);

                      if (fileName == null || fileName.isEmpty) {
                        return;
                      }

                      final ProgressDialog pd =
                          ProgressDialog(context: context);
                      //pr.show();
                      pd.show(max: 100, msg: 'File Downloading...');
                      List<int> fileData = []; // = Uint8List(0);
                      msgListProvider.getFile(message.localFileName,
                          context: context, onData: (value) {
                        fileData.addAll(value);
                      }, onDone: () async {
                        pd.close();
                        if (fileData.isNotEmpty) {
                          saveFile(fileData, fileName);
                        }
                      });
                    }),
            ],
            child: DecoratedBox(
              // attached file
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.blue
                    : const Color.fromARGB(255, 224, 224, 224),
                borderRadius: BorderRadius.circular(8),
                border: message.isSelected
                    ? Border.all(color: Colors.blueAccent, width: 3)
                    : Border.all(
                        color: const Color.fromARGB(255, 228, 232, 233)),
              ),
              //child: GestureDetector(
              //onTap: () => onTapOnFileMessage(message, context),
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.file_present_rounded,
                                color: Colors.white),
                            const SizedBox(width: 10),
                            FittedBox(
                                fit: BoxFit.fill,
                                alignment: Alignment.center,
                                child: SelectableText(
                                  message.fileName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: isCurrentUser
                                              ? Colors.white
                                              : Colors.black87),
                                )),
                            if (message.loadinInProcess)
                              const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                        //value: progress,
                                      )))
                          ]))),
              //),
            ));
      }
    }
  }

  void onTapOnFileMessage(Message message, context) async {
    msgListProvider.selectItem(message);
    if (message.isImage && message.localFileName.isNotEmpty) {
      // var res = await getFile(message.localFileName);
      var res = NetworkImage(
          "${serverURI.scheme}://${serverURI.authority}/FileStorage/${message.localFileName}",
          headers: {"sessionID": sessionID});
      //if (res.isNotEmpty) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ImageDialog(imageProvider: res, fileSize: message.fileSize)));
      //}
    } else if (message.isImage && uploadingFiles.containsKey(message.tempID)) {
      // var res = await getFile(message.localFileName);
      var res = Image.memory(uploadingFiles[message.tempID]!.loadingFileData);
      //if (res.isNotEmpty) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ImageDialog(
                  imageProvider: res.image, fileSize: message.fileSize)));
      //}
    } else if (message.localFileName.isNotEmpty) {
      var res = await msgListProvider.getFile(message.localFileName,
          context: context);
      if (res.isNotEmpty) {
        var localFullName = await saveInDownloads(res, message.fileName);
        if (localFullName.isNotEmpty) {
          OpenFileInApp(localFullName);
        }
      }
    }
  }
}

class NewMessageActionsMenu extends StatelessWidget {
  final MsgListProvider msgListProvider;

  const NewMessageActionsMenu({Key? key, required this.msgListProvider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final task = msgListProvider.task as Task;

    List<PopupMenuItem> items = [
      /*CheckedPopupMenuItem<String>(
          value: "Done", checked: task.closed, child: const Text('Done')),
      CheckedPopupMenuItem<String>(
          value: "Closed", checked: task.closed, child: const Text('Closed')),*/
      if (!task.completed)
        PopupMenuItem(
            child: const Label(
              text: 'Done',
              backgroundColor: Colors.green,
              clickableCursor: true,
            ),
            onTap: () {
              msgListProvider.createMessage(
                  text: "",
                  task: msgListProvider.task,
                  messageAction: MessageAction.CompleteTaskAction);
              msgListProvider.task!.completed = true;
            }),
      if (task.completed)
        PopupMenuItem(
            child: const Text.rich(
                TextSpan(text: "Remove the ", children: <InlineSpan>[
              WidgetSpan(
                //baseline: TextBaseline.ideographic,
                alignment: PlaceholderAlignment.middle,
                child: Label(
                  text: "Done",
                  backgroundColor: Colors.green,
                  clickableCursor: true,
                ),
              ),
              WidgetSpan(child: Text("label"))
            ])),
            onTap: () {
              msgListProvider.createMessage(
                  text: "",
                  task: msgListProvider.task,
                  messageAction: MessageAction.RemoveCompletedLabelAction);
              msgListProvider.task!.completed = false;
            }),
      if (!task.cancelled)
        PopupMenuItem(
            child: const Label(
              text: 'Cancel task',
              backgroundColor: Colors.grey,
              clickableCursor: true,
            ),
            onTap: () {
              msgListProvider.createMessage(
                  text: "",
                  task: msgListProvider.task,
                  messageAction: MessageAction.CancelTaskAction);
              msgListProvider.task!.cancelled = true;
            }),
      if (task.cancelled || task.closed)
        PopupMenuItem(
            child: const Label(
              text: 'Reopen task',
              backgroundColor: Colors.orange,
              clickableCursor: true,
            ),
            onTap: () {
              msgListProvider.createMessage(
                  text: "",
                  task: msgListProvider.task,
                  messageAction: MessageAction.ReopenTaskAction);
              msgListProvider.task!.cancelled = false;
              msgListProvider.task!.completed = false;
              msgListProvider.task!.closed = false;
            }),
    ];

    return PopupMenuButton(
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),

      // add icon, by default "3 dot" icon
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[800],
      ),
      itemBuilder: (context) {
        return items;
      },
      /*onSelected: (String result) {
        switch (result) {
          case "Closed":
            createMessage(
                text: "",
                msgListProvider: msgListProvider,
                messageAction: task.closed
                    ? MessageAction.ReopenTaskAction
                    : MessageAction.CloseTaskAction);
            task.closed = !task.closed;
            break;
          case "Done":
            createMessage(
                text: "",
                msgListProvider: msgListProvider,
                messageAction: task.completed
                    ? MessageAction.ReopenTaskAction
                    : MessageAction.CompleteTaskAction);
            task.completed = !task.completed;
            break;
        }
      },*/
    );
  }
}

FlutterSelectionControls messageSelectionControl(
    MsgListProvider msgListProvider,
    String? messageText,
    int messageID,
    FocusNode messageTextFieldFocusNode,
    BuildContext context) {
  return FlutterSelectionControls(toolBarItems: [
    ToolBarItem(
        item: const Text('Select All'),
        itemControl: ToolBarItemControl.selectAll),
    ToolBarItem(item: const Text('Copy'), itemControl: ToolBarItemControl.copy),
    ToolBarItem(
        item: const Text('Reply'),
        onItemPressed: (String highlightedText, int startIndex, int endIndex) {
          msgListProvider.quotedText = messageText ?? "";
          msgListProvider.currentParentMessageID = messageID;

          //messageTextFieldFocusNode.dispose();
          searchFocusNode.unfocus();
          messageTextFieldFocusNode = FocusNode();
          messageTextFieldFocusNode.requestFocus();
          msgListProvider.refresh();
        }),
    if (messageText != null)
      ToolBarItem(
          item: const Text('Quote selection'),
          onItemPressed:
              (String highlightedText, int startIndex, int endIndex) {
            msgListProvider.quotedText =
                messageText.substring(startIndex, endIndex);
            msgListProvider.currentParentMessageID = messageID;
            //messageTextFieldFocusNode.dispose();
            searchFocusNode.unfocus();
            messageTextFieldFocusNode = FocusNode();
            messageTextFieldFocusNode.requestFocus();
            msgListProvider.refresh();
          }),
    ToolBarItem(
        item: const Text('Delete'),
        onItemPressed:
            (String highlightedText, int startIndex, int endIndex) async {
          var res = await confirmDismissDlg(context);
          if (res ?? false) {
            msgListProvider.deleteMesage(messageID);
          }
        })
  ]);
}
