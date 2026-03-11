package main

import (
	"database/sql"
	"fmt"

	_ "github.com/mattn/go-sqlite3"
)

type DB struct {
	Conn *sql.DB
}

func NewDB() (*DB, error) {
	fmt.Println("1")
	db, err := sql.Open("sqlite3", "./goqueue.db")
	fmt.Println("2")
	if err != nil {
		return nil, err
	}

	sqlStmt := `
		create table if not exists tasks (id varchar(64) not null primary key, name varchar(64), status varchar(64));
	`
	db.Exec(sqlStmt)

	return &DB{
		Conn: db,
	}, nil
}
