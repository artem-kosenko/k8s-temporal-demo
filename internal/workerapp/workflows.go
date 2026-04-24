package workerapp

import (
	"context"
	"fmt"
	"time"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/workflow"
)

func GreetingWorkflow(ctx workflow.Context, name string) (string, error) {
	options := workflow.ActivityOptions{
		StartToCloseTimeout: 30 * time.Second,
	}
	ctx = workflow.WithActivityOptions(ctx, options)

	var result string
	err := workflow.ExecuteActivity(ctx, GreetingActivity, name).Get(ctx, &result)
	return result, err
}

func GreetingActivity(ctx context.Context, name string) (string, error) {
	info := activity.GetInfo(ctx)
	team := getenv("WORKER_TEAM", "unknown-team")
	environment := getenv("WORKER_ENVIRONMENT", "dev")

	return fmt.Sprintf(
		"hello %s from %s/%s on task queue %s",
		name,
		team,
		environment,
		info.TaskQueue,
	), nil
}

