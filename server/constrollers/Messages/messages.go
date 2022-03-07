package Messages

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	//"github.com/gorilla/mux"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	. "todochat_server/App"
	. "todochat_server/DB"
	WS "todochat_server/constrollers/WebSocked"
)

func GetMessages(w http.ResponseWriter, r *http.Request) {

	log.Info("Get Messages")

	if !CheckSessionID(w, r) {
		return
	}

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

	var messages []Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	for i := range messages {
		data, err_read := os.ReadFile(filepath.Join(FileStoragePath, messages[i].SmallImageLocalPath))
		if err_read == nil {
			messages[i].SmallImageBase64 = ToBase64(data)
		}

	}
	json.NewEncoder(w).Encode(messages)
}

/*func CreateMessage(w http.ResponseWriter, r *http.Request) {
	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}
	decoder := json.NewDecoder(r.Body)
	var message Message

	err := decoder.Decode(&message)
	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"error": "Record Not Found"}`)
	} else {
		text := message.Text
		log.WithFields(log.Fields{"text": text}).Info("Add new Message. Saving to database.")
		//message := &Message{Description: description, Completed: false, Creation_date: time.Now()}
		message.Created_at = time.Now()
		message.UserID = userID
		if message.Image != "" {
			fileData, err := FromBase64(message.Image)
			if err != nil {
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				io.WriteString(w, `{"error": "Image parse error"}`)
				return
			}
			imageFileName := uuid.New().String() + ".jpg"

			err = os.WriteFile(imageFileName, fileData, 0644)
			if err != nil {
				// handle error
			}
		}
		message.PictureLocalPath = ""
		DB.Create(&message)
		//DB.Last(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		//io.WriteString(w, `{result: true}`)
		json.NewEncoder(w).Encode(message)
		WS.SendWSMessage(message)
	}
}*/

func CreateMessage(w http.ResponseWriter, r *http.Request) {
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

	for {
		part, err_part := read_form.NextPart()
		if err_part == io.EOF {
			break
		}
		if part.FormName() == "File" {
			ext := filepath.Ext(part.FileName())
			fileData, _ = ioutil.ReadAll(part)
			fileName = uuid.New().String() + ext

			err = os.WriteFile(filepath.Join(FileStoragePath, fileName), fileData, 0644)
			if err != nil {
				fileName = ""
			}

			if message.IsImage {
				smallImageData, err = ResizeImageByHeight(fileData, 200)

				if err == nil {
					smallImageFileName = uuid.New().String() + ext
					err = os.WriteFile(filepath.Join(FileStoragePath, smallImageFileName), smallImageData, 0644)
					if err != nil {
						smallImageFileName = ""
					}
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

	message.FileLocalPath = fileName
	message.SmallImageLocalPath = smallImageFileName
	message.Created_at = time.Now()
	message.UserID = userID

	if smallImageFileName != "" {
		message.SmallImageBase64 = ToBase64(smallImageData)
	}

	DB.Create(&message)
	WS.SendWSMessage(&message)

	/*fmt.Println(r.FormValue("delete"))
	decoder := json.NewDecoder(r.Body)
	var message Message

	err = decoder.Decode(&message)
	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"error": "Record Not Found"}`)
	} else {
		text := message.Text
		log.WithFields(log.Fields{"text": text}).Info("Add new Message. Saving to database.")
		//message := &Message{Description: description, Completed: false, Creation_date: time.Now()}
		message.Created_at = time.Now()
		message.UserID = userID
		if message.Image != "" {
			fileData, err := FromBase64(message.Image)
			if err != nil {
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				io.WriteString(w, `{"error": "Image parse error"}`)
				return
			}
			imageFileName := uuid.New().String() + ".jpg"

			err = os.WriteFile(imageFileName, fileData, 0644)
			if err != nil {
				// handle error
			}
		}
		message.PictureLocalPath = ""
		DB.Create(&message)
		//DB.Last(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		//io.WriteString(w, `{result: true}`)
		json.NewEncoder(w).Encode(message)
		WS.SendWSMessage(message)
	}*/
}

func getItemByID(ID int) (*Message, bool) {
	message := &Message{}
	result := DB.First(&message, ID)
	if result.Error != nil {
		log.Warn("Message not found in database")
		return message, false
	}
	return message, true
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	if !CheckSessionID(w, r) {
		return
	}

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	message, err := getItemByID(id)

	if err == false {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"ID": id}).Info("Deleting TodoItem")

		DB.First(&message, id)
		DB.Delete(&message)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}
