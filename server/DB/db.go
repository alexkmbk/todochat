package DB

import (
	"os"
	"path/filepath"
	"time"

	log "github.com/sirupsen/logrus"

	. "todochat_server/App"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

//+var db, _ = gorm.Open("mysql", "root:root@/todolist?charset=utf8&parseTime=True&loc=Local")
//var dsn = "host=localhost user=postgres password=123 dbname=todolist port=5432 sslmode=disable TimeZone=Asia/Shanghai"
var DB *gorm.DB

func InitDB() {

	var err error
	DBPAth := filepath.Join(GetCurrentDir(), "gorm.db")
	DB, err = gorm.Open(sqlite.Open(DBPAth), &gorm.Config{})
	if err != nil {
		log.Println(err)
		return
	}
	//defer db.Close()

	//db.DropTableIfExist = //.DropTableIfExist(&TodoItemModel{})

	//db.Migrator().DropTable(&User{})

	DB.AutoMigrate(&User{})
	DB.AutoMigrate(&Project{})
	DB.AutoMigrate(&Task{})
	DB.AutoMigrate(&Message{})

	/*var tasks []Task
	DB.Find(&tasks)

	for i := range tasks {
		tasks[i].ProjectID = 2
	}

	DB.Save(&tasks)*/
	// Sessions
	sessionDB.AutoMigrate(&Session{})

	/*var message Message
	message.ID = 4
	message.TaskID = 34
	message.Text = "Hi"
	db.Create(&message)*/
	//DB.Migrator().DropColumn(&Message{}, "picture_data_base64")
	/*db.Migrator().DropColumn(&Message{}, "deleted_at")
	db.Migrator().AddColumn(&Message{}, "field2")*/

}

func GetMessagesDB(lastID int64, limit int64, taskID int64) []*Message {

	start := time.Now()
	log.Info("Get Messages")

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(int(limit)).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(int(limit)).Find(&messages)
	}

	for i := range messages {
		data, err_read := os.ReadFile(filepath.Join(FileStoragePath, messages[i].SmallImageLocalPath))
		if err_read == nil {
			messages[i].SmallImageBase64 = ToBase64(data)
		}

	}
	/*res, err := json.Marshal(messages)

	if err != nil {
		res = []byte{}
	}*/
	elapsed := time.Since(start)
	log.Printf("Get messages took %s", elapsed.Seconds())

	return messages
}
