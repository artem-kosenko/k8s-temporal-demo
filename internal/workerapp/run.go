package workerapp

import (
	"context"
	"log"
	"os/signal"
	"syscall"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"
)

func Run(defaultNamespace string) error {
	cfg := LoadConfig(defaultNamespace)

	c, err := client.Dial(client.Options{
		HostPort:  cfg.HostPort,
		Namespace: cfg.Namespace,
	})
	if err != nil {
		return err
	}
	defer c.Close()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		if err := StartHTTPServer(ctx, cfg, c); err != nil {
			log.Printf("http server stopped with error: %v", err)
			stop()
		}
	}()

	w := worker.New(c, cfg.TaskQueue, worker.Options{})
	w.RegisterWorkflow(GreetingWorkflow)
	w.RegisterActivity(GreetingActivity)

	log.Printf(
		"starting worker deployment=%s namespace=%s task_queue=%s",
		cfg.WorkerDisplayName,
		cfg.Namespace,
		cfg.TaskQueue,
	)

	return w.Run(worker.InterruptCh())
}

