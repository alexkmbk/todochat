package WS

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	. "todochat_server/models"
	"todochat_server/service"
	"todochat_server/utils"
)

type WSMessage struct {
	Command string
	Data    interface{}
	UserID  int64
}

// Client is a middleman between the websocket connection and the hub.
type Client struct {
	hub *Hub

	// The websocket connection.
	conn *websocket.Conn

	// Buffered channel of outbound messages.
	send chan *WSMessage

	sessionID uuid.UUID

	//userID int64
}

var Upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 65536,
}

var WSHub *Hub

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer.
	maxMessageSize = 512
)

var (
	newline = []byte{'\n'}
	space   = []byte{' '}
)

func SendWSMessage(message *Message) {
	/*for key, conn := range WSConnections {
		if SessionIDExists(key) {
			conn.WriteJSON(WSMessage{"createMessage", message})
		}
	}*/

	WSHub.broadcast <- &WSMessage{"createMessage", message, 0}
}

func SendWSUpdateMessage(message *Message) {

	WSHub.broadcast <- &WSMessage{"updateMessage", message, 0}
}

func SendDeleteMessage(message *Message, task *Task) {
	data := []interface{}{message, task}
	WSHub.broadcast <- &WSMessage{"deleteMessage", data, 0}
}

func SendUnreadMessages(data []map[int64]int64) {
	WSHub.broadcast <- &WSMessage{"unreadMessages", data, 0}
}

func SendDeleteTask(task *Task) {
	/*for key, conn := range WSConnections {
		if SessionIDExists(key) {
			conn.WriteJSON(WSMessage{"createMessage", message})
		}
	}*/

	WSHub.broadcast <- &WSMessage{"deleteTask", task.ID, 0}
}

func SendUpdateTask(task *Task, userID int64) {

	WSHub.broadcast <- &WSMessage{"updateTask", task, userID}
}

func SendTask(task *Task) {

	WSHub.broadcast <- &WSMessage{"createTask", task, 0}
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
			service.DeleteSession(c.sessionID)
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
				utils.Log(fmt.Sprintf("error: %v", err))
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
				utils.Log(fmt.Sprintf("error: %v", err))
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
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !service.SessionIDExists(sessionID) {
				utils.Log("CLOSE WS CONNECTION ON init!")
				break
			}
			c.sessionID = sessionID
		} else if query["command"] == "getMessages" {
			sessionID, err = uuid.Parse(query["sessionID"])
			if sessionID == uuid.Nil || !service.SessionIDExists(sessionID) {
				utils.Log("CLOSE WS CONNECTION ON getMessages!")
				break
			}

			c.sessionID = sessionID
			lastID := utils.ToInt64(query["lastID"])
			limit := utils.ToInt64(query["limit"])
			taskID := utils.ToInt64(query["taskID"])
			messageIDPosition := utils.ToInt64(query["messageIDPosition"])
			res := service.GetMessagesDB(sessionID, lastID, limit, taskID, "", messageIDPosition)
			//res := service.GetMessages(userID, taskID, lastID, limit)
			//if len(res) > 0 {
			//c.conn.WriteJSON(WSMessage{"getMessages", res})
			//}
			c.hub.broadcast <- &WSMessage{"getMessages", res, 0}
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
			service.DeleteSession(c.sessionID)
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
func ServeWs(hub *Hub, w http.ResponseWriter, r *http.Request, DebugMode bool) {

	if DebugMode {
		Upgrader.CheckOrigin = func(r *http.Request) bool {
			return true
		}
	}
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
