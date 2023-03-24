package Messages

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	_ "image/png"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	//"github.com/gorilla/mux"

	. "todochat_server/App"

	. "todochat_server/DB"
	WS "todochat_server/constrollers/WebSocked"

	Tasks "todochat_server/constrollers/Tasks"
	Users "todochat_server/constrollers/Users"
)

func GetFile(w http.ResponseWriter, r *http.Request) {

	query := r.URL.Query()
	fileName := query.Get("localFileName")

	if fileName == "" {
		return
	}

	data, err := os.ReadFile(filepath.Join(FileStoragePath, fileName))
	if err != nil {
		return
	}

	b := bytes.NewBuffer(data)

	w.Header().Set("Content-Type", "application/octet-stream")
	_, err = b.WriteTo(w)
	//w.Write(data)
	//	json.NewEncoder(w).Encode(ToBase64(data))
}

func GetMessages__(w http.ResponseWriter, r *http.Request) {

	start := time.Now()

	Log("Get Messages")

	lastID, err := strconv.Atoi(r.Header.Get("lastID"))
	if err != nil {
		return
	}

	/*offset, err := strconv.Atoi(r.Header.Get("offset"))
	if err != nil {
		offset = 0
	}*/

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		return
	}

	taskID, err := strconv.Atoi(r.Header.Get("taskID"))
	if err != nil {
		return
	}

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	}

	//	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	/*mediatype, _, err := mime.ParseMediaType(r.Header.Get("Accept"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotAcceptable)
		return
	}
	if mediatype != "multipart/form-data" {
		http.Error(w, "set Accept: multipart/form-data", http.StatusMultipleChoices)
		return
	}*/
	mw := multipart.NewWriter(w)
	w.Header().Set("Content-Type", mw.FormDataContentType())

	for _, message := range messages {

		data, err_read := os.ReadFile(filepath.Join(FileStoragePath, message.SmallImageName))
		if err_read == nil {
			fw, err := mw.CreateFormFile("SmallImageData", message.FileName+".jpg")
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			if _, err := fw.Write(data); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
		}
		_, err_field := mw.CreateFormField("Message")
		if err_field != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json, _ := json.Marshal(message)
		if err := mw.WriteField("Message", string(json)); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

	}

	if err := mw.Close(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	//json.NewEncoder(w).Encode(messages)
	//log.Info("Get Messages - finish")
	elapsed := time.Since(start)
	Log(fmt.Sprintf("Get messages took %s", elapsed))
}

func GetMessages(w http.ResponseWriter, r *http.Request) {

	start := time.Now()
	Log("Get Messages")

	lastID, err := strconv.Atoi(r.Header.Get("lastID"))
	if err != nil {
		return
	}

	/*offset, err := strconv.Atoi(r.Header.Get("offset"))
	if err != nil {
		offset = 0
	}*/

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		return
	}

	taskID, err := strconv.Atoi(r.Header.Get("taskID"))
	if err != nil {
		return
	}

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	for i := range messages {
		data, err_read := os.ReadFile(filepath.Join(FileStoragePath, messages[i].SmallImageName))
		if err_read == nil {
			messages[i].PreviewSmallImageBase64 = ToBase64(data)
		}

	}

	pw := bufio.NewWriterSize(w, 100000) // Bigger writer of 10kb
	Log(fmt.Sprintln("Buffer size", pw.Size()))

	res, _ := json.Marshal(messages)
	pw.Write(res)
	//_, err := io.WriteString(pw, )

	if err != nil {
		fmt.Println(err)
	}

	if pw.Buffered() > 0 {
		Log(fmt.Sprintln("Bufferred", pw.Buffered()))
		pw.Flush() // Important step read my note following this code snippet
	}

	length := strconv.Itoa(len(res))
	w.Header().Set("Content-Length", length)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	//json.NewEncoder(w).Encode(messages)
	//log.Info("Get Messages - finish")
	elapsed := time.Since(start)
	Log(fmt.Sprintf("Get messages took %s", elapsed.Seconds()))

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

	user, success := Users.GetItemByID(userID)
	if success {
		message.UserName = user.Name
	}

	message.Created_at = time.Now()
	message.UserID = userID

	/*message.LocalFileName = fileName
	message.SmallImageName = smallImageFileName
	message.FileSize = fileSize*/

	task, success := Tasks.GetItemByID(message.TaskID)
	if success {
		task.LastMessage = message.Text
		if len(task.LastMessage) == 0 {
			task.LastMessage = message.FileName
		}
		task.LastMessageID = message.ID
		task.LastMessageUserName = message.UserName

		switch message.MessageAction {
		case CompleteTaskAction:
			task.Completed = true
			break
		case ReopenTaskAction:
			task.Completed = false
			task.Cancelled = false
			task.Closed = false
			break

		case CloseTaskAction:
			task.Closed = true
			task.Completed = true
			task.Cancelled = false
			break
		case CancelTaskAction:
			task.Completed = false
			task.Cancelled = true
			break
		case RemoveCompletedLabelAction:
			task.Completed = false
		}

		DB.Save(&task)
	}
	message.ProjectID = task.ProjectID
	DB.Create(&message)
	go WS.SendWSMessage(&message)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(message)

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

			fileData, ext := OptimizeImageSize(fileData, ext)

			fileName = uuid.New().String() + ext
			err = os.WriteFile(filepath.Join(FileStoragePath, fileName), fileData, 0644)
			if err != nil {
				fileName = ""
			}

			if message.IsImage {

				smallImageData, err, message.SmallImageHeight, message.SmallImageWidth = ResizeImageByHeight(fileData, 200)

				if err != nil {
					message.SmallImageHeight = 200
					message.SmallImageWidth = 0
					smallImageData = fileData
				}
				smallImageFileName = uuid.New().String() + ".jpg"
				err = os.WriteFile(filepath.Join(FileStoragePath, smallImageFileName), smallImageData, 0644)
				Log("File Saved: " + filepath.Join(FileStoragePath, smallImageFileName))
				if err != nil {
					smallImageFileName = ""
					Log("Resize image error: " + err.Error())
				}

				previewSmallImageData, err, _, _ := ResizeImageByHeight(smallImageData, 30)

				if err == nil {
					message.PreviewSmallImageBase64 = ToBase64(previewSmallImageData)
				}

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
	user, success := Users.GetItemByID(userID)
	if success {
		message.UserName = user.Name
	}

	foundMessage := &Message{}
	result := DB.Where("Temp_ID = ?", message.TempID).First(&foundMessage)
	if result.Error != nil {
		return
	}
	message.ID = foundMessage.ID

	message.LocalFileName = fileName
	message.SmallImageName = smallImageFileName
	message.Created_at = time.Now()
	message.UserID = userID
	message.FileSize = fileSize

	task, success := Tasks.GetItemByID(message.TaskID)
	if success {
		task.LastMessage = message.Text
		task.LastMessageID = message.ID
		task.LastMessageUserName = message.UserName
		DB.Save(&task)
	}
	message.ProjectID = task.ProjectID
	message.LoadinInProcess = false
	DB.Save(&message)
	WS.SendWSMessage(&message)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(message)

}

func getItemByID(ID int64) (*Message, bool) {
	message := &Message{}
	result := DB.First(&message, ID)
	if result.Error != nil {
		Log_warn("Message not found in database")
		return message, false
	}
	return message, true
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := ToInt64(vars["id"])

	message, err := getItemByID(id)

	if err == false {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		Log("Deleting TodoItem")

		DB.First(&message, id)

		if message.SmallImageName != "" {
			err := os.Remove(filepath.Join(FileStoragePath, message.SmallImageName))
			if err != nil {
				Log(err)
			}
		}
		DB.Delete(&message)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
		go WS.SendDeleteMessage(message)
	}
}
