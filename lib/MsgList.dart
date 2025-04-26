import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:todochat/models/message.dart';
import 'package:todochat/msglist_editbox.dart';
import 'package:todochat/state/msglist_provider.dart';
import 'package:todochat/state/tasks.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';
import 'package:todochat/todochat.dart';
import 'msglist_tile.dart';
//import 'package:flutter_dropzone/flutter_dropzone.dart';

class MsgList extends StatefulWidget {
  const MsgList({Key? key}) : super(key: key);

  @override
  State<MsgList> createState() {
    return _MsgListState();
  }
}

class _MsgListState extends State<MsgList> {
  // late DropzoneViewController controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MsgListProvider>(
      builder: (context, provider, child) {
        final msglist = provider;
        if (msglist.task.ID == 0) {
          return const Center(child: Text("No any task was selected"));
        } else {
          if (msglist.foundMessageID > 0 && msglist.items.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              msglist.jumpTo(msglist.foundMessageID);
              msglist.foundMessageID = 0;
            });
          }
          if (msglist.loading) {
            return const Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(),
                ));
          }
          return DropRegion(
              formats: const [Formats.fileUri],
              onDropOver: (event) {
                // При наведении мышки с файлом
                return DropOperation.copy; // Return a valid DropOperation
              },
              onDropLeave: (event) {
                // Когда ушли
              },
              onPerformDrop: (PerformDropEvent event) async {
                final fileItems = await event.session.items;
                for (final fileItem in fileItems) {
                  final reader = fileItem.dataReader!;
                  if (reader.canProvide(Formats.fileUri)) {
                    reader.getFile(null, (file) async {
                      final data = await file.readAll();
                      final name = file.fileName;
                      msglist.addUploadingItem(
                          Message(
                              taskID: msglist.task.ID,
                              userID: currentUserID,
                              fileName: name ?? "",
                              loadingFile: true,
                              isImage:
                                  false), // Set isImage to false for any file type
                          data);
                    }, onError: (error) {
                      print('Error reading value $error');
                    });
                  }
                }
              },
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: InfiniteList(
                      scrollController: msglist.scrollController,
                      reverse: true,
                      itemCount: msglist.items.length,
                      isLoading: msglist.loading,
                      onFetchData: () {
                        msglist.requestMessages(
                            Provider.of<TasksState>(context, listen: false),
                            context);
                      },
                      emptyBuilder: (context) =>
                          Text("No any task was selected"),
                      itemBuilder: (context, index) {
                        var item = msglist.items[index];
                        return AutoScrollTag(
                            key: ValueKey(index),
                            controller: msglist.scrollController,
                            index: index,
                            child: MsgListTile(
                              index: index,
                              isCurrentUser: item.userID == currentUserID,
                              message: item,
                              msgListProvider: msglist,
                              onDismissed: (direction) async {
                                if (await msglist.deleteMesage(item.ID)) {
                                  msglist.deleteItem(item.ID);
                                }
                              },
                            ));
                      },
                    ),
                  ),
                  EditMessageBox(
                    msglist: msglist,
                  ),
                ],
              ));
        }
      },
    );
  }
}
