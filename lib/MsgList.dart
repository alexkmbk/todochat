import 'package:flutter/material.dart';
//import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

//import 'package:loadmore_listview/loadmore_listview.dart';
//import 'package:loadmore/loadmore.dart';
//import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

import 'package:provider/provider.dart';
import 'package:todochat/tasklist_provider.dart';

import 'package:todochat/todochat.dart';
import 'editMessageBox.dart';
import 'msglist_provider.dart';
import 'msglist_tile.dart';

class MsgList extends StatefulWidget {
  final MsgListProvider msglist;
  final AutoScrollController scrollController;

  const MsgList(
      {Key? key, required this.msglist, required this.scrollController})
      : super(key: key);

  @override
  State<MsgList> createState() {
    return _MsgListState();
  }
}

class _MsgListState extends State<MsgList> {
  final messageTextFieldFocusNode = FocusNode();

  @override
  void initState() {
    // if (!isDesktopMode) {
    //   widget.msglist.requestMessages(
    //       Provider.of<TaskListProvider>(context, listen: false), context);
    // }
    // widget.flutterListViewController.sliverController
    //     .onPaintItemPositionsCallback = (height, positions) {
    //   // height is widget's height
    //   // positions is the items which render in viewports
    //   if (positions.last.index >= widget.msglist.items.length - 5) {
    //     final tasklist = Provider.of<TaskListProvider>(context, listen: false);

    //     widget.msglist.requestMessages(tasklist, context);
    //   }
    // };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final msglist = widget.msglist;
    msglist.scrollController = widget.scrollController;
    if (msglist.task.ID == 0) {
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
            child: InfiniteList(
              scrollController: widget.scrollController,
              reverse: true,
              itemCount: msglist.items.length,
              isLoading: msglist.loading,
              onFetchData: () {
                msglist.requestMessages(
                    Provider.of<TaskListProvider>(context, listen: false),
                    context);
              },
              emptyBuilder: (context) => Text("No any task was selected"),
              itemBuilder: (context, index) {
                var item = msglist.items[index];
                return AutoScrollTag(
                    key: ValueKey(index),
                    controller: widget.scrollController,
                    index: index,
                    child: MsgListTile(
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
                    ));
              },
            ),
          ),
        ),
        EditMessageBox(
          msglist: msglist,
          messageTextFieldFocusNode: messageTextFieldFocusNode,
        ),
      ]);
      // child: FlutterListView(
      //   reverse: true,
      //   controller: widget.flutterListViewController,
      //   delegate: FlutterListViewDelegate(
      //     (BuildContext context, int index) {
      //       if (msglist.items.isEmpty) {
      //         return const Text("No any task was selected");
      //       }
      //       var item = msglist.items[index];
      //       return MsgListTile(
      //         index: index,
      //         isCurrentUser: item.userID == currentUserID,
      //         message: item,
      //         msgListProvider: msglist,
      //         messageTextFieldFocusNode: messageTextFieldFocusNode,
      //         onDismissed: (direction) async {
      //           if (await msglist.deleteMesage(item.ID)) {
      //             msglist.deleteItem(item.ID);
      //           }
      //         },
      //       );
      //     },
      //     childCount: widget.msglist.items.length,
      //   ),
      // ),
      // EditMessageBox(
      //   msglist: msglist,
      //   messageTextFieldFocusNode: messageTextFieldFocusNode,
      // ),
    }
  }
}
