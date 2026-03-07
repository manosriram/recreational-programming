package main

import "fmt"

func main() {
	p := NewParser("mock/data.json")
	p.Parse()
	fmt.Println(p.Query("youtube.total_views[0]"))

	p.Watch("mock/data.json")

	/*
		1. List access via query
		2. Non Deterministic results
	*/
}
