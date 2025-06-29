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

func GetProjectsList() []map[int64]string {
	// getting list of projects with names
	var projects []map[int64]string
	DB.Table("projects").Select("id, Description").Scan(&projects)
	return projects
}
