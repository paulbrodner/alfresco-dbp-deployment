export KOPS_STATE_STORE:=s3://pbrodner

.DEFAULT_GOAL := help

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

ifeq ($(UNAME), Linux)
	OPEN := xdg-open
endif

ifeq ($(UNAME), Darwin)
	OPEN := open
endif

proxy: ## open k8s cluster
	@kubectl proxy &
	@echo Opening K8S Dashboard localy via proxy, click Skip on login page! 	
	$(OPEN) http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default
	@make cluster-get-token

.PHONY: cluster-get-token
cluster-get-token: ## get token to login
	$(eval SECRET_NAME := $(shell kubectl --namespace kube-system get secret | grep kubernetes-dashboard-token| awk '{print $$1}'))	
	kubectl --namespace kube-system describe secret $(SECRET_NAME)

cluster-available: ## show available clusters
	@kubectl config get-contexts

cluster-get-current: ## show current cluster context
	@kubectl config current-context

cluster-set-context: ## set current cluster context
	make cluster-available
	@read -p "Paste here the CLUSTER that you want to setup:" currentCluster && kubectl config use-context $$currentCluster
	
