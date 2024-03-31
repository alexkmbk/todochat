package DB

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"

	. "todochat_server/App"

	//"gorm.io/driver/sqlite"

	"gorm.io/gorm"
)

// +var db, _ = gorm.Open("mysql", "root:root@/todolist?charset=utf8&parseTime=True&loc=Local")
// var dsn = "host=localhost user=postgres password=123 dbname=todolist port=5432 sslmode=disable TimeZone=Asia/Shanghai"
var DB *gorm.DB
var DBMS string

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

func AutoMigrate() {
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

}
func InitDB(DBMS string, DBUserName string, DBPassword string, DBName string, DBHost string, DBPort string, TimeZone string) {

	if DBMS == "SQLite" {
		if !InitDB_SQLite() {
			return
		}
	} else if DBMS == "PostgreSQL" {
		if !InitDB_Postges(DBMS, DBUserName, DBPassword, DBName, DBHost, DBPort, TimeZone) {
			return
		}
	} else {
		Log(fmt.Sprintf("DBMS \"" + DBMS + "\" is not supported."))
		return
	}

	SQLDB, _ := DB.DB()
	SQLDB.SetMaxIdleConns(10)
	SQLDB.SetMaxOpenConns(100)

	AutoMigrate()

	if DBMS == "SQLite" {
		InitFTS_SQLite()
	}

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
	DB.AutoMigrate(&Session{})

}
