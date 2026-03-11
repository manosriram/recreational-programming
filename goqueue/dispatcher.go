package main

import (
	"fmt"
	"time"
)

type Task struct {
	Id     string
	Name   string
	Status string
}

type Dispatcher struct {
	Worker Worker
	Task   Task
	DB     *DB
}

func NewDispatcher(db *DB) Dispatcher {
	return Dispatcher{
		Worker: NewWorker(),
		Task: Task{
			Status: "waiting",
		},
		DB: db,
	}
}

func (d *Dispatcher) updateTaskStatus(taskId, status string) {
	query := fmt.Sprintf(`
	UPDATE tasks set status = '%s' where id = ?
	`, status)
	d.DB.Conn.Exec(query, taskId)
}

func (d *Dispatcher) CallWorker() error {
	d.Task.Status = "processing"

	d.updateTaskStatus(d.Task.Id, d.Task.Status)

	err := d.Worker.DoWork(d.Task.Name)

	if err != nil {
		d.Task.Status = "notok"
		d.updateTaskStatus(d.Task.Id, "notok")
		return err
	}
	d.Task.Status = "ok"
	d.updateTaskStatus(d.Task.Id, "ok")
	return nil
}

func (d *Dispatcher) Dispatch(taskId, taskName string) error {
	d.Task.Id = taskId
	d.Task.Name = taskName

	retries := 1
	err := d.CallWorker()
	for retries <= 3 && err != nil {
		fmt.Println("Retrying task " + d.Task.Id + "; count " + fmt.Sprintf("%v", retries))
		retries += 1
		time.Sleep(time.Second * time.Duration(retries))
		err = d.CallWorker()
	}

	return err
}
