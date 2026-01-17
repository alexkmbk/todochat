package service

import (
	. "todochat_server/db"
	. "todochat_server/models"
)

func CreateProject(item *Project) {
	DB.Create(&item)
}

func UpdateProject(item *Project) {

	DB.Save(&item)
}

func DeleteProject(id int64) error {

	// Test if the TodoItem exist in DB
	item, err := GetProjectByID(id)
	if err != nil {
		return err
	} else {
		DB.Delete(&item)
	}
	return nil
}

func GetProjectByID(ID int64) (*Project, error) {
	item := &Project{}
	result := DB.First(&item, ID)
	if result.Error != nil {
		return nil, result.Error
	}
	return item, nil
}

func GetProjects(limit int) []Project {

	var items []Project
	if limit != 0 {
		DB.Order("Description asc").Limit(limit).Find(&items)
	} else {
		DB.Order("Description asc").Find(&items)
	}
	return items
}

// Get unread messages by projects
func GetProjectsWithUnreadMessages(userID int64) []UnreadMessagesByProjects {
	var results []UnreadMessagesByProjects

	rows, err := DB.Table("projects").
		Select("projects.id, projects.Description, COUNT(case when messages.id IN (select seen_messages.message_id from seen_messages where seen_messages.user_id = ?) THEN 1 ELSE 0 END) as messages_count").
		Joins("LEFT JOIN messages ON messages.project_id = projects.id AND messages.user_id = ?").
		Group("projects.id, projects.Description").
		Rows()
	if err != nil {
		//utils.Log_warn("Error fetching unread messages by projects:", err)
		return results
	}
	defer rows.Close()

	for rows.Next() {
		var projectID int64
		var projectName string
		var messagesCount int64
		err := rows.Scan(&projectID, &projectName, &messagesCount)
		if err == nil {
			//utils.Log_warn("Error scanning row:", err)
			//continue
			project := Project{
				ID:          projectID,
				Description: projectName,
			}
			results = append(results, UnreadMessagesByProjects{
				Project:       project,
				MessagesCount: messagesCount,
			})
		}
		//results = append(results, {project: messagesCount})
	}

	return results
}

// func GetProjectsList() map[string]interface{} {
// 	// getting list of projects with names
// 	var projects map[string]interface{}
// 	DB.Table("projects").Select("ID, Description").Scan(&projects)
// 	return projects
// }
