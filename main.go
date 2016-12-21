package main

import (
	"os"
)


func main() {
	binary := os.Args[1]
	core := os.Args[2]
	arguments := []string{"-n", "-q", "-i", "mi2", binary, core}

	gdb := NewGdb(arguments)

	SendPayload(BuildPayload(gdb))
}
