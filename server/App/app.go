package App

import (
	"io"
	"net/http"

	log "github.com/sirupsen/logrus"
)

var FileStoragePath string

func Healthz(w http.ResponseWriter, r *http.Request) {
	log.Info("API Health is OK")
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	io.WriteString(w, `{"alive": "hello!"}`)
}
