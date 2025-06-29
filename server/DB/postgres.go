package db

import (
	"fmt"
	"time"

	"todochat_server/utils"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func InitDB_Postges(DBMS string, DBUserName string, DBPassword string, DBName string, DBHost string, DBPort string, TimeZone string) bool {

	if DBPort == "" {
		DBPort = "5432" //"9920" //"5432"
	}

	if DBHost == "" {
		DBHost = "localhost"
	}

	if DBName == "" {
		DBName = "todochat"
	}

	if DBUserName == "" {
		DBUserName = "postgres"
	}

	if DBPassword == "" {
		DBPassword = "postgres"
	}

	if TimeZone == "" {

		t := time.Now()
		zone, offset := t.Zone()
		fmt.Println(zone, offset)

		TimeZone = "Etc/Greenwich"
	}
	var err error
	var dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=%s", DBHost, DBUserName, DBPassword, DBName, DBPort, "Asia/Shanghai")

	/*DB, err = gorm.Open(postgres.New(postgres.Config{
		DSN:                  fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=%s", DBHost, DBUserName, DBPassword, DBName, DBPort, "Asia/Shanghai"), // data source name, refer https://github.com/jackc/pgx
		PreferSimpleProtocol: true,                                                                                                                                                      // disables implicit prepared statement usage. By default pgx automatically uses the extended protocol
	}), &gorm.Config{})*/

	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		utils.Log(err.Error())
		return false
	}

	return true
}
