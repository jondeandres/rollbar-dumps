package main

import (
	"github.com/kr/pretty"
	"fmt"
	"strconv"
)


func BuildPayload(gdb *Gdb) {
	gdb.Start()

	depth, _ := strconv.ParseInt(gdb.Send("-stack-info-depth")["payload"].(map[string]interface{})["depth"].(string), 10, 64)

	for i := depth - 1; i >= 0; i-- {
		gdb.Send(fmt.Sprintf("-stack-select-frame %d", i))
		frame := gdb.Send(fmt.Sprintf("-stack-info-frame"))["payload"].(map[string]interface{})["frame"]

		file := frame.(map[string]interface{})["file"]
		line := frame.(map[string]interface{})["line"]
		function := frame.(map[string]interface{})["func"]

		locals := extractLocals(gdb)
		args := extractArgs(gdb)

		fmt.Printf("%s:%s (%s)\n", file, line, function)
		pretty.Print(locals)
	}
}


func extractLocals(gdb *Gdb) map[string]interface{} {
	result := gdb.Send("-stack-list-locals 1")
	locals := result["payload"].(map[string]interface{})["locals"].([]interface{})
	localsMap := make(map[string]interface{})

	for _, v := range(locals) {
		localVar := v.(map[string]interface{})

		localsMap[localVar["name"].(string)] = localVar["value"]
	}

	return localsMap
}


func extractArgs(gdb *Gdb) []interface {
	result := gdb.Send()
}
