package WS

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	. "todochat_server/App"
	. "todochat_server/DB"

	log "github.com/sirupsen/logrus"
)

type WSMessage struct {
	Command string
	Data    interface{}
}

var Upgrader = websocket.Upgrader{
	ReadBufferSize:  100000,
	WriteBufferSize: 100000,
} // use default options
var WSConnections = make(map[uuid.UUID]*websocket.Conn)

func InitMessagesWS(w http.ResponseWriter, r *http.Request) {

	// CORS
	Upgrader.CheckOrigin = func(r *http.Request) bool { return true }

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
			//log.Println("read:", err)
			delete(WSConnections, sessionID)
			conn.Close()
			break
		}
		var query map[string]string
		err = json.Unmarshal(message, &query)

		if err != nil {
			delete(WSConnections, sessionID)
			conn.Close()
			break
		}

		if query["command"] == "init" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				conn.Close()
				break
			}
			WSConnections[sessionID] = conn
		} else if query["command"] == "getMessages" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				conn.Close()
				break
			}

			lastID := ToInt64(query["lastID"])
			limit := ToInt64(query["limit"])
			taskID := ToInt64(query["taskID"])
			res := GetMessagesDB(lastID, limit, taskID, "")
			if len(res) > 0 {
				conn.WriteJSON(WSMessage{"getMessages", res})
			}

		}

		/*log.Printf("recv: %s", message)
		err = conn.WriteMessage(mt, message)
		if err != nil {
			log.Println("write:", err)
			break
		}*/
	}
}

func SendWSMessage(message *Message) {
	for key, conn := range WSConnections {
		if SessionIDExists(key) {
			conn.WriteJSON(WSMessage{"createMessage", message})
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
