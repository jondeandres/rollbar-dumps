package main

import (
	"os"
)


func main() {
	binary := os.Args[1]
	core := os.Args[2]
	arguments := []string{"-n", "-q", "-i", "mi2", binary, core}

	gdb := NewGdb(arguments)

	BuildPayload(gdb)
}


func RecordInitialResponse(gdb *Gdb) string {
	return gdb.Record()
}
