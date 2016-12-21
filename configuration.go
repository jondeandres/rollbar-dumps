package main

import (
	"os"
)

func ConfigurationAccessToken() string {
	value, _ := os.LookupEnv("ROLLBAR_ACCESS_TOKEN")

	return value
}

func ConfigurationNotifierVersion() string {
	return "0.0.1"
}
