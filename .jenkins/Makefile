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
	DESIREDNAMESPACE:=dev-$(shell whoami)
endif

# the Route53 entry
ifndef DNSZONE
	DNSZONE=$(shell whoami).dev.alfresco.me
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

# only on Jenkins agents execute this (notice that this variable is set in Jenkinsfile)
agent:
	aws eks update-kubeconfig --name=tcds-1 --region=eu-west-3
	helm init	
	kubectl get ns

namespace: ## 1 - create namespace for your cluster	
	@kubectl create namespace $(DESIREDNAMESPACE)	
	helm repo add alfresco-incubator https://kubernetes-charts.alfresco.com/incubator
	helm repo add alfresco-stable https://kubernetes-charts.alfresco.com/stable
	@kubectl create -f $(SECRETS_YAML) --namespace $(DESIREDNAMESPACE)

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
	sleep 10	
	helm delete --purge `helm ls --namespace=$(DESIREDNAMESPACE) | grep $(DESIREDNAMESPACE) | awk {'print $$1'}`
	#kubectl delete ns $(DESIREDNAMESPACE)
	# force delete of the namespace
	kubectl get namespace $(DESIREDNAMESPACE) -o json |jq '.spec = {"finalizers":[]}' >temp.json
	curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$(DESIREDNAMESPACE)/finalize	

proxy: ## open k8s dashboard
	@kubectl proxy &
	@echo Opening K8S Dashboard localy via proxy, click Skip on login page! 
	$(OPEN)  http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/		
	@make get-proxy-token

get-proxy-token: ## get token for login on k8s dashboard
	@$(eval K8S_DASHBOARD_TOKEN := $(shell kubectl -n kube-system get secrets | grep kubernetes-dashboard-token | awk '{print $$1}'))
	@kubectl -n kube-system describe secrets $(K8S_DASHBOARD_TOKEN)	

sed-values:
	@sed -i -e "s/https:/http:/" $(CHART_VALUES)
	@sed -i -e "s/REPLACEME/$(DNSZONE)/" $(CHART_VALUES)
	
get-dbp-deployment-name:
	#sleep 60
	$(eval DBP_DEPLOYMENT_NAME := "$(shell helm ls --namespace $(DESIREDNAMESPACE) | grep alfresco-dbp | awk '{printf $$1}')-nginx-ingress-controller")	

get-ingress: get-dbp-deployment-name ## get load balancer IP		
	$(eval LOAD_BALANCER_IP := $(shell kubectl --namespace $(DESIREDNAMESPACE) get services $(DBP_DEPLOYMENT_NAME) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'))
	@echo The Ingress Load Balancer is found at: $(LOAD_BALANCER_IP)

create-route: get-ingress
	$(shell .scripts/route53.sh --create '*.$(DNSZONE)' $(LOAD_BALANCER_IP))

delete-route: get-ingress
	$(shell .scripts/route53.sh --delete '*.$(DNSZONE)' $(LOAD_BALANCER_IP))

build: namespace deploy	create-route ## all in one - create	
	
cleanup: delete-route destroy ## all in one - destroy
