package main


func main() {
	binary := "/home/jon/rollbar/rollbar-dumps/sample"
	core := "/home/jon/rollbar/rollbar-dumps/core"
	arguments := []string{"-n", "-q", "-i", "mi2", binary, core}

	gdb := NewGdb(arguments)

	BuildPayload(gdb)
}


func RecordInitialResponse(gdb *Gdb) string {
	return gdb.Record()
}
