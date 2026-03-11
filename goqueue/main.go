package main

import (
	"fmt"
	"log"

	"github.com/gofiber/fiber/v3"
)

type ScheduleReq struct {
	TaskId string `json:"task_id"`
}

func Schedule(c fiber.Ctx) error {
	var s ScheduleReq
	c.Bind().JSON(&s)

	q := c.Locals("queue").(Queue)
	err := q.Add(s.TaskId)
	if err != nil {
		return c.Status(500).SendString(err.Error())
	}

	return c.SendString("Job scheduled!")
}

func loadTasksFromDB(db *DB, q *Queue) error {
	query := `SELECT id, name FROM tasks where status in ('waiting', 'processing')`
	rows, err := db.Conn.Query(query)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var id string
		var name string
		err = rows.Scan(&id, &name)
		if err != nil {
			log.Fatal(err)
		}

		fmt.Println("Restoring task item " + id + ":" + name + " from db")
		q.Add(name)
	}

	return nil
}

func main() {
	db, err := NewDB()
	if err != nil {
		log.Fatalf("Error initializing DB: %s\n", err.Error())
	}

	// Initialize a new Fiber app
	app := fiber.New()

	q := NewQueue(db)

	err = loadTasksFromDB(db, &q)
	if err != nil {
		log.Fatalf("Error loading tasks from DB\n")
	}

	app.Use(func(c fiber.Ctx) error {
		c.Locals("queue", q)
		return c.Next()
	})

	// Define a route for the GET method on the root path '/'
	app.Post("/schedule", Schedule)
	// app.Get("/get_queued_jobs", x)

	// Start the server on port 3000
	log.Fatal(app.Listen(":3000"))
}
