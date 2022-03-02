package WS

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	. "todochat_server/DB"

	log "github.com/sirupsen/logrus"
)

var Upgrader = websocket.Upgrader{} // use default options
var WSConnections = make(map[uuid.UUID]*websocket.Conn)

func InitMessagesWS(w http.ResponseWriter, r *http.Request) {

	var conn, err = Upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade:", err)
		return
	}

	var sessionID uuid.UUID
	var message []byte

	for {
		_, message, err = conn.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			delete(WSConnections, sessionID)
			conn.Close()
			break
		}
		sessionID, err = uuid.Parse(string(message))
		if !SessionIDExists(sessionID) {
			conn.Close()
			break
		}
		WSConnections[sessionID] = conn

		/*log.Printf("recv: %s", message)
		err = conn.WriteMessage(mt, message)
		if err != nil {
			log.Println("write:", err)
			break
		}*/
	}
}

func SendWSMessage(message Message) {
	for key, conn := range WSConnections {
		if SessionIDExists(key) {
			conn.WriteJSON(message)
		}
	}
}

func Echo(w http.ResponseWriter, r *http.Request) {
	c, err := Upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade:", err)
		return
	}
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}
		log.Printf("recv: %s", message)
		err = c.WriteMessage(mt, message)
		if err != nil {
			log.Println("write:", err)
			break
		}
	}

	c.Close()
}
