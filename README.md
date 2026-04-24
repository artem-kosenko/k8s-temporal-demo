# Local Temporal on Colima Demo

This repository is a GitOps-ready monorepo for running a local, production-style Temporal setup on a Kubernetes cluster on macOS Apple Silicon.

It is built around:

- Colima with embedded k3s for the local Kubernetes cluster
- Argo CD for GitOps reconciliation
- The official Temporal Helm chart for the Temporal platform
- The official Temporal Worker Controller charts for worker lifecycle management
- Namespace isolation for multiple teams and environments
- Sample Go-based Temporal workers that can be built locally, imported into Colima k3s, and later published from GitHub

## What is included

- `scripts/` to start and stop Colima, bootstrap Argo CD, build local images, and port-forward UIs
- `gitops/` for the Argo CD root app, projects, and team environment ApplicationSet
- `platform/` for shared platform manifests and values
- `charts/team-worker/` for a reusable team worker chart
- `cmd/team-a-worker/` and `cmd/team-b-worker/` as sample worker services
- `.github/workflows/` scaffolding for CI validation and image publishing

## Repository layout

```text
.
├── .github/workflows
├── charts/team-worker
├── cmd
│   ├── team-a-worker
│   └── team-b-worker
├── gitops
│   ├── bootstrap
│   └── root
├── internal/workerapp
├── platform
│   ├── bootstrap
│   ├── core
│   └── values
└── scripts
```

## Local architecture

- `argocd` namespace hosts Argo CD.
- `temporal-system` namespace hosts PostgreSQL, Temporal, and the Temporal Worker Controller.
- Each team environment gets its own Kubernetes namespace and its own Temporal namespace:
  - `team-a-dev`
  - `team-a-stage`
  - `team-b-dev`
  - `team-b-stage`

This keeps worker rollouts, service accounts, and operational resources isolated per team and environment while still sharing one local Temporal control plane.

## Prerequisites

Install these on your Mac before running the scripts:

- `colima`
- `kubectl`
- `helm`
- `docker` CLI
- `git`

Optional but useful:

- `argocd`
- `temporal`
- `go`

`helm` is required by `scripts/bootstrap-argocd.sh`. `go` is only required if you want to build or test the sample workers locally outside container builds.

## Quick start

1. Copy `.env.example` to `.env` and update the values you care about.
2. Start the cluster:

```bash
make start
```

This start step also generates or refreshes `~/.kube/config` and selects the `colima-<profile>` context for the active Colima profile.

3. Build the sample worker images and import them into Colima k3s:

```bash
make build-images
```

4. Set `GITOPS_REPO_URL` in `.env`, then render the GitOps app manifests:

```bash
make render-gitops
```

5. Push this repo to GitHub.
6. Bootstrap Argo CD and the root app:

```bash
make bootstrap
```

7. Port-forward the UIs:

```bash
make port-forward
```

## Notes about GitOps bootstrapping

Argo CD needs a reachable Git repository. Because of that, the bootstrap flow assumes this repository is pushed to GitHub or another Git host first.

Run `make render-gitops` before the first push so the child Argo CD applications point at the real repository URL and revision.

If `scripts/bootstrap-argocd.sh` cannot detect a Git remote and `GITOPS_REPO_URL` is not set, it will still install Argo CD but it will stop before creating the root application.

## Colima notes

This repo assumes Colima is started with Kubernetes enabled, using the Docker runtime and embedded k3s.

The local image workflow is:

1. build the worker image with `docker build`
2. export it with `docker save`
3. import it into Colima's k3s containerd with `sudo k3s ctr images import`

That import step is important because the k3s node runtime does not reliably consume the host Docker image cache directly.

## Platform design choices

- PostgreSQL is deployed as a simple in-cluster StatefulSet for the demo.
- Temporal is installed from the official Helm repository and configured to use PostgreSQL for default and visibility stores.
- Temporal namespaces are created by the Temporal chart itself to keep team and env setup declarative.
- Temporal Worker Controller is installed from its official OCI charts, with CRDs separated from the controller as recommended upstream.
- Team workloads are deployed through an Argo CD `ApplicationSet` so adding a new team environment becomes a list entry change instead of manual duplication.

## Sample worker behavior

Each sample worker:

- connects to Temporal using environment variables
- registers a simple greeting workflow and activity
- exposes:
  - `GET /healthz`
  - `POST /start?name=Alice`

The HTTP endpoint is there to make the demo easier to poke locally through `kubectl port-forward`.

## GitHub flow

The included GitHub Actions are starter scaffolding:

- `validate.yaml` checks the repository shape
- `publish-workers.yaml` builds and publishes worker images to GHCR

For a real flow, you would typically add:

- image tag updates in the chart values files
- pull-request based promotion between environments
- Argo CD sync windows or approval gates for non-dev environments

## Verified upstream references

I used current upstream references on April 24, 2026 for:

- Colima CLI behavior was aligned to the locally installed `colima 0.10.1`
- Argo CD Helm chart: [Artifact Hub](https://artifacthub.io/packages/helm/argo/argo-cd)
- Temporal Helm chart repo and docs: [temporalio/helm-charts](https://github.com/temporalio/helm-charts)
- Temporal Worker Controller install and rollout docs: [temporalio/temporal-worker-controller](https://github.com/temporalio/temporal-worker-controller)
- Temporal Go SDK module: [pkg.go.dev/go.temporal.io/sdk](https://pkg.go.dev/go.temporal.io/sdk)
