package main

import (
	"os/exec"
	"io"
	"bufio"
	"bytes"
	"fmt"
)


type Gdb struct {
	cmd *exec.Cmd
	stdout io.ReadCloser
	stdin io.WriteCloser
	scanner *bufio.Scanner
}

func NewGdb(arguments []string) *Gdb{

	cmd := exec.Command("gdb", arguments...)
	stdout, _ := cmd.StdoutPipe()
	stdin, _ := cmd.StdinPipe()

	gdb := Gdb{
		cmd: cmd,
		stdout: stdout,
		stdin: stdin,
		scanner: bufio.NewScanner(stdout),
	}

	return &gdb
}

func (gdb *Gdb)Start() string {
	gdb.cmd.Start()

	// we want to parse the initial response
	return gdb.Record()
}


func (gdb *Gdb)Send(command string) map[string]interface{} {
	gdb.stdin.Write([]byte(fmt.Sprintf("%s\n", command)))

	return parseRecord(gdb.Record())
}

func (gdb *Gdb)Record() string {
	buffer := bytes.NewBufferString("")

	for gdb.scanner.Scan() {
		line := gdb.scanner.Text()

		if (line == terminator) {
			break
		}

		buffer.WriteString(line)
	}

	return buffer.String()
}
