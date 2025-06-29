package handlers

import (
	"bytes"
	"io"
	"net/http"
	"todochat_server/service"
	"todochat_server/utils"
)

func Healthz(w http.ResponseWriter, r *http.Request) {
	utils.Log("API Health is OK")
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	io.WriteString(w, `{"alive": "hello!"}`)
}

func GetFile(w http.ResponseWriter, r *http.Request) {

	query := r.URL.Query()
	fileName := query.Get("localFileName")

	if fileName == "" {
		return
	}

	data, err := service.GetFile(fileName)
	if err != nil {
		return
	}

	b := bytes.NewBuffer(data)

	w.Header().Set("Content-Type", "application/octet-stream")
	_, err = b.WriteTo(w)
	//w.Write(data)
	//	json.NewEncoder(w).Encode(ToBase64(data))
}
