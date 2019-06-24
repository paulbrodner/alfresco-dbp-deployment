#!/usr/bin/env bash

# create the cluster
eksctl create cluster -f eksctl.yaml --auto-kubeconfig --alb-ingress-access --appmesh-access

# just see if the cluster is responding
eksctl get cluster --name=tcds-1 --region=eu-west-3

# update the config so you can access it with kubectl
aws eks update-kubeconfig --name=tcds-1 --region=eu-west-3
kubectl get nodes

# create roles and services for access
kubectl create sa tiller-sa -n kube-system
kubectl create clusterrolebinding tiller-sa-clusterrole-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller-sa  
helm init --service-account tiller-sa

# for k8 dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl create -f dashboard-admin.yaml
