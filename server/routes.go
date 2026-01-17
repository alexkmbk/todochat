package main

import (
	"net/http"
	"os"
	"path/filepath"

	//. "todochat_server/DB"
	WS "todochat_server/WebSocked"

	"todochat_server/handlers"

	"todochat_server/utils"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

func FileServer(fs http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		/*if !CheckSessionID(w, r, false) {
			return
		}*/

		fs.ServeHTTP(w, r)
	}
}

func WebClient(fs http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fs.ServeHTTP(w, r)
	}
}

func CommonHandler(f http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		res, _ := handlers.CheckSessionID(w, r, true)
		if !res {
			return
		}
		f(w, r)
	}
}

func corsHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	return
}

func origin(origin string) bool {
	return true

}

func originRequest(r *http.Request, origin string) bool {
	return true
}

// GetRoutesHandler inits router
func GetRoutesHandler(DebugMode bool) http.Handler {

	router := mux.NewRouter()

	router.HandleFunc("/healthz", handlers.Healthz).Methods("GET")
	router.HandleFunc("/login", handlers.Login).Methods("POST")
	router.HandleFunc("/checkLogin", handlers.CheckLogin).Methods("GET")
	router.HandleFunc("/logoff", handlers.Logoff).Methods("POST")
	router.HandleFunc("/tasks", CommonHandler(handlers.GetTasks)).Methods("GET")
	router.HandleFunc("/searchTasks", CommonHandler(handlers.SearchTasks)).Methods("GET")
	router.HandleFunc("/markallread", CommonHandler(handlers.MarkAllRead)).Methods("POST")

	router.HandleFunc("/todo", CommonHandler(handlers.CreateTask)).Methods("POST")
	router.HandleFunc("/updateTask", CommonHandler(handlers.UpdateTask)).Methods("POST")
	router.HandleFunc("/todo/{id}", CommonHandler(handlers.UpdateTask)).Methods("POST")
	router.HandleFunc("/todo/{id}", CommonHandler(handlers.DeleteTask)).Methods("DELETE")
	router.HandleFunc("/todo/{id}", CommonHandler(handlers.GetTask)).Methods("GET")

	router.HandleFunc("/messages", CommonHandler(handlers.GetMessages)).Methods("GET")
	router.HandleFunc("/message/{id}", CommonHandler(handlers.GetMessage)).Methods("GET")
	router.HandleFunc("/createMessage", CommonHandler(handlers.CreateMessage)).Methods("POST")
	router.HandleFunc("/updateMessage", CommonHandler(handlers.UpdateMessage)).Methods("POST")
	router.HandleFunc("/createMessageWithFile", CommonHandler(handlers.CreateMessageWithFile)).Methods("POST")
	router.HandleFunc("/deleteMessage/{id}", CommonHandler(handlers.DeleteMessage)).Methods("DELETE")

	router.HandleFunc("/projects", CommonHandler(handlers.GetProjects)).Methods("GET")
	router.HandleFunc("/projectsWithUnreadMessages", CommonHandler(handlers.GetProjectsWithUnreadMessages)).Methods("GET")
	router.HandleFunc("/project/{id}", CommonHandler(handlers.GetProject)).Methods("GET")
	router.HandleFunc("/createProject", CommonHandler(handlers.CreateProject)).Methods("POST")
	router.HandleFunc("/updateProject", CommonHandler(handlers.UpdateProject)).Methods("POST")
	router.HandleFunc("/deleteProject/{id}", CommonHandler(handlers.DeleteProject)).Methods("DELETE")

	router.HandleFunc("/registerNewUser", handlers.RegisterNewUser).Methods("POST")

	//router.HandleFunc("/initMessagesWS", WS.InitMessagesWS).Methods("GET")
	router.HandleFunc("/initMessagesWS", func(w http.ResponseWriter, r *http.Request) {
		WS.ServeWs(WS.WSHub, w, r, DebugMode)
	}).Methods("GET")
	//router.HandleFunc("/echo", WS.Echo).Methods("GET")
	router.HandleFunc("/getFile", CommonHandler(handlers.GetFile)).Methods("POST")

	// File server

	var currentDir string

	exePath, err := os.Executable()
	if err == nil {
		currentDir = filepath.Dir(exePath)
	} else {
		currentDir = utils.GetCurrentDir()
	}

	fs := http.StripPrefix("/FileStorage/", http.FileServer(http.Dir(filepath.Join(currentDir, "FileStorage"))))
	router.PathPrefix("/FileStorage/").Handler(FileServer(fs))

	webClientPath := filepath.Join(currentDir, "WebClient")
	indexTemplatePath := filepath.Join(webClientPath, "index.html")

	// // 1. /{id} → отдать index.html с внедрённым id
	router.HandleFunc("/{id:\\d{6}}", func(w http.ResponseWriter, r *http.Request) {

		// Читаем шаблон index.html
		data, err := os.ReadFile(indexTemplatePath)
		if err != nil {
			http.Error(w, "Index not found", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(data))
	}).Methods("GET")

	// router.PathPrefix("/{id:\\d{6}}").Handler(
	// 	WebClient(http.FileServer(http.Dir(filepath.Join(currentDir, "WebClient")))),
	// ).Methods("GET")

	router.PathPrefix("/").Handler(WebClient(http.FileServer(http.Dir(filepath.Join(currentDir, "WebClient"))))).Methods("GET")

	router.PathPrefix("/").HandlerFunc(corsHandler).Methods("OPTIONS")

	// CORS
	if DebugMode {
		return cors.New(cors.Options{
			AllowedHeaders: []string{"Accept", "Content-Type", "Bearer", "content-type", "Content-Length", "Accept-Encoding", "X-CSRF-Token", "Authorization", "Passwordhash", "Username", "Origin", "sessionID", "limit"},
			//AllowedHeaders:     []string{"Content-Type", "Bearer", "Bearer ", "content-type", "Origin", "Accept"},
			AllowedOrigins:     []string{"*"},
			AllowedMethods:     []string{"GET", "POST", "DELETE", "PATCH", "OPTIONS"},
			AllowCredentials:   true,
			OptionsPassthrough: true,
			//Debug:                  true,
			AllowOriginFunc:        origin,
			AllowOriginRequestFunc: originRequest,
		}).Handler(router)
	} else {
		return router
	}

}
