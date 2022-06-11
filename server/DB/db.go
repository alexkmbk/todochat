package DB

import (
	"crypto/sha256"
	"encoding/hex"

	"github.com/google/uuid"
	log "github.com/sirupsen/logrus"

	//"gorm.io/driver/sqlite"

	"gorm.io/gorm"
)

//+var db, _ = gorm.Open("mysql", "root:root@/todolist?charset=utf8&parseTime=True&loc=Local")
//var dsn = "host=localhost user=postgres password=123 dbname=todolist port=5432 sslmode=disable TimeZone=Asia/Shanghai"
var DB *gorm.DB

func DropUnusedColumns(dst interface{}) {

	stmt := &gorm.Statement{DB: DB}
	stmt.Parse(dst)
	fields := stmt.Schema.Fields
	columns, _ := DB.Debug().Migrator().ColumnTypes(dst)

	for i := range columns {
		found := false
		for j := range fields {
			if columns[i].Name() == fields[j].DBName {
				found = true
				break
			}
		}
		if !found {
			DB.Migrator().DropColumn(dst, columns[i].Name())
		}
	}
}

func InitDB() {

	InitDB_SQLite()

	SQLDB, _ := DB.DB()
	SQLDB.SetMaxIdleConns(10)
	SQLDB.SetMaxOpenConns(100)

	DB.AutoMigrate(&User{})
	DropUnusedColumns(&User{})
	DB.AutoMigrate(&Project{})
	DropUnusedColumns(&Project{})
	DB.AutoMigrate(&Task{})
	DropUnusedColumns(&Task{})
	DB.AutoMigrate(&Message{})
	DropUnusedColumns(&Message{})
	DB.AutoMigrate(&SeenMessage{})
	DropUnusedColumns(&SeenMessage{})
	DB.AutoMigrate(&SeenTask{})
	DropUnusedColumns(&SeenTask{})

	InitFTS_SQLite()

	var count int64
	DB.Model(&Project{}).Count(&count)
	if count == 0 {
		var project Project
		project.Description = "Default project"
		DB.Create(&project)
	}

	DB.Model(&User{}).Count(&count)
	if count == 0 {
		var user User
		hash := sha256.Sum256([]byte(""))
		user.PasswordHash = hex.EncodeToString(hash[:])
		user.Name = "admin"
		DB.Create(&user)
	}

	// Sessions
	sessionDB.AutoMigrate(&Session{})

}

func GetMessagesDB(SessionID uuid.UUID, lastID int64, limit int64, taskID int64, filter string, messageIDPosition int64) []*Message {

	//	start := time.Now()
	log.Info("Get Messages")

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
