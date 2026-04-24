package workerapp

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"go.temporal.io/sdk/client"
)

func StartHTTPServer(ctx context.Context, cfg Config, temporalClient client.Client) error {
	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	mux.HandleFunc("/start", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "only POST is allowed", http.StatusMethodNotAllowed)
			return
		}

		name := r.URL.Query().Get("name")
		if name == "" {
			name = "Temporal Demo"
		}

		workflowID := fmt.Sprintf("%s-%d", cfg.WorkerDisplayName, time.Now().UnixNano())
		run, err := temporalClient.ExecuteWorkflow(
			r.Context(),
			client.StartWorkflowOptions{
				ID:        workflowID,
				TaskQueue: cfg.TaskQueue,
			},
			GreetingWorkflow,
			name,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		_ = json.NewEncoder(w).Encode(map[string]string{
			"workflowId": workflowID,
			"runId":      run.GetRunID(),
			"namespace":  cfg.Namespace,
			"taskQueue":  cfg.TaskQueue,
		})
	})

	server := &http.Server{
		Addr:    ":" + cfg.HTTPPort,
		Handler: mux,
	}

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdownCtx)
	}()

	log.Printf("http server listening on :%s", cfg.HTTPPort)
	err := server.ListenAndServe()
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}

