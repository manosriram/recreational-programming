package main

import (
	"fmt"
	"time"
)

type Worker struct {
	Task     string
	Id       string
	TaskList map[string]func() error
}

func Sleep5() error {
	for range 5 {
		time.Sleep(1 * time.Second)
		fmt.Println("Sleep5:Slept for 1 second")
	}
	return nil
}

func Sleep10() error {
	for range 10 {
		time.Sleep(1 * time.Second)
		fmt.Println("Sleep10:Slept for 1 second")
	}
	return nil
}

func NewWorker() Worker {
	t := make(map[string]func() error)
	t["sleep10"] = Sleep10
	t["sleep5"] = Sleep5

	return Worker{
		Id:       RandStringRunes(15),
		TaskList: t,
	}
}

func (w *Worker) DoWork(task string) error {
	fmt.Println(w.TaskList, task)
	t, ok := w.TaskList[task]
	if !ok {
		return fmt.Errorf("Task %s not found\n", w.Task)
	}

	return t()
}
