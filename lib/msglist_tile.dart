import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
//import 'package:text_selection_controls/text_selection_controls.dart';
import 'msglist_actions_menu.dart';
import 'text_selection_controls.dart';
//import 'package:todochat/tasklist_provider.dart';
import 'package:todochat/todochat.dart';
import 'package:todochat/utils.dart';

import 'customWidgets.dart';
import 'msglist_provider.dart';

import 'package:easy_image_viewer/easy_image_viewer.dart';

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
    });
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
      return GestureDetectorWithMenu(
        child: DecoratedBox(
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
        ),
        onDelete: () => msgListProvider.deleteMesage(message.ID),
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
              textWidget,
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
                '${serverURI.scheme}://${serverURI.authority}/FileStorage/${message.smallImageName}',
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
      await showImageViewer(context, res);

      // await Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) =>
      //             ImageDialog(imageProvider: res, fileSize: message.fileSize)));
      //}
    } else if (message.isImage && uploadingFiles.containsKey(message.tempID)) {
      // var res = await getFile(message.localFileName);
      var res = Image.memory(uploadingFiles[message.tempID]!.loadingFileData);
      await showImageViewer(context, res.image);
      //if (res.isNotEmpty) {
      // await Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => ImageDialog(
      //             imageProvider: res.image, fileSize: message.fileSize)));
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
