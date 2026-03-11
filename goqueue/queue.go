package main

import (
	"fmt"
)

/*
	init db - get all notok/waiting/inprogress tasks from db and load it into memory
	task added - update db
	task updated - update db

*/

type Queue struct {
	Dispatcher Dispatcher
	TaskQueue  chan Task
	DB         *DB
}

func NewQueue(d *DB) Queue {
	q := Queue{
		Dispatcher: NewDispatcher(d),
		TaskQueue:  make(chan Task, 1000),
		DB:         d,
	}
	go q.Init()
	return q
}

func (q *Queue) Init() {
	fmt.Println("Queue init started")
	for {
		t := <-q.TaskQueue

		fmt.Println("Got task ", t.Id)
		err := q.Dispatcher.Dispatch(t.Id, t.Name)
		if err != nil {
			fmt.Println("Error dispatching: " + err.Error())
		} else {
			fmt.Println("Task Done: " + t.Id)
		}
	}
}

func (q *Queue) Add(task string) error {
	taskId := RandStringRunes(15)

	query := `
	insert into tasks(id, name, status) values(?, ?, ?)
	`
	q.DB.Conn.Exec(query, taskId, task, "waiting")

	q.TaskQueue <- Task{
		Name: task,
		Id:   taskId,
	}

	return nil
}
