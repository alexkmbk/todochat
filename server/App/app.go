package App

import (
	"io"
	"net/http"
)

var FileStoragePath string

func Healthz(w http.ResponseWriter, r *http.Request) {
	Log("API Health is OK")
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	io.WriteString(w, `{"alive": "hello!"}`)
}
