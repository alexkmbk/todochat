import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pasteboard/pasteboard.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:todochat/models/message.dart';
import 'package:todochat/state/msglist_provider.dart';
import 'package:todochat/todochat.dart';

import 'msglist_actions_menu.dart';
import 'customWidgets.dart';
import 'utils.dart';

class EditMessageBox extends StatelessWidget {
  final MsgListProvider msglist;
  final messageTextFieldFocusNode;

  EditMessageBox(
      {required this.msglist,
      required this.messageTextFieldFocusNode,
      super.key});

  @override
  Widget build(BuildContext context) {
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
                //width: 20,
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
            ActionsMenu(
              msglist: msglist,
            ),
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter,
                      control: false): () {
                    if (msglist.messageInputController.text.isNotEmpty) {
                      if (msglist.editMode) {
                        msglist.updateMessage(
                            text: msglist.messageInputController.text);
                      } else
                        msglist.createMessage(
                            text: msglist.messageInputController.text,
                            task: msglist.task);
                      msglist.messageInputController.text = "";
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
                  const SingleActivator(LogicalKeyboardKey.keyV, control: true):
                      () async {
                    ClipboardData? data = await Clipboard.getData('text/plain');

                    if (data != null &&
                        data.text != null &&
                        data.text!.trim().isNotEmpty) {
                      String text = data.text ?? "";
                      msglist.messageInputController.text =
                          msglist.messageInputController.text + text.trim();
                      msglist.messageInputController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset:
                                  msglist.messageInputController.text.length));
                    } else {
                      final bytes = await Pasteboard.image;
                      if (bytes != null) {
                        msglist.addUploadingItem(
                            Message(
                                taskID: msglist.task.ID,
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
                                      taskID: msglist.task.ID,
                                      userID: currentUserID,
                                      fileName: path.basename(file),
                                      loadingFile: true,
                                      isImage: isImageFile(file)),
                                  fileData);
                            }
                          }
                        } else {
                          final clipboard = SystemClipboard.instance;
                          if (clipboard == null) {
                            return; // Clipboard API is not supported on this platform.
                          }
                          final reader = await clipboard.read();
                          if (reader.canProvide(Formats.htmlText)) {
                            final html =
                                await reader.readValue(Formats.htmlText);

                            //var html = await Pasteboard.html;
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
                                          taskID: msglist.task.ID,
                                          userID: currentUserID,
                                          fileName: "clipboard_image.png",
                                          loadingFile: true,
                                          isImage: true),
                                      response.bodyBytes);
                                }
                              } else {
                                msglist.messageInputController.text =
                                    html.trim();
                                msglist.messageInputController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: msglist.messageInputController
                                            .text.length));
                              }
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
                  controller: msglist.messageInputController,
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
                if (msglist.messageInputController.text.isNotEmpty) {
                  if (msglist.editMode) {
                    msglist.updateMessage(
                        text: msglist.messageInputController.text);
                  } else
                    msglist.createMessage(
                        text: msglist.messageInputController.text,
                        task: msglist.task);
                  msglist.messageInputController.text = "";
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
                            taskID: msglist.task.ID,
                            userID: currentUserID,
                            fileName: path.basename(fileName),
                            loadingFile: true,
                            isImage: isImageFile(fileName)),
                        res);
                    msglist.messageInputController.text = "";
                  }
                } else if (result.files.single.bytes != null &&
                    result.files.single.bytes!.isNotEmpty) {
                  var fileName = result.files.single.name;
                  msglist.addUploadingItem(
                      Message(
                          taskID: msglist.task.ID,
                          userID: currentUserID,
                          fileName: path.basename(fileName),
                          loadingFile: true,
                          isImage: isImageFile(fileName)),
                      result.files.single.bytes!);
                  msglist.messageInputController.text = "";
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
