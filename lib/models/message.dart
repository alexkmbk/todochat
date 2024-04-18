import 'package:todochat/models/task.dart';

enum MessageAction {
  CreateUpdateMessageAction,
  CompleteTaskAction,
  ReopenTaskAction,
  CloseTaskAction,
  CancelTaskAction,
  RemoveCompletedLabelAction,
}

class Message {
  int ID = 0;
  int taskID = 0;
  int projectID = 0;
  Task? task;
  DateTime? created_at;
  String text = "";
  String? quotedText = "";
  int parentMessageID = 0;
  int userID = 0;
  String userName = "";
  String fileName = "";
  int fileSize = 0;
  String localFileName = "";
  String parentsmallImageName = "";
  String smallImageName = "";
  bool isImage = false;
  //Uint8List? previewSmallImageData;
  int smallImageWidth = 0;
  int smallImageHeight = 0;
  bool isTaskDescriptionItem = false;
  bool loadingFile = false;
  //Uint8List? loadingFileData;
  bool loadinInProcess = false;
  String tempID = "";
  bool editMode = false;
  //bool isSelected = false;

  MessageAction messageAction = MessageAction.CreateUpdateMessageAction;
  Message(
      {required this.taskID,
      this.text = "",
      this.quotedText = "",
      this.parentMessageID = 0,
      this.parentsmallImageName = "",
      this.created_at,
      this.ID = 0,
      this.userID = 0,
      this.smallImageName = "",
      this.localFileName = "",
      this.fileName = "",
      this.isImage = false,
      this.isTaskDescriptionItem = false,
      this.loadingFile = false,
      //this.loadingFileData,
      this.tempID = "",
      this.loadinInProcess = false,
      this.messageAction = MessageAction.CreateUpdateMessageAction});

  Map<String, dynamic> toJson() {
    int messageActionInt = 0;
    switch (messageAction) {
      case MessageAction.CreateUpdateMessageAction:
        messageActionInt = 0;
        break;

      case MessageAction.CompleteTaskAction:
        messageActionInt = 1;
        break;

      case MessageAction.ReopenTaskAction:
        messageActionInt = 2;
        break;

      case MessageAction.CloseTaskAction:
        messageActionInt = 3;
        break;

      case MessageAction.CancelTaskAction:
        messageActionInt = 4;
        break;
      case MessageAction.RemoveCompletedLabelAction:
        messageActionInt = 5;
        break;

      default:
    }
    return {
      'ID': ID,
      'taskID': taskID == 0 ? task?.ID : taskID,
      'projectID': projectID,
      'created_at': created_at,
      'text': text,
      'quotedText': quotedText,
      'parentMessageID': parentMessageID,
      'parentsmallImageName': parentsmallImageName,
      'userID': userID,
      'userName': userName,
      'fileName': fileName,
      'fileSize': fileSize,
      'isImage': isImage,
      'smallImageName': smallImageName,
      'localFileName': localFileName,
      'smallImageWidth': smallImageWidth,
      'smallImageHeight': smallImageHeight,
      'isTaskDescriptionItem': isTaskDescriptionItem,
      'TempID': tempID,
      'LoadinInProcess': loadinInProcess,
      'MessageAction': messageActionInt,
    };
  }

  Message.fromJson(Map<String, dynamic> json) {
    ID = json['ID'];
    created_at = DateTime.tryParse(json['Created_at']);
    text = json['Text'];
    quotedText = json['QuotedText'];
    var value = json['ParentMessageID'];
    parentMessageID = value ?? 0;
    parentsmallImageName = json['ParentsmallImageName'] ?? "";
    taskID = json['TaskID'];
    projectID = json['ProjectID'];
    userID = json['UserID'];
    userName = json['UserName'];
    isImage = json['IsImage'];
    fileName = json['FileName'];
    fileSize = json['FileSize'];
    smallImageName = json['SmallImageName'];
    localFileName = json['LocalFileName'];
    smallImageWidth = json['SmallImageWidth'];
    smallImageHeight = json['SmallImageHeight'];
    // var previewSmallImageBase64 = json['PreviewSmallImageBase64'];
    // if (previewSmallImageBase64 != null && previewSmallImageBase64 != "") {
    //   previewSmallImageData = fromBase64(previewSmallImageBase64);
    // }
    value = json['IsTaskDescriptionItem'];
    isTaskDescriptionItem = value ?? false;
    tempID = json["TempID"];
    loadinInProcess = json["LoadinInProcess"];
    int? messageActionIntValue = json["MessageAction"];

    switch (messageActionIntValue) {
      case 0:
        messageAction = MessageAction.CreateUpdateMessageAction;
        break;
      case 1:
        messageAction = MessageAction.CompleteTaskAction;
        break;
      case 2:
        messageAction = MessageAction.ReopenTaskAction;
        break;
      case 3:
        messageAction = MessageAction.CloseTaskAction;
        break;
      case 4:
        messageAction = MessageAction.CancelTaskAction;
        break;

      case 5:
        messageAction = MessageAction.RemoveCompletedLabelAction;
        break;

      default:
        messageAction = MessageAction.CreateUpdateMessageAction;
    }
  }
}
