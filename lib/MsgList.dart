//import 'dart:ffi';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';

import 'TasksPage.dart';
import 'main.dart';

class MsgListProvider extends ChangeNotifier {
  List<Message> items = [];
  num offset = 0;
  int lastID = 0;
  bool loading = false;

  void clear() {
    items.clear();
    offset = 0;
    lastID = 0;
  }

  void addItem(Message message) {
    offset++;
    //lastID = message.ID;
    items.insert(0, message);
    notifyListeners();
  }

  void deleteItem(int messageID) async {
    offset--;
    if (offset < 0) offset = 0;
    items.removeWhere((item) => item.ID == messageID);
    notifyListeners();
  }
}

class Message {
  int ID = 0;
  int taskID = 0;
  Task? task;
  DateTime? created_at;
  String text = "";
  int userID = 0;
  Message(
      {required this.task,
      this.text = "",
      this.created_at,
      this.ID = 0,
      this.userID = 0});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'taskID': task?.ID,
      'created_at': created_at,
      'text': text,
      'userID': userID
    };
  }

  Message.fromJson(Map<String, dynamic> json)
      : ID = json['ID'],
        //task = json['task'],
        created_at = DateTime.tryParse(json['Created_at']),
        text = json['Text'],
        taskID = json['TaskID'],
        userID = json['UserID'];
}

typedef Future<bool> OnDeleteFn(int messageID);

class InifiniteMsgList extends StatefulWidget {
  final ScrollController scrollController;
  final Future<bool> Function(int messageID) onDelete;
  //final ItemBuilder itemBuilder;
  //final Task task;
  const InifiniteMsgList(
      {Key? key, required this.scrollController, required this.onDelete})
      : super(key: key);

  @override
  InifiniteMsgListState createState() {
    InifiniteMsgListState state = InifiniteMsgListState();
    return state;
  }
}

class InifiniteMsgListState extends State<InifiniteMsgList> {
  late MsgListProvider _msgListProvider;

  @override
  void initState() {
    super.initState();

    _msgListProvider = Provider.of<MsgListProvider>(context, listen: false);

    //getMoreItems();
    /*WidgetsBinding.instance?.addPostFrameCallback((_) {
      getMoreItems();
    });*/

/*    _scrollController.addListener(() {
      if (!_msgListProvider.loading &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent) getMoreItems();
    });*/
  }

/*  InifiniteListState() {
    _controller.addListener(() {
      _getMoreItems();
    });
  }*/

  /*final ScrollController _scrollController = ScrollController();
// This is what you're looking for!
  void _scrollDown() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }*/

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: <Widget>[
      Expanded(
          child: ListView.builder(
        reverse: true,
        controller: widget.scrollController,
        itemBuilder: (context, index) {
          //if (index < _msgListProvider.items.length) {
          var item = _msgListProvider.items[index];
          return ChatBubble(
            isCurrentUser: item.userID == currentUserID,
            text: item.text,
            onDismissed: (direction) async {
              if (await widget.onDelete(item.ID)) {
                _msgListProvider.deleteItem(item.ID);
              }
            },
          );
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
        },
        itemCount: _msgListProvider.items.length,
      )),
    ]));
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.text,
    required this.isCurrentUser,
    required this.onDismissed,
  }) : super(key: key);
  final String text;
  final bool isCurrentUser;
  final DismissDirectionCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) {
          return confirmDimissDlg(
              "Are you sure you wish to delete this item?", context);
        },
        onDismissed: onDismissed,
        child: Padding(
          // asymmetric padding
          padding: EdgeInsets.fromLTRB(
            isCurrentUser ? 64.0 : 16.0,
            4,
            isCurrentUser ? 16.0 : 64.0,
            4,
          ),
          child: Align(
            // align the child within the container
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: DecoratedBox(
              // chat bubble decoration
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: isCurrentUser ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ),
        ));
  }
}
