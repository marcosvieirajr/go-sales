SHELL := /bin/bash

# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"


run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

# # ==============================================================================
# Building containers

# $(shell git rev-parse --short HEAD)
VERSION := 1.0

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.sales-api \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%sZ"` \
		. 


# ==============================================================================
# Running from within k8s/kind

KIND := kindest/node:v1.26.14
KIND_CLUSTER := ardam-cluster

kind-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml

	kubectl config set-context --current --namespace=sales-system

	# kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER)
	# kind load docker-image $(GRAFANA) --name $(KIND_CLUSTER)
	# kind load docker-image $(PROMETHEUS) --name $(KIND_CLUSTER)
	# kind load docker-image $(TEMPO) --name $(KIND_CLUSTER)
	# kind load docker-image $(LOKI) --name $(KIND_CLUSTER)
	# kind load docker-image $(PROMTAIL) --name $(KIND_CLUSTER)

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)
	
kind-load:
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:${VERSION}
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-apply:
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -
	# cat zarf/k8s/base/sales-pod/base-sales.yaml | kubectl apply -f -

kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

kind-status-sales:
	kubectl get pods -o wide --watch

kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go

kind-restart:
	kubectl rollout restart deployment sales

