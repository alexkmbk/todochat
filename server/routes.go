package main

import (
	"net/http"

	"todochat_server/App"
	. "todochat_server/DB"
	"todochat_server/constrollers/Messages"
	"todochat_server/constrollers/Projects"
	"todochat_server/constrollers/Tasks"
	"todochat_server/constrollers/Users"
	WS "todochat_server/constrollers/WebSocked"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

func FileServer(fs http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !CheckSessionID(w, r) {
			return
		}

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
		if !CheckSessionID(w, r) {
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

//GetRoutesHandler inits router
func GetRoutesHandler() http.Handler {
	router := mux.NewRouter()

	router.HandleFunc("/healthz", App.Healthz).Methods("GET")
	router.HandleFunc("/login", Users.Login).Methods("GET")
	router.HandleFunc("/tasks", CommonHandler(Tasks.GetItems)).Methods("GET")
	router.HandleFunc("/todo", CommonHandler(Tasks.CreateItem)).Methods("POST")
	router.HandleFunc("/todo/{id}", CommonHandler(Tasks.UpdateItem)).Methods("POST")
	router.HandleFunc("/todo/{id}", CommonHandler(Tasks.DeleteItem)).Methods("DELETE")

	router.HandleFunc("/messages", CommonHandler(Messages.GetMessages)).Methods("GET")
	router.HandleFunc("/createMessage", CommonHandler(Messages.CreateMessage)).Methods("POST")
	router.HandleFunc("/deleteMessage/{id}", CommonHandler(Messages.DeleteItem)).Methods("DELETE")

	router.HandleFunc("/projects", CommonHandler(Projects.GetItems)).Methods("GET")
	router.HandleFunc("/project/{id}", CommonHandler(Projects.GetItem)).Methods("GET")
	router.HandleFunc("/createProject", CommonHandler(Projects.CreateItem)).Methods("POST")
	router.HandleFunc("/updateProject", CommonHandler(Projects.UpdateItem)).Methods("POST")
	router.HandleFunc("/deleteProject/{id}", CommonHandler(Projects.DeleteItem)).Methods("DELETE")

	router.HandleFunc("/registerNewUser", Users.RegisterNewUser).Methods("POST")

	router.HandleFunc("/initMessagesWS", WS.InitMessagesWS).Methods("GET")
	//router.HandleFunc("/echo", WS.Echo).Methods("GET")
	router.HandleFunc("/getFile", CommonHandler(Messages.GetFile)).Methods("GET")

	// File server
	fs := http.StripPrefix("/FileStorage/", http.FileServer(http.Dir("./FileStorage")))
	router.PathPrefix("/FileStorage/").Handler(FileServer(fs))
	router.PathPrefix("/").Handler(WebClient(http.FileServer(http.Dir("./WebClient")))).Methods("GET")

	router.PathPrefix("/").HandlerFunc(corsHandler).Methods("OPTIONS")

	// CORS
	handler := cors.New(cors.Options{
		AllowedHeaders: []string{"Accept", "Content-Type", "Bearer", "content-type", "Content-Length", "Accept-Encoding", "X-CSRF-Token", "Authorization", "Passwordhash", "Username", "Origin", "sessionID", "limit"},
		//AllowedHeaders:     []string{"Content-Type", "Bearer", "Bearer ", "content-type", "Origin", "Accept"},
		AllowedOrigins:         []string{"*"},
		AllowedMethods:         []string{"GET", "POST", "DELETE", "PATCH", "OPTIONS"},
		AllowCredentials:       true,
		OptionsPassthrough:     true,
		Debug:                  true,
		AllowOriginFunc:        origin,
		AllowOriginRequestFunc: originRequest,
	}).Handler(router)

	return handler
}
