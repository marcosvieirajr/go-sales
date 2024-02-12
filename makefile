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

