# deploy DBP from your machine or CI/CD using the same approach
# author: Paul Brodner

CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR:=$(shell dirname $(CURRENT_DIR))

ifeq ($(UNAME), Linux)
	OPEN := xdg-open
endif

ifeq ($(UNAME), Darwin)
	OPEN := open
endif

# this should be the branch name or CI build number
ifndef DESIREDNAMESPACE
	DESIREDNAMESPACE:=development
endif

# the Route53 entry
ifndef DNSZONE
	DNSZONE="$(shell whoami).dev.alfresco.me"
endif

# for development purposes you need to have this secrets.yml file locally created
# see https://github.com/Alfresco/alfresco-dbp-deployment#8-pull-secrets
ifndef SECRETS_YAML
	SECRETS_YAML=secrets.yml
endif

ifndef CHART_VALUES
	CHART_VALUES=$(ROOT_DIR)/charts/incubator/alfresco-dbp/values.yaml
endif

.DEFAULT_GOAL := help
help: ## showing this help message 	
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

update-kubeconfig:
	aws eks update-kubeconfig --name=tcds-1 --region=eu-west-3

namespace: ## 1 - create namespace for your cluster	
	@kubectl create namespace $(DESIREDNAMESPACE)	
	helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator
	helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
	kubectl create -f $(SECRETS_YAML) --namespace $(DESIREDNAMESPACE)

deploy: sed-values ## 2 - deploy	
	# details https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner
	helm install stable/nfs-server-provisioner --namespace $(DESIREDNAMESPACE) \
		--set persistence.enabled=true,persistence.size=21Gi,storageClass.name=$(DESIREDNAMESPACE)
	helm install alfresco-incubator/alfresco-dbp -f $(CHART_VALUES) \
		--set alfresco-infrastructure.persistence.efs.enabled=false \
		--set alfresco-infrastructure.persistence.storageClass.enabled=true \
		--set alfresco-infrastructure.persistence.storageClass.name=$(DESIREDNAMESPACE) \
		--namespace=$(DESIREDNAMESPACE)

destroy: ## cleanup after deploy
	@kubectl delete --all pods --force --grace-period=0 --namespace=$(DESIREDNAMESPACE) && \
	@sleep 10 && \
	@kubectl delete --all pods --force --grace-period=0 --namespace=$(DESIREDNAMESPACE) && \
	helm delete --purge `helm ls --namespace=$(DESIREDNAMESPACE) | grep $(DESIREDNAMESPACE) | awk {'print $$1'}` && \
	kubectl delete ns $(DESIREDNAMESPACE)

proxy: ## open k8s dashboard
	@kubectl proxy &
	@echo Opening K8S Dashboard localy via proxy, click Skip on login page! 
	$(OPEN)  http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/		
	@make get-proxy-token

get-proxy-token: ## get toke for login on k8s dashboard
	@$(eval K8S_DASHBOARD_TOKEN := $(shell kubectl -n kube-system get secrets | grep kubernetes-dashboard-token | awk '{print $$1}'))
	@kubectl -n kube-system describe secrets $(K8S_DASHBOARD_TOKEN)	

sed-values:
	@sed -i -e "s/https:/http:/" $(CHART_VALUES)
	@sed -i -e "s/REPLACEME/$(DNSZONE)/" $(CHART_VALUES)
	

get-ingress: get-dbp-deployment-name ## display Load Balancer IP	
	$(eval LOAD_BALANCER_IP := $(shell kubectl --namespace $(DESIREDNAMESPACE) get services $(DBP_DEPLOYMENT_NAME) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'))
	@echo The Ingress Load Balancer is found at: $(LOAD_BALANCER_IP)

get-dbp-deployment-name:
	$(eval DBP_DEPLOYMENT_NAME := "$(shell helm ls --namespace $(DESIREDNAMESPACE) | grep alfresco-dbp | awk '{printf $$1}')-nginx-ingress-controller")	