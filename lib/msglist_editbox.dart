import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pasteboard/pasteboard.dart';
//import 'package:super_clipboard/super_clipboard.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:todochat/models/message.dart';
import 'package:todochat/state/msglist_provider.dart';
import 'package:todochat/todochat.dart';

import 'msglist_actions_menu.dart';
import 'customWidgets.dart';
import 'utils.dart';

class EditMessageBox extends StatefulWidget {
  final MsgListProvider msglist;

  EditMessageBox({required this.msglist, super.key});

  @override
  State<EditMessageBox> createState() => _EditMessageBoxState();
}

class _EditMessageBoxState extends State<EditMessageBox> {
  @override
  void dispose() {
    // widget.msglist.messageTextFieldFocusNode.unfocus();
    // widget.msglist.messageTextFieldFocusNode.dispose();
    // widget.msglist.messageInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.msglist.setEditBoxFocus) {
        widget.msglist.setEditBoxFocus = false;
        FocusScope.of(context).unfocus();
        widget.msglist.messageTextFieldFocusNode.requestFocus();
      }
    });
    return // Edit message box
        //   Padding(
        // padding: const EdgeInsets.only(bottom: 10),
        //child:
        Container(
      padding: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Column(children: [
        if (widget.msglist.quotedText.isNotEmpty ||
            widget.msglist.parentsmallImageName.isNotEmpty)
          Row(children: [
            if (widget.msglist.parentsmallImageName.isNotEmpty)
              networkImage(
                  '${serverURI.scheme}://${serverURI.authority}/FileStorage/${widget.msglist.parentsmallImageName}',
                  height: Platform().isAndroid ? 30 : 60),
            Expanded(
                child: Text(
              widget.msglist.quotedText,
              style: const TextStyle(color: Colors.grey),
            )),
            SizedBox(
                //width: 20,
                child: IconButton(
                    onPressed: () {
                      widget.msglist.quotedText = "";
                      widget.msglist.parentsmallImageName = "";
                      if (widget.msglist.editMode) {
                        widget.msglist.editMode = false;
                        widget.msglist.messageInputController.text = "";
                      }
                      widget.msglist.refresh();
                    },
                    icon: const Icon(Icons.close)))
          ]),
        if (widget.msglist.quotedText.isNotEmpty) const Divider(),
        Row(
          children: [
            ActionsMenu(),
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter,
                      control: false): () {
                    if (widget.msglist.messageInputController.text.isNotEmpty) {
                      if (widget.msglist.editMode) {
                        widget.msglist.updateMessage(
                            text: widget.msglist.messageInputController.text);
                      } else
                        widget.msglist.createMessage(
                            text: widget.msglist.messageInputController.text,
                            task: widget.msglist.task);
                      widget.msglist.messageInputController.text = "";
                    }
                  },
                  const SingleActivator(LogicalKeyboardKey.escape,
                      control: false): () {
                    if (widget.msglist.quotedText.isNotEmpty ||
                        widget.msglist.parentsmallImageName.isNotEmpty) {
                      widget.msglist.quotedText = "";
                      widget.msglist.parentsmallImageName = "";
                      widget.msglist.refresh();
                    }
                  },
                  const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                      () async {
                    // final clipboard = SystemClipboard.instance;
                    // if (clipboard == null) {
                    //   return; // Clipboard API is not supported on this platform.
                    // }
                    // final reader = await clipboard.read();

                    // if (reader.canProvide(Formats.htmlText)) {
                    //   final html = await reader.readValue(Formats.htmlText);

                    //   //var html = await Pasteboard.html;
                    //   if (html != null && html.isNotEmpty) {
                    //     String imageURL = getImageURLFromHTML(html);
                    //     if (imageURL.isNotEmpty) {
                    //       Response response;
                    //       try {
                    //         response = await get(Uri.parse(imageURL));
                    //       } catch (e) {
                    //         toast(e.toString(), context);
                    //         return;
                    //       }

                    //       if (response.statusCode == 200) {
                    //         msglist.addUploadingItem(
                    //             Message(
                    //                 taskID: msglist.task.ID,
                    //                 userID: currentUserID,
                    //                 fileName: "clipboard_image.png",
                    //                 loadingFile: true,
                    //                 isImage: true),
                    //             response.bodyBytes);
                    //       }
                    //     }
                    //   }
                    // } else if ((reader.canProvide(Formats.plainText)) &&
                    //     (reader.canProvide(Formats.plainText))) {
                    //   final text =
                    //       await reader.readValue(Formats.plainText) ?? "";
                    //   msglist.messageInputController.text =
                    //       msglist.messageInputController.text + text.trim();
                    //   msglist.messageInputController.selection =
                    //       TextSelection.fromPosition(TextPosition(
                    //           offset:
                    //               msglist.messageInputController.text.length));
                    // }

                    // /// Binary formats need to be read as streams
                    // else if (reader.canProvide(Formats.png)) {
                    //   reader.getFile(Formats.png, (file) {
                    //     // Do something with the PNG image
                    //     final stream = file.getStream();
                    //     stream.fold<Uint8List>(Uint8List(0),
                    //         (previous, element) {
                    //       // Объединяем все Uint8List в один массив
                    //       final newBuffer =
                    //           Uint8List(previous.length + element.length);
                    //       newBuffer.setRange(0, previous.length, previous);
                    //       newBuffer.setRange(
                    //           previous.length, newBuffer.length, element);
                    //       return newBuffer;
                    //     }).then((Uint8List result) {
                    //       msglist.addUploadingItem(
                    //           Message(
                    //               taskID: msglist.task.ID,
                    //               userID: currentUserID,
                    //               fileName: "clipboard_image.png",
                    //               loadingFile: true,
                    //               isImage: true),
                    //           result);
                    //     });
                    //   });
                    // }

                    ClipboardData? data = await Clipboard.getData('text/plain');

                    if (data != null &&
                        data.text != null &&
                        data.text!.trim().isNotEmpty) {
                      String text = data.text ?? "";
                      widget.msglist.messageInputController.text =
                          widget.msglist.messageInputController.text +
                              text.trim();
                      widget.msglist.messageInputController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: widget
                                  .msglist.messageInputController.text.length));
                    } else {
                      final bytes = await Pasteboard.image;
                      if (bytes != null) {
                        widget.msglist.addUploadingItem(
                            Message(
                                taskID: widget.msglist.task.ID,
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
                              widget.msglist.addUploadingItem(
                                  Message(
                                      taskID: widget.msglist.task.ID,
                                      userID: currentUserID,
                                      fileName: path.basename(file),
                                      loadingFile: true,
                                      isImage: isImageFile(file)),
                                  fileData);
                            }
                          }
                        } else {
                          // final clipboard = SystemClipboard.instance;
                          // if (clipboard == null) {
                          //   return; // Clipboard API is not supported on this platform.
                          // }
                          // final reader = await clipboard.read();
                          // if (reader.canProvide(Formats.htmlText)) {
                          //   final html =
                          //       await reader.readValue(Formats.htmlText);

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
                                widget.msglist.addUploadingItem(
                                    Message(
                                        taskID: widget.msglist.task.ID,
                                        userID: currentUserID,
                                        fileName: "clipboard_image.png",
                                        loadingFile: true,
                                        isImage: true),
                                    response.bodyBytes);
                              }
                            } else {
                              widget.msglist.messageInputController.text =
                                  html.trim();
                              widget.msglist.messageInputController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: widget.msglist
                                          .messageInputController.text.length));
                            }
                          }
                        }
                      }
                    }
                  },
                },
                child: TextField(
                  focusNode: widget.msglist.messageTextFieldFocusNode,
                  autofocus: (!isDesktopMode &&
                          widget.msglist.quotedText.isEmpty &&
                          widget.msglist.parentsmallImageName.isEmpty)
                      ? false
                      : true,
                  controller: widget.msglist.messageInputController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none, // OutlineInputBorder(),
                    hintText: 'Message',
                    alignLabelWithHint: true,
                    hintStyle: TextStyle(
                        //fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (widget.msglist.messageInputController.text.isNotEmpty) {
                  if (widget.msglist.editMode) {
                    widget.msglist.updateMessage(
                        text: widget.msglist.messageInputController.text);
                  } else
                    widget.msglist.createMessage(
                        text: widget.msglist.messageInputController.text,
                        task: widget.msglist.task);
                  widget.msglist.messageInputController.text = "";
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
                    widget.msglist.addUploadingItem(
                        Message(
                            taskID: widget.msglist.task.ID,
                            userID: currentUserID,
                            fileName: path.basename(fileName),
                            loadingFile: true,
                            isImage: isImageFile(fileName)),
                        res);
                    widget.msglist.messageInputController.text = "";
                  }
                } else if (result.files.single.bytes != null &&
                    result.files.single.bytes!.isNotEmpty) {
                  var fileName = result.files.single.name;
                  widget.msglist.addUploadingItem(
                      Message(
                          taskID: widget.msglist.task.ID,
                          userID: currentUserID,
                          fileName: path.basename(fileName),
                          loadingFile: true,
                          isImage: isImageFile(fileName)),
                      result.files.single.bytes!);
                  widget.msglist.messageInputController.text = "";
                }
              },
              tooltip: 'Add file',
              icon: const Icon(Icons.attach_file),
            )
          ],
        ),
      ]),
      //),
    );
  }
}
