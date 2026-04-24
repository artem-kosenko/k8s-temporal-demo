package main

import (
	"log"

	"github.com/artem-kosenko/k8s-temporal-demo/internal/workerapp"
)

func main() {
	if err := workerapp.Run("team-a-dev"); err != nil {
		log.Fatal(err)
	}
}

