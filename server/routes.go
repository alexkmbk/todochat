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

//GetRoutesHandler inits router
func GetRoutesHandler() http.Handler {
	router := mux.NewRouter()

	router.HandleFunc("/healthz", App.Healthz).Methods("GET")
	router.HandleFunc("/login", Users.Login).Methods("GET")
	router.HandleFunc("/todoItems", Tasks.GetItems).Methods("GET")
	router.HandleFunc("/todo", Tasks.CreateItem).Methods("POST")
	router.HandleFunc("/todo/{id}", Tasks.UpdateItem).Methods("POST")
	router.HandleFunc("/todo/{id}", Tasks.DeleteItem).Methods("DELETE")

	router.HandleFunc("/messages", Messages.GetMessages).Methods("GET")
	router.HandleFunc("/createMessage", Messages.CreateMessage).Methods("POST")
	router.HandleFunc("/deleteMessage/{id}", Messages.DeleteItem).Methods("DELETE")

	router.HandleFunc("/projects", Projects.GetItems).Methods("GET")
	router.HandleFunc("/project/{id}", Projects.GetItem).Methods("GET")
	router.HandleFunc("/createProject", Projects.CreateItem).Methods("POST")
	router.HandleFunc("/deleteProject/{id}", Projects.DeleteItem).Methods("DELETE")

	router.HandleFunc("/registerNewUser", Users.RegisterNewUser).Methods("POST")

	router.HandleFunc("/initMessagesWS", WS.InitMessagesWS).Methods("GET")
	router.HandleFunc("/echo", WS.Echo).Methods("GET")

	//router.PathPrefix("/").Handler(http.FileServer(http.Dir("E:\\DEV\\Go\\todo\\")))
	//fs := http.FileServer(http.Dir("./FileStorage"))
	fs := http.FileServer(http.Dir(http.Dir("E:\\DEV\\Go\\todo\\")))
	router.Handle("/", FileServer(fs))

	handler := cors.New(cors.Options{
		AllowedHeaders:   []string{"Accept", "content-type", "Content-Length", "Accept-Encoding", "X-CSRF-Token", "Authorization"},
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "DELETE", "PATCH", "OPTIONS"},
		AllowCredentials: true,
	}).Handler(router)

	return handler
}
