CLUSTER_NAME=localdev
REGISTRY_IMAGE=registry:2
REGISTRY_HOST=registry.local
REGISTRY_PORT=5000
REGISTRY_VOLUME=local_registry_volume
DEFAULT_REPO="$(REGISTRY_HOST):$(REGISTRY_PORT)"

##############################
# for k3d cluster
.PHONY: create
create: ## k3d cluster create
	k3d cluster create $(CLUSTER_NAME) \
		--volume "$(PWD)/registry/registries.yaml:/etc/rancher/k3s/registries.yaml"
	docker volume create $(REGISTRY_VOLUME)
	docker container run -d \
		--net k3d-$(CLUSTER_NAME) \
		--name $(REGISTRY_HOST) \
		-v $(REGISTRY_VOLUME):/var/lib/registry \
		--restart always \
		-p $(REGISTRY_PORT):$(REGISTRY_PORT) \
		$(REGISTRY_IMAGE)

.PHONY: start
start: ## k3d cluster start
	k3d cluster start $(CLUSTER_NAME)

.PHONY: down
down: ## k3d cluster stop
	k3d cluster stop $(CLUSTER_NAME)

.PHONY: destroy
destroy: ## k3d cluster delete
	docker stop $(REGISTRY_HOST)
	docker rm $(REGISTRY_HOST)
	docker volume rm $(REGISTRY_VOLUME)
	k3d cluster delete $(CLUSTER_NAME)

##############################
# for app
.PHONY: dev
dev: ## skaffold dev
	skaffold dev --port-forward --default-repo $(DEFAULT_REPO)

.PHONY: help
.DEFAULT_GOAL := help
help: ## HELP
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'