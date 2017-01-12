package main

import (
	"time"
	"fmt"
	"strconv"
)


func BuildPayload(gdb *Gdb) {
	gdb.Start()

	depth, _ := strconv.ParseInt(gdb.Send("-stack-info-depth")["payload"].(map[string]interface{})["depth"].(string), 10, 64)

	frames := make([]map[string]interface{}, depth)

	for frameNumber := depth - 1; frameNumber >= 0; frameNumber-- {
		gdb.Send(fmt.Sprintf("-stack-select-frame %d", frameNumber))
		frame := gdb.Send(fmt.Sprintf("-stack-info-frame"))["payload"].(map[string]interface{})["frame"]

		file := frame.(map[string]interface{})["file"]
		line := frame.(map[string]interface{})["line"]
		function := frame.(map[string]interface{})["func"]

		locals := extractLocals(gdb)
		args := extractArgs(gdb, frameNumber)

		frames[frameNumber] = map[string]interface{}{
			"filename": file,
			"lineno": line,
			"method": function,
			"locals": locals,
			"args": args,
		}
	}

	payload := map[string]interface{}{
		"access_token": ConfigurationAccessToken(),
		"data": map[string]interface{}{
			"timestamp": time.Now().Unix(),
			"environment": "development",
			"level": "error",
			"language": "c",
			"server": map[string]interface{}{
				"host": "my-host",
			},
			"notifier": map[string]interface{}{
				"name": "rollbar-dumps",
				"version": ConfigurationNotifierVersion(),
			},
			"body": map[string]interface{}{
				"trace": map[string]interface{}{
					"frames": frames,
					"exception": map[string]interface{}{
						"class": "MyError",
						"message": "The error message",
					},
				},
			},
		},
	}

	SendPayload(payload)
}


func extractLocals(gdb *Gdb) map[string]interface{} {
	gdbResult := gdb.Send("-stack-list-locals 1")
	locals := gdbResult["payload"].(map[string]interface{})["locals"].([]interface{})
	localsMap := make(map[string]interface{})

	for _, v := range(locals) {
		localVar := v.(map[string]interface{})

		localsMap[localVar["name"].(string)] = localVar["value"]
	}

	return localsMap
}


func extractArgs(gdb *Gdb, frameNumber int64) []interface{} {
	gdbResult := gdb.Send(fmt.Sprintf("-stack-list-arguments 1 %d %d", frameNumber, frameNumber))
	payload := gdbResult["payload"].(map[string]interface{})
	args := payload["stack-args"].([]interface{})[0].(
		map[string]interface{})["frame"].(
			map[string]interface{})["args"].(
				[]interface{})

	result := make([]interface{}, len(args))

	for index, arg := range(args) {
		result[index] = arg.(map[string]interface{})["value"]
	}

	return result
}
