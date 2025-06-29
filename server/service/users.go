package service

import (
	. "todochat_server/db"
	. "todochat_server/models"
	"todochat_server/utils"
	//"github.com/gorilla/mux"
)

func GetUserByID(ID int64) (*User, bool) {
	user := &User{}
	result := DB.First(&user, ID)
	if result.Error != nil {
		utils.Log_warn("User not found in database")
		return user, false
	}
	return user, true
}

func FindUserByName(userName string) (*User, bool) {

	user := &User{}
	err := DB.Where("Name = ?", userName).First(&user).Error
	return user, err == nil
}

func CreateUser(user *User) {

	DB.Create(&user)

}
