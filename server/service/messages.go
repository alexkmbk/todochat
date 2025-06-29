package service

import (
	_ "image/png"
	"os"
	"path/filepath"
	"time"

	//"github.com/gorilla/mux"

	. "todochat_server/db"
	. "todochat_server/models"
	"todochat_server/utils"

	"github.com/google/uuid"
)

// Get unread messages by projects
func GetUnreadMessagesByProjects() []map[int64]int64 {
	// getting count of unread messages by projects
	var data []map[int64]int64
	DB.Table("messages").Select("messages.project_id, COUNT(messages.id) as count").Where("messages.seen = false").Group("messages.project_id").Scan(&data)

	return data
}

func GetMessages(userID int64, taskID int64, lastID int64, limit int) []*Message {

	var messages []*Message
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	}

	for i := range messages {
		seenMessage := SeenMessage{UserID: userID, TaskID: taskID, MessageID: messages[i].ID}
		found := DB.Find(&seenMessage)
		if found.RowsAffected == 0 {
			DB.Create(&seenMessage)
		}
	}

	seenTask := SeenTask{UserID: userID, TaskID: taskID}

	if DB.Find(&seenTask).RowsAffected == 0 { // not found
		DB.Create(&seenTask)
	}

	return messages
}

func GetMessagesDB(SessionID uuid.UUID, lastID int64, limit int64, taskID int64, filter string, messageIDPosition int64) []*Message {

	//	start := time.Now()
	utils.Log("Get Messages")

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		if messageIDPosition > 0 {
			var addMessages []*Message
			DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Find(&addMessages)
			DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, messageIDPosition).Limit(int(limit)).Find(&messages)
			messages = append(addMessages, messages...)
			/*DB.Raw("? UNION ?",
				DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Model(&Message{}),
				DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Model(&Message{}),
			).Scan(&messages)*/
		} else {
			DB.Order("ID desc").Where("task_id = ?", taskID).Limit(int(limit)).Find(&messages)
		}
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(int(limit)).Find(&messages)
	}

	UserID := GetUserIDBySessionID(SessionID)
	if UserID != 0 {
		for i := range messages {
			seenMessage := SeenMessage{UserID: UserID, TaskID: taskID, MessageID: messages[i].ID}
			if DB.Find(&seenMessage).RowsAffected == 0 {
				DB.Create(&seenMessage)
			}
		}

		seenTask := SeenTask{UserID: UserID, TaskID: taskID}

		if DB.Find(&seenTask).RowsAffected == 0 { // not found
			DB.Create(&seenTask)
		}
	}

	/*res, err := json.Marshal(messages)

	if err != nil {
		res = []byte{}
	}*/
	//elapsed := time.Since(start)
	//log.Printf("Get messages took %s", elapsed.Seconds())

	return messages
}

func CreateMessage(userID int64, message *Message) {

	if message.TempID != "" {
		foundMessage := &Message{}
		result := DB.Where("Temp_ID = ?", message.TempID).First(&foundMessage)
		if result.Error != nil {
			return
		}
		message.ID = foundMessage.ID
	}

	user, success := GetUserByID(userID)
	if success {
		message.UserName = user.Name
	}

	message.Created_at = time.Now()
	message.UserID = userID

	task, err := GetTaskByID(message.TaskID)
	if err == nil {
		task.LastMessage = message.Text
		if len(task.LastMessage) == 0 {
			task.LastMessage = message.FileName
		}
		task.LastMessageID = message.ID
		task.LastMessageUserName = message.UserName

		switch message.MessageAction {
		case CompleteTaskAction:
			task.Completed = true
			task.InHand = false
		case ReopenTaskAction:
			task.Completed = false
			task.Cancelled = false
			task.Closed = false

		case CloseTaskAction:
			task.Closed = true
			task.Completed = true
			task.Cancelled = false
			task.InHand = false
		case CancelTaskAction:
			task.Completed = false
			task.Cancelled = true
			task.InHand = false
		case RemoveCompletedLabelAction:
			task.Completed = false
		case InHand:
			task.InHand = true
			task.Completed = false
		case RemoveInHand:
			task.InHand = false
		}

		DB.Save(&task)
	}
	message.ProjectID = task.ProjectID
	if message.ID == 0 {
		DB.Create(&message)
	} else {
		DB.Save(&message)
	}

	if userID != 0 {
		seenMessage := SeenMessage{UserID: userID, TaskID: task.ID, MessageID: message.ID}
		if DB.Find(&seenMessage).RowsAffected == 0 {
			DB.Create(&seenMessage)
		}

		seenTask := SeenTask{UserID: userID, TaskID: task.ID}

		if DB.Find(&seenTask).RowsAffected == 0 { // not found
			DB.Create(&seenTask)
		}
	}
}

func UpdateMessage(userID int64, message *Message) {

	task, _ := GetTaskByID(message.TaskID)

	message.ProjectID = task.ProjectID
	DB.Updates(&message)

}

func GetMessageByID(ID int64) (*Message, error) {
	message := &Message{}
	result := DB.First(&message, ID)
	if result.Error != nil {
		utils.Log_warn("Message not found in database")
		return message, result.Error
	}
	return message, result.Error
}

func DeleteMessage(id int64) (*Message, *Task, error) {

	message, err := GetMessageByID(id)

	if err != nil {
		return message, nil, err
	}

	utils.Log("Deleting TodoItem")

	DB.First(&message, id)

	if message.SmallImageName != "" {
		err := os.Remove(filepath.Join(FileStoragePath, message.SmallImageName))
		if err != nil {
			utils.Log(err)
		}
	}
	DB.Delete(&message)
	var lastMessage Message
	task, err := GetTaskByID(message.TaskID)
	if err == nil {

		DB.Order("ID desc").Where("task_id = ? AND ID < ?", task.ID, message.ID).First(&lastMessage)
		if lastMessage.ID != 0 {
			task.LastMessage = lastMessage.Text
			task.LastMessageID = lastMessage.ID
			task.LastMessageUserName = lastMessage.UserName

			// Если действие сообщения не является CreateUpdateMessageAction, обновляем статус задачи
			if message.MessageAction != CreateUpdateMessageAction {
				var lastStatusMessage Message
				if lastMessage.MessageAction != CreateUpdateMessageAction {
					lastStatusMessage = lastMessage
				} else {
					DB.Order("ID desc").Where("task_id = ? AND message_action != ? AND ID < ?", task.ID, CreateUpdateMessageAction, lastMessage.ID).First(&lastStatusMessage)
				}
				if lastStatusMessage.ID != 0 {
					task.Cancelled = lastStatusMessage.MessageAction == CancelTaskAction
					task.Closed = lastStatusMessage.MessageAction == CloseTaskAction
					task.Completed = lastStatusMessage.MessageAction == CompleteTaskAction
					task.InHand = lastStatusMessage.MessageAction == InHand
				} else {
					task.Cancelled = false
					task.Closed = false
					task.Completed = false
					task.InHand = false
				}
			}
		} else {
			task.LastMessage = ""
			task.LastMessageID = 0
			task.LastMessageUserName = ""
		}
		DB.Save(&task)
	}

	return message, task, nil
}
