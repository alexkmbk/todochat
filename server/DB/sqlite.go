package DB

import (
	"os"
	"path/filepath"

	log "github.com/sirupsen/logrus"

	. "todochat_server/App"

	//"gorm.io/driver/sqlite"
	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

func InitDB_SQLite() bool {

	var err error
	var currentDir string

	exePath, err := os.Executable()
	if err == nil {
		currentDir = filepath.Dir(exePath)
	} else {
		currentDir = GetCurrentDir()
	}

	/*f, err := os.Create("d:\\todochat.log")
	defer f.Close()

	if err == nil {
		w := bufio.NewWriter(f)
		w.WriteString("current dir:" + GetCurrentDir())
		ex, err := os.Executable()
		if err == nil {
			w.WriteString("current exe:" + filepath.Dir(ex))
		}
		w.Flush()
	}*/

	DBPAth := filepath.Join(currentDir, "gorm.db")
	DB, err = gorm.Open(sqlite.Open("file:///"+DBPAth+"?cache=shared&_pragma=journal_mode(MEMORY)&_pragma=busy_timeout(20000)"), &gorm.Config{})
	if err != nil {
		log.Println(err)
		return false
	}
	return true
}

func InitFTS_SQLite() {
	// Full text search

	// FTS Messages
	DB.Exec("DROP TABLE IF EXISTS messages_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(text, task_id UNINDEXED, project_id UNINDEXED, content=messages, content_rowid=ID)")
	DB.Exec("INSERT INTO messages_fts (rowid, text, task_id, project_id) SELECT ID, text, task_id, project_id FROM messages")

	// MESSAGE INSERT TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_ai")
	trigger_query := `CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages 
	    BEGIN
	        INSERT INTO messages_fts (rowid, text, task_id, project_id) 
	        VALUES (new.id, new.text, new.task_id, new.project_id);
	    END;`

	DB.Exec(trigger_query)

	// MESSAGE DELETE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_ad")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
	INSERT INTO messages_fts(messages_fts, rowid, text, task_id, project_id) VALUES('delete', old.id, old.text, old.task_id, old.project_id);
  END`

	DB.Exec(trigger_query)

	// MESSAGE UPDATE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_au")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
	INSERT INTO messages_fts(messages_fts, rowid, text, task_id, project_id) VALUES('delete', old.id, old.text, old.task_id, old.project_id);
	INSERT INTO messages_fts(rowid, text, task_id, project_id) VALUES(new.id, new.text, new.task_id, new.project_id);
  END`

	DB.Exec(trigger_query)

	// FTS Tasks
	DB.Exec("DROP TABLE IF EXISTS tasks_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(description, project_id UNINDEXED, content=tasks, content_rowid=ID)")
	DB.Exec("INSERT INTO tasks_fts (rowid, description, project_id) SELECT ID, description, project_id FROM tasks")

	// TASK INSERT TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ai")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks
	    BEGIN
	        INSERT INTO tasks_fts (rowid, description, project_id)
	        VALUES (new.id, new.description, new.project_id);
	    END;`

	DB.Exec(trigger_query)

	// TASK DELETE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ad")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description, project_id) VALUES('delete', old.id, old.description, old.project_id);
  END`

	DB.Exec(trigger_query)

	// TASK UPDATE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_au")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description, project_id) VALUES('delete', old.id, old.description, old.project_id);
	INSERT INTO tasks_fts(rowid, description, project_id) VALUES(new.id, new.description, new.project_id);
  END`

	DB.Exec(trigger_query)

}
