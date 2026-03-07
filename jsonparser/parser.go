package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
)

type Parser struct {
	JsonMap         map[string]any
	JsonDataInBytes []byte
	JsonMapRootNode *Node
}

func NewParser(jsonPath string) Parser {
	jsonDataInBytes, err := os.ReadFile(jsonPath)
	if err != nil {
		log.Fatalf("Error reading mock/data.json")
	}

	return Parser{
		JsonMap:         make(map[string]any),
		JsonDataInBytes: jsonDataInBytes,
	}
}

func (p *Parser) Parse() error {
	err := json.Unmarshal(p.JsonDataInBytes, &p.JsonMap)
	if err != nil {
		return err
	}

	rootNode := NewNode()
	BuildTree(&rootNode, p.JsonMap)

	p.JsonMapRootNode = &rootNode

	// rootNode.Walk()

	return err
}

func (p *Parser) Query(q string) any {
	queryParts := strings.Split(q, ".")
	return QueryTree(p.JsonMapRootNode, queryParts, 0)
}

func (p *Parser) Watch(path string) {
	w := NewWatcher(path, func() {
		fmt.Println("file has been modified")
		pp := NewParser("mock/data.json")
		pp.Parse()
		fmt.Println(pp.JsonMapRootNode.Children)
		fmt.Println("query = ", pp.Query("total_time_spent"))
	})
	defer w.Close()

	w.Watch()
}
