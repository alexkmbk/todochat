package main

import (
	"flag"
	"net/http"
	"os"
	"path/filepath"

	"github.com/kardianos/service"

	"gopkg.in/ini.v1"

	. "todochat_server/App"
	"todochat_server/DB"
	WS "todochat_server/constrollers/WebSocked"
	//"github.com/kardianos/service"
)

var logger service.Logger

type program struct{}

func (p *program) Start(s service.Service) error {
	// Start should not block. Do the actual work async.
	go p.run()
	return nil
}

func runMain() {
	port_ := flag.String("port", "80", "port")
	DBMS_ := flag.String("DBMS", "SQLite", "DBMS")
	DBUserName_ := flag.String("DBUserName", "", "DBUserName")
	DBPassword_ := flag.String("DBPassword", "", "DBPassword")
	DBName_ := flag.String("DBName", "", "DBName")
	DBHost_ := flag.String("DBHost", "", "DBHost")
	DBPort_ := flag.String("DBPort", "", "DBPort")
	DBTimeZone_ := flag.String("DBTimeZone", "", "DBTimeZone")
	DebugMode_ := flag.Bool("debug", false, "debug")
	logs_ := flag.Bool("logs", false, "logs")

	flag.Parse()

	DebugMode := *DebugMode_
	port := *port_
	DB.DBMS = *DBMS_
	DBUserName := *DBUserName_
	DBPassword := *DBPassword_
	DBName := *DBName_
	DBHost := *DBHost_
	DBPort := *DBPort_
	DBTimeZone := *DBTimeZone_
	DoLogs = *logs_
	var err error

	FileStoragePath = filepath.Join(GetCurrentDir(), "FileStorage")

	if !FileExists(FileStoragePath) {
		os.Mkdir(FileStoragePath, 0777)
	}

	//log.Info("FileStoragePath:" + FileStoragePath)

	Log("Starting Todolist API server")

	DB.InitDB(DB.DBMS, DBUserName, DBPassword, DBName, DBHost, DBPort, DBTimeZone)

	WS.WSHub = WS.NewHub()

	go WS.WSHub.Run()

	/*	if len(os.Args) > 1 {
		err = http.ListenAndServe(":"+os.Args[1], GetRoutesHandler())
	} else {*/
	val := os.Getenv("PORT")
	if val != "" {
		port = val
	}

	if DebugMode {
		err = http.ListenAndServe("localhost:"+port, GetRoutesHandler())
	} else {
		err = http.ListenAndServe(":"+port, GetRoutesHandler())
	}

	//err = http.ListenAndServeTLS(":"+port, "./keys/localhost.crt", "./keys/localhost.key", GetRoutesHandler())
	//}
	if err != nil {
		println(err.Error())
	}

}

func (p *program) run() {
	runMain()
}
func (p *program) Stop(s service.Service) error {
	// Stop should not block. Return with a few seconds.
	return nil
}

func main() {

	DisableServiceMode := false
	var err error
	cfg, err := ini.Load("settings.ini")
	if err == nil {
		settings := cfg.Section("")
		DisableServiceMode, err = settings.Key("DisableServiceMode").Bool()
		if err != nil {
			DisableServiceMode = false
		}
		/*DB.DBMS = settings.Key("DBMS").String()
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
		}*/

	}

	if DisableServiceMode || service.Interactive() {
		runMain()
	} else {

		svcConfig := &service.Config{
			Name:        "todochat",
			DisplayName: "ToDoChat",
			Description: "ToDoChat.",
			//Arguments:   []string{"port", "DBMS"},
		}

		prg := &program{}
		s, err := service.New(prg, svcConfig)
		if err != nil {
			Log_fatal(err)
		}
		logger, err = s.Logger(nil)
		if err != nil {
			Log_fatal(err)
		}
		err = s.Run()
		if err != nil {
			logger.Error(err)
		}
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
