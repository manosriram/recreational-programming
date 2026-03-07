package main

import "fmt"

type NodeListTypePart struct {
	Key   string
	Value any
}

type Node struct {
	Key      string
	Value    any
	Children []*Node
	Parent   string

	Type  string
	Parts []NodeListTypePart
}

func NewNode() Node {
	return Node{}
}

func BuildTree(root *Node, J any) any {
	if root == nil {
		return nil
	}

	for k, v := range J.(map[string]any) {
		switch v.(type) {
		case map[string]any:

			newNode := NewNode()
			newNode.Key = k
			newNode.Value = v
			newNode.Parent = root.Key
			root.Children = append(root.Children, &newNode)

			return BuildTree(&newNode, v)

		case []interface{}:
			newNode := NewNode()
			newNode.Key = k
			newNode.Value = v
			newNode.Parent = root.Key

			root.Children = append(root.Children, &newNode)

			for _, i := range v.([]interface{}) {
				parts := i.(map[string]any)
				for key, value := range parts {
					newNode.Parts = append(newNode.Parts, NodeListTypePart{
						Key:   key,
						Value: value,
					})
				}
			}
			fmt.Println(newNode.Parts)

		default:
			newNode := NewNode()
			newNode.Key = k
			newNode.Value = v
			newNode.Parent = root.Key

			root.Children = append(root.Children, &newNode)
		}
	}

	return nil
}

func QueryTree(root *Node, queryParts []string, idx int) any {
	if root == nil {
		return nil
	}
	if idx >= len(queryParts) {
		return root.Value
	}

	if root.Key == queryParts[idx] {
		return root.Value
	}

	for _, child := range root.Children {
		if child.Key == queryParts[idx] || child.Parent == queryParts[idx] {
			return QueryTree(child, queryParts, idx+1)
		}
	}

	return nil
}

func (n *Node) Walk() {
	if n == nil {
		return
	}

	for _, child := range n.Children {
		// fmt.Println(child.Key, child.Value, child.Parent)
		child.Walk()
	}

}
