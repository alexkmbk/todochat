package WS

import (
	"encoding/json"
	"net/http"
	"time"

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

// Client is a middleman between the websocket connection and the hub.
type Client struct {
	hub *Hub

	// The websocket connection.
	conn *websocket.Conn

	// Buffered channel of outbound messages.
	send chan *WSMessage

	sessionID uuid.UUID
}

var Upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 65536,
}

// use default options
var WSConnections = make(map[uuid.UUID]*websocket.Conn)
var WSIDs = make(map[*websocket.Conn]uuid.UUID)
var WSHub *Hub

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 10 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer.
	maxMessageSize = 512
)

var (
	newline = []byte{'\n'}
	space   = []byte{' '}
)

func InitMessagesWS(w http.ResponseWriter, r *http.Request) {

	// CORS
	Upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	var conn, err = Upgrader.Upgrade(w, r, nil)

	if err != nil {
		log.Print("upgrade:", err)
		return
	}

	keepAlive(conn, 10*time.Second)

	var sessionID uuid.UUID
	var message []byte

	for {
		_, message, err = conn.ReadMessage()
		if err != nil {
			//log.Println("read:", err)
			delete(WSConnections, sessionID)
			delete(WSIDs, conn)
			conn.Close()
			break
		}
		var query map[string]string
		err = json.Unmarshal(message, &query)

		if err != nil {
			delete(WSConnections, sessionID)
			delete(WSIDs, conn)
			conn.Close()
			break
		}

		if query["command"] == "init" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				println("CLOSE WS CONNECTION ON INIT!")
				conn.Close()
				break
			}
			WSConnections[sessionID] = conn
			WSIDs[conn] = sessionID
		} else if query["command"] == "getMessages" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				println("CLOSE WS CONNECTION ON getMessages!")
				conn.Close()
				break
			}

			lastID := ToInt64(query["lastID"])
			limit := ToInt64(query["limit"])
			taskID := ToInt64(query["taskID"])
			messageIDPosition := ToInt64(query["messageIDPosition"])
			res := GetMessagesDB(sessionID, lastID, limit, taskID, "", messageIDPosition)
			//if len(res) > 0 {
			conn.WriteJSON(WSMessage{"getMessages", res})
			//}

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

	WSHub.broadcast <- &WSMessage{"getMessages", message}
}

func keepAlive(conn *websocket.Conn, timeout time.Duration) {
	lastResponse := time.Now()
	conn.SetPongHandler(func(msg string) error {
		lastResponse = time.Now()
		return nil
	})

	go func() {
		for {
			err := conn.WriteMessage(websocket.PingMessage, []byte("keepalive"))
			if err != nil {
				return
			}
			time.Sleep(timeout / 2)
			if time.Since(lastResponse) > timeout {
				sessionID, ok := WSIDs[conn]
				if ok {
					delete(WSConnections, sessionID)
					DeleteSession(sessionID)
				}
				delete(WSIDs, conn)
				conn.Close()
				return
			}
		}
	}()
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

// readPump pumps messages from the websocket connection to the hub.
//
// The application runs readPump in a per-connection goroutine. The application
// ensures that there is at most one reader on a connection by executing all
// reads from this goroutine.
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
		if c.sessionID != uuid.Nil {
			DeleteSession(c.sessionID)
			c.sessionID = uuid.Nil
		}

	}()

	var sessionID uuid.UUID
	//var message []byte

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		//message = bytes.TrimSpace(bytes.Replace(message, newline, space, -1))

		/*if err != nil {
			//log.Println("read:", err)
			delete(WSConnections, sessionID)
			delete(WSIDs, conn)
			conn.Close()
			break
		}*/
		var query map[string]string
		err = json.Unmarshal(message, &query)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		/*if err != nil {
			delete(WSConnections, sessionID)
			delete(WSIDs, conn)
			conn.Close()
			break
		}*/

		if query["command"] == "init" {
			/*sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				println("CLOSE WS CONNECTION ON INIT!")
				//conn.Close()
				break
			}
			//WSConnections[sessionID] = conn
			//WSIDs[conn] = sessionID*/
		} else if query["command"] == "getMessages" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !SessionIDExists(sessionID) {
				println("CLOSE WS CONNECTION ON getMessages!")
				break
			}

			c.sessionID = sessionID
			lastID := ToInt64(query["lastID"])
			limit := ToInt64(query["limit"])
			taskID := ToInt64(query["taskID"])
			messageIDPosition := ToInt64(query["messageIDPosition"])
			res := GetMessagesDB(sessionID, lastID, limit, taskID, "", messageIDPosition)
			//if len(res) > 0 {
			//c.conn.WriteJSON(WSMessage{"getMessages", res})
			//}
			c.hub.broadcast <- &WSMessage{"getMessages", res}
		}
		//c.hub.broadcast <- message
	}
}

// writePump pumps messages from the hub to the websocket connection.
//
// A goroutine running writePump is started for each connection. The
// application ensures that there is at most one writer to a connection by
// executing all writes from this goroutine.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
		if c.sessionID != uuid.Nil {
			DeleteSession(c.sessionID)
			c.sessionID = uuid.Nil
		}
	}()
	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel.
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			/*w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)*/
			c.conn.WriteJSON(message)

			// Add queued chat messages to the current websocket message.
			n := len(c.send)
			for i := 0; i < n; i++ {
				c.conn.WriteJSON(<-c.send)
			}

			/*if err := w.Close(); err != nil {
				return
			}*/
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// serveWs handles websocket requests from the peer.
func ServeWs(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := Upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	client := &Client{hub: hub, conn: conn, send: make(chan *WSMessage, 256)}
	client.hub.register <- client

	// Allow collection of memory referenced by the caller by doing all work in
	// new goroutines.
	go client.writePump()
	go client.readPump()
}
