package models

import (
	"time"

	"github.com/google/uuid"
)

// Session Session info
type Session struct {
	SessionID uuid.UUID `gorm:"primary_key"`
	LastVisit time.Time `gorm:"index"`
	UserID    int64     `gorm:"foreignKey:ID"`
}

// User ... idk
type User struct {
	ID           int64  `gorm:"primary_key"`
	Name         string `gorm:"size:50"`
	PasswordHash string
	Email        string `gorm:"size:320"`
	IsAdmin      bool
	LastVisit    time.Time
}

// Task ...idk
type Task struct {
	ID        int64 `gorm:"primary_key"`
	ProjectID int64 `gorm:"index"`
	//Project     *Project `gorm:"foreignKey:ID"`
	Description         string
	LastMessage         string
	LastMessageID       int64
	LastMessageUserName string
	Completed           bool `gorm:"default:false"`
	Cancelled           bool `gorm:"default:false"`
	Closed              bool `gorm:"default:false"`
	InHand              bool `gorm:"default:false"`
	AuthorID            int64
	AuthorName          string
	//Author        *User `gorm:"foreignKey:ID"`
	Creation_date  time.Time `gorm:"index"`
	Read           bool      `gorm:"-"`
	UnreadMessages int       `gorm:"-"`
}

type MessageAction int

const (
	CreateUpdateMessageAction  MessageAction = 0
	CompleteTaskAction         MessageAction = 1
	ReopenTaskAction           MessageAction = 2
	CloseTaskAction            MessageAction = 3
	CancelTaskAction           MessageAction = 4
	RemoveCompletedLabelAction MessageAction = 5
	InHand                     MessageAction = 6
	RemoveInHand               MessageAction = 7
)

type Message struct {
	ID                    int64 `gorm:"primary_key"`
	TaskID                int64 `gorm:"index"`
	ParentMessageID       int64
	ProjectID             int64
	Text                  string
	QuotedText            string `gorm:"default:''"`
	UserID                int64
	UserName              string
	SmallImageWidth       int
	SmallImageHeight      int
	FileName              string
	LocalFileName         string
	FileSize              int64 `gorm:"default:0"`
	SmallImageName        string
	ParentsmallImageName  string `gorm:"default:''"`
	IsImage               bool
	Created_at            time.Time
	IsTaskDescriptionItem bool `gorm:"default:false"`
	TempID                string
	LoadinInProcess       bool

	MessageAction MessageAction `gorm:"default:0"`
}

type SeenTask struct {
	UserID int64 `gorm:"primaryKey;autoIncrement:false;uniqueIndex:idx_userid_taskid"`
	TaskID int64 `gorm:"primaryKey;autoIncrement:false;uniqueIndex:idx_userid_taskid"`
}

type SeenMessage struct {
	UserID    int64 `gorm:"primaryKey;autoIncrement:false;uniqueIndex:idx_userid_messageid"`
	TaskID    int64 `gorm:"primaryKey;autoIncrement:false;uniqueIndex:idx_userid_messageid"`
	MessageID int64 `gorm:"primaryKey;autoIncrement:false;uniqueIndex:idx_userid_messageid"`
}

/*type Message struct {
	ID     int `gorm:"primary_key"`
	TaskID int
	//Task            Task `gorm:"foreignKey:TaskID"`
	ParentMessageID int
	ParentMessage   *Message `gorm:"foreignKey:ParentMessageID"`
	Text            string
	UserID          int
	//User            User      `gorm:"foreignKey:UserID"`
	field1 time.Time
}*/

// Project ... idk
type Project struct {
	ID          int64  `gorm:"primary_key"`
	Description string `gorm:"size:100"`
}

type UnreadMessagesByProjects struct {
	Project       Project `json:"project"`
	MessagesCount int64   `json:"messagesCount"`
}
