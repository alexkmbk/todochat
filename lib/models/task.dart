import 'dart:typed_data';

import 'package:todochat/utils.dart';

class Task {
  int ID = 0;
  int projectID = 0;
  int authorID = 0;
  String authorName = "";
  bool completed = false;
  bool cancelled = false;
  bool closed = false;

  String description = "";
  String lastMessage = "";
  int lastMessageID = 0;
  bool editMode = false;
  DateTime creation_date = DateTime.utc(0);
  bool read = false;
  int unreadMessages = 0;
  String lastMessageUserName = "";
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
  Uint8List? previewSmallImageData;

  Task(
      {this.ID = 0,
      this.description = "",
      this.completed = false,
      this.editMode = false});

  Map<String, dynamic> toJson() {
    return {
      'ID': ID,
      'Completed': completed,
      'Cancelled': cancelled,
      'Closed': closed,
      'Description': description,
      'LastMessage': lastMessage,
      'LastMessageID': lastMessageID,
      'ProjectID': projectID,
      'AuthorID': authorID,
      'Creation_date': formDateToJsonUtc(creation_date),
      'AuthorName': authorName,
      'Read': read,
      'UnreadMessages': unreadMessages,
      'LastMessageUserName': lastMessageUserName,
      'FileName': fileName,
      'FileSize': fileSize,
      'LocalFileName': localFileName,
      'previewSmallImageBase64': toBase64(previewSmallImageData),
    };
  }

  Task.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    creation_date = formJsonToDate(json['Creation_date']);
    completed = json['Completed'];
    cancelled = json['Cancelled'];
    closed = json['Closed'];
    description = json['Description'];
    lastMessage = json['LastMessage'];
    lastMessageID = json['LastMessageID'];
    projectID = json['ProjectID'];
    authorID = json['AuthorID'];
    authorName = json['AuthorName'];
    read = json['Read'];
    unreadMessages = json['UnreadMessages'];
    lastMessageUserName = json['LastMessageUserName'];
    /*fileName = json['FileName'];
    fileSize = json['FileSize'];
    localFileName = json['LocalFileName'];

    var previewSmallImageBase64 = json['PreviewSmallImageBase64'];
    if (previewSmallImageBase64 != null && previewSmallImageBase64 != "") {
      previewSmallImageData = fromBase64(previewSmallImageBase64);
    }*/
  }

  Task.from(Task task) {
    ID = task.ID;
    description = task.description;
    creation_date = task.creation_date;
    completed = task.completed;
    cancelled = task.cancelled;
    closed = task.closed;
    lastMessage = task.lastMessage;
    lastMessageID = task.lastMessageID;
    projectID = task.projectID;
    authorID = task.authorID;
    authorName = task.authorName;
    read = task.read;
    unreadMessages = task.unreadMessages;
    lastMessageUserName = task.lastMessageUserName;
    fileName = task.fileName;
    fileSize = task.fileSize;
    localFileName = task.localFileName;
    previewSmallImageData = task.previewSmallImageData;
  }
}
