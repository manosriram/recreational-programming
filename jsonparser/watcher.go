package main

import (
	"fmt"
	"log"

	"github.com/fsnotify/fsnotify"
)

type Watcher struct {
	Path            string
	fsNotifyWatcher *fsnotify.Watcher
}

func NewWatcher(Path string, fn func()) Watcher {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
	}
	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				log.Println("event:", event)
				// fn()

				pp := NewParser("mock/data.json")
				pp.Parse()
				fmt.Println(pp.JsonMapRootNode.Children)
				fmt.Println("query = ", pp.Query("total_time_spent"))

				if event.Has(fsnotify.Write) {
					log.Println("modified file:", event.Name)
				}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Println("error:", err)
			}
		}
	}()

	return Watcher{
		Path:            Path,
		fsNotifyWatcher: watcher,
	}
}

func (w *Watcher) Watch() {
	w.fsNotifyWatcher.Add(w.Path)
	<-make(chan struct{})
}

func (w *Watcher) Close() {
	w.fsNotifyWatcher.Close()
}
