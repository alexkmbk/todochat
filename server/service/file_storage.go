package service

import (
	"os"
	"path/filepath"
	"todochat_server/utils"
)

var FileStoragePath string

func InitFileStorage() {
	// Initialize the file storage path
	FileStoragePath = filepath.Join(utils.GetCurrentDir(), "FileStorage")

	if !utils.FileExists(FileStoragePath) {
		os.Mkdir(FileStoragePath, 0777)
	}
}

func WriteFile(fileName string, data []byte) error {
	// Write file to the storage path
	filePath := filepath.Join(FileStoragePath, fileName)
	err := os.WriteFile(filePath, data, 0644)
	if err != nil {
		utils.Log("File Saved: " + filepath.Join(FileStoragePath, fileName))
	}
	return err
}

func RemoveFile(fileName string) error {
	// Remove file from the storage path
	filePath := filepath.Join(FileStoragePath, fileName)
	if utils.FileExists(filePath) {
		err := os.Remove(filePath)
		if err != nil {
			utils.Log("Failed to remove file: " + filePath)
			return err
		}
		utils.Log("File removed: " + filePath)
	}
	return nil
}

func GetFile(fileName string) ([]byte, error) {
	return os.ReadFile(filepath.Join(FileStoragePath, fileName))
}
