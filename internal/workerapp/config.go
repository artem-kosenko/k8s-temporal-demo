package workerapp

import (
	"fmt"
	"os"
)

type Config struct {
	HostPort          string
	Namespace         string
	TaskQueue         string
	HTTPPort          string
	Team              string
	Environment       string
	WorkerDisplayName string
}

func LoadConfig(defaultNamespace string) Config {
	team := getenv("WORKER_TEAM", "unknown-team")
	environment := getenv("WORKER_ENVIRONMENT", "dev")
	namespace := getenv("TEMPORAL_NAMESPACE", defaultNamespace)

	return Config{
		HostPort:          getenv("TEMPORAL_ADDRESS", "temporal-frontend.temporal-system.svc.cluster.local:7233"),
		Namespace:         namespace,
		TaskQueue:         getenv("TEMPORAL_TASK_QUEUE", fmt.Sprintf("%s-%s-greetings", team, environment)),
		HTTPPort:          getenv("HTTP_PORT", "8080"),
		Team:              team,
		Environment:       environment,
		WorkerDisplayName: getenv("TEMPORAL_DEPLOYMENT_NAME", fmt.Sprintf("%s-%s-worker", team, environment)),
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

