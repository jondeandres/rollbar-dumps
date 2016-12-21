package main

import (
	"net/http"
	"encoding/json"
	"bytes"
)


func SendPayload(payload map[string]interface{}) {
	jsonStr, _ := json.Marshal(payload)

	url := "https://api.rollbar.com/api/1/item/"
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(jsonStr))
	req.Header.Set("X-Rollbar-Access-Token", ConfigurationAccessToken())

	client := &http.Client{}
	resp, _ := client.Do(req)
	resp.Body.Close()
}
