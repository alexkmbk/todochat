package main

import (
	"net/http"
	"os"
	"path/filepath"

	log "github.com/sirupsen/logrus"
	//"gorm.io/driver/postgres"
	. "todochat_server/App"
	"todochat_server/DB"
)

func main() {
	//var err error
	//db, _ = gorm.Open(postgres.Open(dsn), &gorm.Config{})

	FileStoragePath = filepath.Join(GetCurrentDir(), "FileStorage")

	if !FileExists(FileStoragePath) {
		os.Mkdir(FileStoragePath, 0644)
	}

	log.Info("Starting Todolist API server")

	DB.InitDB()

	http.ListenAndServe(":80", GetRoutesHandler())
	//http.ListenAndServeTLS(":8000", "./keys/localhost.crt", "./keys/localhost.key", GetRoutesHandler())

}

// BasicAuth wraps a handler requiring HTTP basic auth for it using the given
// username and password and the specified realm, which shouldn't contain quotes.
//
// Most web browser display a dialog with something like:
//
//    The website says: "<realm>"
//
// Which is really stupid so you may want to set the realm to a message rather than
// an actual realm.
/*func BasicAuth(handler http.HandlerFunc, username, password, realm string) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {

		user, pass, ok := r.BasicAuth()

		if !ok || subtle.ConstantTimeCompare([]byte(user), []byte(username)) != 1 || subtle.ConstantTimeCompare([]byte(pass), []byte(password)) != 1 {
			w.Header().Set("WWW-Authenticate", `Basic realm="`+realm+`"`)
			w.WriteHeader(401)
			w.Write([]byte("Unauthorised.\n"))
			return
		}

		handler(w, r)
	}
}*/
