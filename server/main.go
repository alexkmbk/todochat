package main

import (
	"net/http"
	"os"
	"path/filepath"

	log "github.com/sirupsen/logrus"
	//"gorm.io/driver/postgres"
	. "todochat_server/App"
	"todochat_server/DB"
	WS "todochat_server/constrollers/WebSocked"

	"github.com/kardianos/service"
	"gopkg.in/ini.v1"
)

var logger service.Logger

type program struct{}

func (p *program) Start(s service.Service) error {
	// Start should not block. Do the actual work async.
	go p.run()
	return nil
}
func (p *program) run() {
	//var err error
	//db, _ = gorm.Open(postgres.Open(dsn), &gorm.Config{})

	DB.DBMS = "SQLite"
	DBUserName := ""
	DBPassword := ""
	DBName := ""
	DBHost := ""
	DBPort := ""
	DBTimeZone := ""
	port := "80"

	cfg, err := ini.Load("settings.ini")
	if err == nil {
		settings := cfg.Section("")
		DB.DBMS = settings.Key("DBMS").String()
		if DB.DBMS == "" {
			DB.DBMS = "SQLite"
		}
		DBUserName = settings.Key("DBUserName").String()
		DBName = settings.Key("DBName").String()
		DBHost = settings.Key("DBHost").String()
		DBPassword = settings.Key("DBPassword").String()
		DBTimeZone = settings.Key("TimeZone").String()

		port = settings.Key("Port").String()
		if port == "" {
			port = "80"
		}

	}

	FileStoragePath = filepath.Join(GetCurrentDir(), "FileStorage")

	if !FileExists(FileStoragePath) {
		os.Mkdir(FileStoragePath, 0777)
	}

	log.Info("Starting Todolist API server")

	DB.InitDB(DB.DBMS, DBUserName, DBPassword, DBName, DBHost, DBPort, DBTimeZone)

	WS.WSHub = WS.NewHub()

	go WS.WSHub.Run()

	if len(os.Args) > 1 {
		err = http.ListenAndServe(":"+os.Args[1], GetRoutesHandler())
	} else {
		val := os.Getenv("PORT")
		if val != "" {
			port = val
		}
		err = http.ListenAndServe(":"+port, GetRoutesHandler())
	}
	if err != nil {
		println(err.Error())
	}
	//http.ListenAndServeTLS(":8000", "./keys/localhost.crt", "./keys/localhost.key", GetRoutesHandler())
}
func (p *program) Stop(s service.Service) error {
	// Stop should not block. Return with a few seconds.
	return nil
}

func main() {

	svcConfig := &service.Config{
		Name:        "todochat",
		DisplayName: "ToDoChat",
		Description: "ToDoChat.",
	}

	prg := &program{}
	s, err := service.New(prg, svcConfig)
	if err != nil {
		log.Fatal(err)
	}
	logger, err = s.Logger(nil)
	if err != nil {
		log.Fatal(err)
	}
	err = s.Run()
	if err != nil {
		logger.Error(err)
	}

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
