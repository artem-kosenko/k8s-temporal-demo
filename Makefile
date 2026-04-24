SHELL := /bin/zsh

.PHONY: help start stop bootstrap build-images port-forward render-gitops

help:
	@printf "Targets:\n"
	@printf "  make start          Start local Minikube cluster\n"
	@printf "  make stop           Stop or delete local Minikube cluster\n"
	@printf "  make render-gitops  Render repo URL and revision into GitOps app manifests\n"
	@printf "  make bootstrap      Install Argo CD and bootstrap the root app\n"
	@printf "  make build-images   Build sample worker images into Minikube\n"
	@printf "  make port-forward   Forward Argo CD and Temporal UIs locally\n"

start:
	./scripts/start-cluster.sh

stop:
	./scripts/stop-cluster.sh

render-gitops:
	./scripts/render-gitops.sh

bootstrap:
	./scripts/bootstrap-argocd.sh

build-images:
	./scripts/build-images.sh

port-forward:
	./scripts/port-forward.sh
