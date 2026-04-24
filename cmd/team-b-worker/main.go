package main

import (
	"log"

	"github.com/your-org/k8s-temporal-demo/internal/workerapp"
)

func main() {
	if err := workerapp.Run("team-b-dev"); err != nil {
		log.Fatal(err)
	}
}

