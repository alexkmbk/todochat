package handlers

import (
	"bufio"
	"encoding/json"
	"fmt"
	_ "image/png"
	"io"
	"io/ioutil"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	//"github.com/gorilla/mux"

	WS "todochat_server/WebSocked"
	. "todochat_server/models"
	"todochat_server/service"
	"todochat_server/utils"
)

func GetMessage(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	message, err := service.GetMessageByID(id)

	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
	} else {

		// return message as json
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(message)
	}
}

func GetMessages(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	start := time.Now()
	utils.Log("Get Messages")

	lastID := utils.ToInt64(r.Header.Get("lastID"))

	/*offset, err := strconv.Atoi(r.Header.Get("offset"))
	if err != nil {
		offset = 0
	}*/

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		return
	}

	taskID := utils.ToInt64(r.Header.Get("taskID"))

	// var messages []*Message
	// //DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	// if lastID == 0 {
	// 	DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	// } else {
	// 	DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	// }

	// if userID != 0 {
	// 	for i := range messages {
	// 		seenMessage := SeenMessage{UserID: userID, TaskID: taskID, MessageID: messages[i].ID}
	// 		found := DB.Find(&seenMessage)
	// 		if found.RowsAffected == 0 {
	// 			DB.Create(&seenMessage)
	// 		}
	// 	}

	// 	seenTask := SeenTask{UserID: userID, TaskID: taskID}

	// 	if DB.Find(&seenTask).RowsAffected == 0 { // not found
	// 		DB.Create(&seenTask)
	// 	}
	// }

	messages := service.GetMessages(userID, taskID, lastID, limit)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	// for i := range messages {
	// 	data, err_read := os.ReadFile(filepath.Join(FileStoragePath, messages[i].SmallImageName))
	// 	if err_read == nil {
	// 		messages[i].PreviewSmallImageBase64 = ToBase64(data)
	// 	}

	// }

	pw := bufio.NewWriterSize(w, 100000) // Bigger writer of 10kb
	utils.Log(fmt.Sprintln("Buffer size", pw.Size()))

	res, _ := json.Marshal(messages)
	pw.Write(res)
	//_, err := io.WriteString(pw, )

	if err != nil {
		fmt.Println(err)
	}

	if pw.Buffered() > 0 {
		utils.Log(fmt.Sprintln("Bufferred", pw.Buffered()))
		pw.Flush() // Important step read my note following this code snippet
	}

	length := strconv.Itoa(len(res))
	w.Header().Set("Content-Length", length)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	//json.NewEncoder(w).Encode(messages)
	//log.Info("Get Messages - finish")
	elapsed := time.Since(start)
	utils.Log(fmt.Sprintf("Get messages took %s", elapsed.Seconds()))

}

func CreateMessage(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	decoder := json.NewDecoder(r.Body)
	var message Message

	err := decoder.Decode(&message)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
		return
	}

	service.CreateMessage(userID, &message, false)

	// user, success := GetUserByID(userID)
	// if success {
	// 	message.UserName = user.Name
	// }

	// message.Created_at = time.Now()
	// message.UserID = userID

	// /*message.LocalFileName = fileName
	// message.SmallImageName = smallImageFileName
	// message.FileSize = fileSize*/

	// task, success := getTaskByID(message.TaskID)
	// if success {
	// 	task.LastMessage = message.Text
	// 	if len(task.LastMessage) == 0 {
	// 		task.LastMessage = message.FileName
	// 	}
	// 	task.LastMessageID = message.ID
	// 	task.LastMessageUserName = message.UserName

	// 	switch message.MessageAction {
	// 	case CompleteTaskAction:
	// 		task.Completed = true
	// 		task.InHand = false
	// 	case ReopenTaskAction:
	// 		task.Completed = false
	// 		task.Cancelled = false
	// 		task.Closed = false

	// 	case CloseTaskAction:
	// 		task.Closed = true
	// 		task.Completed = true
	// 		task.Cancelled = false
	// 		task.InHand = false
	// 	case CancelTaskAction:
	// 		task.Completed = false
	// 		task.Cancelled = true
	// 		task.InHand = false
	// 	case RemoveCompletedLabelAction:
	// 		task.Completed = false
	// 	case InHand:
	// 		task.InHand = true
	// 		task.Completed = false
	// 	case RemoveInHand:
	// 		task.InHand = false
	// 	}

	// 	DB.Save(&task)
	// }
	// message.ProjectID = task.ProjectID
	// DB.Create(&message)

	// if userID != 0 {
	// 	seenMessage := SeenMessage{UserID: userID, TaskID: task.ID, MessageID: message.ID}
	// 	if DB.Find(&seenMessage).RowsAffected == 0 {
	// 		DB.Create(&seenMessage)
	// 	}

	// 	seenTask := SeenTask{UserID: userID, TaskID: task.ID}

	// 	if DB.Find(&seenTask).RowsAffected == 0 { // not found
	// 		DB.Create(&seenTask)
	// 	}
	// }

	go WS.SendWSMessage(&message)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(message)

}

func UpdateMessage(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	decoder := json.NewDecoder(r.Body)
	var message Message

	err := decoder.Decode(&message)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
		return
	}

	service.UpdateMessage(userID, &message)

	// task, _ := getTaskByID(message.TaskID)

	// message.ProjectID = task.ProjectID
	// DB.Updates(&message)

	go WS.SendWSUpdateMessage(&message)
}

func CreateMessageWithFile(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	read_form, err := r.MultipartReader()

	if err != nil {
		return
	}

	var message Message
	var fileName string
	var smallImageFileName string
	var fileData []byte
	var smallImageData []byte
	var fileSize int64

	for {
		part, err_part := read_form.NextPart()
		if err_part == io.EOF {
			break
		}
		if part.FormName() == "File" {
			ext := filepath.Ext(part.FileName())

			fileData, _ = ioutil.ReadAll(part)

			fileSize = int64(len(fileData))

			fileData, ext := utils.OptimizeImageSize(fileData, ext)

			fileName = uuid.New().String() + ext
			err = service.WriteFile(fileName, fileData)
			if err != nil {
				fileName = ""
			}

			if message.IsImage {

				smallImageData, err, message.SmallImageHeight, message.SmallImageWidth = utils.ResizeImageByHeight(fileData, 200)

				if err != nil {
					message.SmallImageHeight = 200
					message.SmallImageWidth = 0
					smallImageData = fileData
				}
				smallImageFileName = uuid.New().String() + ".jpg"
				err = service.WriteFile(smallImageFileName, smallImageData)
				if err != nil {
					smallImageFileName = ""
					utils.Log("Resize image error: " + err.Error())
				}

				// previewSmallImageData, err, _, _ := ResizeImageByHeight(smallImageData, 30)

				// if err == nil {
				// 	message.PreviewSmallImageBase64 = ToBase64(previewSmallImageData)
				// }

			}
			//buf := new(bytes.Buffer)
			//buf.ReadFrom(part)
			//log.Println("delete is: ", buf.String())
		} else if part.FormName() == "Message" {
			data, _ := ioutil.ReadAll(part)
			jsonDataReader := strings.NewReader(string(data))
			decoder := json.NewDecoder(jsonDataReader)
			err = decoder.Decode(&message)
			if err != nil {
				return
			}
		}
	}
	user, success := service.GetUserByID(userID)
	if success {
		message.UserName = user.Name
	}

	message.LocalFileName = fileName
	message.SmallImageName = smallImageFileName
	message.FileSize = fileSize

	service.CreateMessage(userID, &message, true)
	// foundMessage := &Message{}
	// result := DB.Where("Temp_ID = ?", message.TempID).First(&foundMessage)
	// if result.Error != nil {
	// 	return
	// }
	// message.ID = foundMessage.ID

	// message.LocalFileName = fileName
	// message.SmallImageName = smallImageFileName
	// message.Created_at = time.Now()
	// message.UserID = userID
	// message.FileSize = fileSize

	// task, success := getTaskByID(message.TaskID)
	// if success {
	// 	task.LastMessage = message.Text
	// 	task.LastMessageID = message.ID
	// 	task.LastMessageUserName = message.UserName
	// 	DB.Save(&task)
	// }
	// message.ProjectID = task.ProjectID
	// message.LoadinInProcess = false
	// DB.Save(&message)
	WS.SendWSMessage(&message)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(message)

}

func DeleteMessage(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	message, task, err := service.DeleteMessage(id)
	// message, err := service.GetMessageByID(id)

	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, fmt.Sprintf(`{"deleted": false, "error": "%s"}`, err.Error()))
	} else {
		// utils.Log("Deleting TodoItem")

		// DB.First(&message, id)

		// if message.SmallImageName != "" {
		// 	err := service.RemoveFile(message.SmallImageName)
		// 	if err != nil {
		// 		utils.Log(err)
		// 	}
		// }
		// DB.Delete(&message)
		// var lastMessage Message
		// task, success := getTaskByID(message.TaskID)
		// if success {

		// 	DB.Order("ID desc").Where("task_id = ? AND ID < ?", task.ID, message.ID).First(&lastMessage)
		// 	if lastMessage.ID != 0 {
		// 		task.LastMessage = lastMessage.Text
		// 		task.LastMessageID = lastMessage.ID
		// 		task.LastMessageUserName = lastMessage.UserName

		// 		// Если действие сообщения не является CreateUpdateMessageAction, обновляем статус задачи
		// 		if message.MessageAction != CreateUpdateMessageAction {
		// 			var lastStatusMessage Message
		// 			if lastMessage.MessageAction != CreateUpdateMessageAction {
		// 				lastStatusMessage = lastMessage
		// 			} else {
		// 				DB.Order("ID desc").Where("task_id = ? AND message_action != ? AND ID < ?", task.ID, CreateUpdateMessageAction, lastMessage.ID).First(&lastStatusMessage)
		// 			}
		// 			if lastStatusMessage.ID != 0 {
		// 				task.Cancelled = lastStatusMessage.MessageAction == CancelTaskAction
		// 				task.Closed = lastStatusMessage.MessageAction == CloseTaskAction
		// 				task.Completed = lastStatusMessage.MessageAction == CompleteTaskAction
		// 				task.InHand = lastStatusMessage.MessageAction == InHand
		// 			} else {
		// 				task.Cancelled = false
		// 				task.Closed = false
		// 				task.Completed = false
		// 				task.InHand = false
		// 			}
		// 		}
		// 	} else {
		// 		task.LastMessage = ""
		// 		task.LastMessageID = 0
		// 		task.LastMessageUserName = ""
		// 	}
		// 	DB.Save(&task)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	io.WriteString(w, `{"deleted": true}`)
	go WS.SendDeleteMessage(message, task)
}
