import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:todochat/constants.dart';
import 'package:todochat/models/message.dart';
import 'package:todochat/ui_components/chat_text_bubble.dart';
import 'package:todochat/ui_components/context_menu_detector.dart';
import 'package:todochat/ui_components/network_image_with_menu.dart';
import 'package:todochat/ui_components/tile_menu.dart';
import 'msglist_actions_menu.dart';
import 'package:todochat/todochat.dart';
import 'package:todochat/utils.dart';
import 'customWidgets.dart';
import 'state/msglist_provider.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class MsgListTile extends StatefulWidget {
  const MsgListTile(
      {Key? key,
      required this.message,
      required this.onDismissed,
      required this.isCurrentUser,
      required this.msgListProvider,
      required this.index})
      : super(key: key);
  final Message message;
  final bool isCurrentUser;
  final MsgListProvider msgListProvider;
  final int index;

  //double progress = 1.0;
  /*final String text;
  final String isImage = false;
  final Uint8List? smallImageData;
  final bool isCurrentUser;*/
  final DismissDirectionCallback onDismissed;

  @override
  State<MsgListTile> createState() => _MsgListTileState();
}

class _MsgListTileState extends State<MsgListTile> {
  // TextSelection textWidgetSelection =
  //     const TextSelection(baseOffset: 0, extentOffset: 0);

  /*final Future<Uint8List> Function(String localFileName,
      {Function(List<int> value)? onData,
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) getFile;*/
//   TextBox? calcLastLineEnd(String text, TextSpan textSpan, BuildContext context,
//       BoxConstraints constraints) {
//     final richTextWidget = Text.rich(textSpan).build(context) as RichText;
//     final renderObject = richTextWidget.createRenderObject(context);
//     renderObject.layout(constraints);
//     var boxes = renderObject.getBoxesForSelection(
//         TextSelection(baseOffset: 0, extentOffset: text.length));

// /*final TextPainter textPainter = TextPainter(
//       text: textSpan,
//       textDirection: TextDirection.ltr,
//       maxLines: 1,
//     )..layout(minWidth: 0, maxWidth: double.infinity);
// */

//     if (boxes.isEmpty) {
//       return null;
//     } else {
//       return boxes.last;
//     }
//   }

  @override
  Widget build(BuildContext context) {
    final foundStruct = uploadingFiles[widget.message.tempID];
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        // asymmetric padding
        padding: widget.message.isTaskDescriptionItem
            ? const EdgeInsets.fromLTRB(0, 0, 0, 0)
            : EdgeInsets.fromLTRB(
                widget.isCurrentUser ? 64.0 : 16.0,
                4,
                widget.isCurrentUser ? 16.0 : 64.0,
                4,
              ),
        child: Align(
            // align the child within the container
            alignment: widget.message.isTaskDescriptionItem ||
                    widget.message.messageAction !=
                        MessageAction.CreateUpdateMessageAction
                ? Alignment.center
                : widget.isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child:
                drawBubble(context, constraints, foundStruct?.loadingFileData)),
      );
    });
  }

  Color getBubbleColor() {
    if (widget.message.isTaskDescriptionItem) {
      return widget.msgListProvider.task.completed
          ? closedTaskColor
          : uncompletedTaskColor;
    } else {
      return widget.isCurrentUser
          ? const Color.fromARGB(255, 187, 239, 251)
          : const Color.fromARGB(255, 224, 224, 224);
    }
  }

  Widget drawBubble(BuildContext context, BoxConstraints constraints,
      Uint8List? loadingFileData) {
    final message = widget.message;
    final msgListProvider = widget.msgListProvider;

    if (widget.message.messageAction !=
        MessageAction.CreateUpdateMessageAction) {
      return ChatTextBubble(
        leading: getMessageActionDescription(widget.message),
        onDelete: () => widget.msgListProvider.deleteMesage(widget.message.ID),
        backgroundColor: const Color.fromARGB(255, 228, 232, 233),
      );

      // Text bubble
    } else if (widget.message.fileName.isEmpty &&
        !widget.message.isTaskDescriptionItem) {
      return ChatTextBubble(
        text: widget.message.text,
        backgroundColor: getBubbleColor(),
        quotedText: message.quotedText,
        quotedImageURL: message.parentsmallImageName.isNotEmpty
            ? serverURI.scheme +
                '://' +
                serverURI.authority +
                "/FileStorage/" +
                message.parentsmallImageName
            : "",
        HTTPHeaders: {"sessionID": sessionID},
        onCopy: () => Clipboard.setData(ClipboardData(text: message.text)),
        onReply: () {
          msgListProvider.quotedText = message.text;
          msgListProvider.currentParentMessageID = message.ID;
          widget.msgListProvider.messageTextFieldFocusNode.unfocus();
          msgListProvider.setEditBoxFocus = true;
          msgListProvider.refresh();
          //widget.msgListProvider.messageTextFieldFocusNode.requestFocus();
        },
        onDelete: () => msgListProvider.deleteMesage(message.ID),
        onQuoteSelection: (selectedText) async {
          msgListProvider.quotedText = selectedText;
          msgListProvider.currentParentMessageID = message.ID;
          //searchFocusNode.unfocus();
          widget.msgListProvider.messageTextFieldFocusNode.unfocus();
          msgListProvider.setEditBoxFocus = true;
          msgListProvider.refresh();
        },
        onEdit: () {
          msgListProvider.editMode = true;
          msgListProvider.quotedText = message.text;
          msgListProvider.messageInputController.text = message.text;
          msgListProvider.editingMessage = message;
          msgListProvider.refresh();
        },
        onTapOnQuotedMessage: () {
          msgListProvider.jumpTo(message.parentMessageID);
        },
      );
    } else if (widget.message.isTaskDescriptionItem) {
      // Task Description
      return ChatTextBubble(
        text: widget.msgListProvider.task.description,
        leading:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            "Created by ${widget.msgListProvider.task.authorName} at ${dateFormat(widget.msgListProvider.task.creation_date)}",
            style: const TextStyle(color: Colors.grey),
          ),
          SelectableText(
            widget.msgListProvider.task.ID.toString().padLeft(6, '0'),
            style: const TextStyle(color: Colors.grey),
          ),
        ]),
        backgroundColor: getBubbleColor(),
        onCopy: () => Clipboard.setData(
            ClipboardData(text: msgListProvider.task.description)),
        onReply: () {
          msgListProvider.quotedText = msgListProvider.task.description;
          msgListProvider.currentParentMessageID = message.ID;
          widget.msgListProvider.messageTextFieldFocusNode.unfocus();
          msgListProvider.setEditBoxFocus = true;
          msgListProvider.refresh();
        },
        onQuoteSelection: (selectedText) async {
          msgListProvider.quotedText = selectedText;
          msgListProvider.currentParentMessageID = message.ID;
          //searchFocusNode.unfocus();
          widget.msgListProvider.messageTextFieldFocusNode.unfocus();
          msgListProvider.setEditBoxFocus = true;
          msgListProvider.refresh();
        },
      );
    } else {
      // Image bubble
      if (widget.message.isImage &&
          (widget.message.smallImageName.isNotEmpty ||
              loadingFileData != null)) {
        return loadingFileData != null
            ? Stack(children: [
                memoryImage(
                  loadingFileData,
                  height: 200,
                  onTap: () => onTapOnFileMessage(widget.message, context),
                ),
                if (widget.message.loadinInProcess)
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
            : CachedNetworkImageWithMenu(
                '${serverURI.scheme}://${serverURI.authority}/FileStorage/${widget.message.smallImageName}',
                headers: {"sessionID": sessionID},
                onTap: () {
                  onTapOnFileMessage(widget.message, context);
                },
                onCopy: () async {
                  final fileData = await widget.msgListProvider
                      .getFile(widget.message.smallImageName, context: context);
                  Pasteboard.writeImage(fileData);
                },
                onCopyOriginal: () {
                  final ProgressDialog pd = ProgressDialog(context: context);
                  //pr.show();
                  pd.show(max: 100, msg: 'File Downloading...');
                  List<int> fileData = []; // = Uint8List(0);
                  widget.msgListProvider.getFile(widget.message.localFileName,
                      context: context, onData: (value) {
                    fileData.addAll(value);
                  }, onDone: () async {
                    pd.close();
                    Pasteboard.writeImage(Uint8List.fromList(fileData));
                  });
                },
                onDelete: () =>
                    widget.msgListProvider.deleteMesage(widget.message.ID),
                onReply: () {
                  widget.msgListProvider.parentsmallImageName =
                      widget.message.smallImageName;
                  widget.msgListProvider.quotedText = widget.message.text;
                  widget.msgListProvider.currentParentMessageID =
                      widget.message.ID;
                  //messageTextFieldFocusNode.dispose();

                  //searchFocusNode.unfocus();
                  //FocusScope.of(context).requestFocus(widget.msgListProvider);
                  widget.msgListProvider.messageTextFieldFocusNode.unfocus();
                  msgListProvider.setEditBoxFocus = true;
                  widget.msgListProvider.refresh();
                },
                width: widget.message.smallImageWidth.toDouble(),
                height: widget.message.smallImageHeight.toDouble());
      } else {
        // File bubble
        return ContextMenuDetector(
            onTap: () => onTapOnFileMessage(widget.message, context),
            onContextMenu: (Offset position) {
              TileMenu.show(
                context: context,
                position: position,
                onDelete: () =>
                    widget.msgListProvider.deleteMesage(widget.message.ID),
                addMenuItems: [
                  if (Platform().isWindows)
                    PopupMenuItem<String>(
                        child: const Text('Save as...'),
                        onTap: () async {
                          String? fileName = await FilePicker.platform
                              .saveFile(fileName: widget.message.fileName);

                          if (fileName == null || fileName.isEmpty) {
                            return;
                          }

                          final ProgressDialog pd =
                              ProgressDialog(context: context);
                          //pr.show();
                          pd.show(max: 100, msg: 'File Downloading...');
                          List<int> fileData = []; // = Uint8List(0);
                          widget.msgListProvider.getFile(
                              widget.message.localFileName,
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
              );
            },
            child: DecoratedBox(
              // attached file
              decoration: BoxDecoration(
                color: widget.isCurrentUser
                    ? Colors.blue
                    : const Color.fromARGB(255, 224, 224, 224),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
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
                                  widget.message.fileName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          color: widget.isCurrentUser
                                              ? Colors.white
                                              : Colors.black87),
                                )),
                            if (widget.message.loadinInProcess)
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
      final ProgressDialog pd = ProgressDialog(context: context);
      pd.show(max: 100, msg: 'File Downloading...');
      final List<int> fileData =
          []; // Use a List<int> for dynamic data addition
      try {
        await widget.msgListProvider.getFile(widget.message.localFileName,
            context: context, onData: (value) {
          fileData.addAll(value);
        }, onDone: () async {
          pd.close();
          if (fileData.isNotEmpty) {
            final localFullName = await saveInDownloads(
                Uint8List.fromList(fileData), message.fileName);
            if (localFullName.isNotEmpty) {
              OpenFileInApp(localFullName);
            }
          }
        });
      } catch (error) {
        pd.close();
        toast("Error downloading file: $error", context);
      }
      // var res = await widget.msgListProvider
      //     .getFile(message.localFileName, context: context);
    }
  }
}

// FlutterSelectionControls messageSelectionControl(
//     MsgListProvider msgListProvider,
//     String? messageText,
//     int messageID,
//     FocusNode messageTextFieldFocusNode,
//     BuildContext context) {
//   return FlutterSelectionControls(toolBarItems: [
//     ToolBarItem(
//         item: const Text('Select All'),
//         itemControl: ToolBarItemControl.selectAll),
//     ToolBarItem(item: const Text('Copy'), itemControl: ToolBarItemControl.copy),
//     ToolBarItem(
//         item: const Text('Reply'),
//         onItemPressed: (String highlightedText, int startIndex, int endIndex) {
//           msgListProvider.quotedText = messageText ?? "";
//           msgListProvider.currentParentMessageID = messageID;

//           //messageTextFieldFocusNode.dispose();
//           searchFocusNode.unfocus();
//           messageTextFieldFocusNode = FocusNode();
//           messageTextFieldFocusNode.requestFocus();
//           msgListProvider.refresh();
//         }),
//     if (messageText != null)
//       ToolBarItem(
//           item: const Text('Quote selection'),
//           onItemPressed:
//               (String highlightedText, int startIndex, int endIndex) {
//             msgListProvider.quotedText =
//                 messageText.substring(startIndex, endIndex);
//             msgListProvider.currentParentMessageID = messageID;
//             //messageTextFieldFocusNode.dispose();
//             searchFocusNode.unfocus();
//             messageTextFieldFocusNode = FocusNode();
//             messageTextFieldFocusNode.requestFocus();
//             msgListProvider.refresh();
//           }),
//     ToolBarItem(
//         item: const Text('Delete'),
//         onItemPressed:
//             (String highlightedText, int startIndex, int endIndex) async {
//           var res = await confirmDismissDlg(context);
//           if (res ?? false) {
//             msgListProvider.deleteMesage(messageID);
//           }
//         })
//   ]);
// }
