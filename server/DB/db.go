package DB

import (
	"path/filepath"

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
