#!/usr/bin/env bash
# this shell script is checking if all pods within a namespace are available
# pass the NAMESPACE string as argument
# available => value is greater than 0 (does not contain 0)
# this can be extended to take in consideration the replicas

set -eu
TIMEOUT=420 # in seconds
WAIT_INTERVAL=10
COUNTER=0
T0=`date +%s`

get_deployments() {
    local readonly _namespace="$1"    
    deployments=$(kubectl get deployments --namespace ${_namespace} | awk '{print $5}')
    
    COUNTER=$((${COUNTER}+1))
    echo "Check count: ${COUNTER}"        
    if ((${COUNTER} >= ${TIMEOUT}/${WAIT_INTERVAL})) ; then
        T1=`date +%s`
        delta=$((($T1 - $T0)/60))
        echo "Deployed pods in namespace: ${_namespace} didn't start in time (timout is set to ${TIMEOUT} seconds)" 
        echo "Status of deployed Pods:"
        kubectl get deployments --namespace ${_namespace}        
        exit 1
    fi

    if [[ ${deployments} == *0* ]];
    then        
        echo "We still have PODS that are not available (available=0) in [${_namespace}] namespace. Waiting ${WAIT_INTERVAL} seconds..."
        # echo -e `kubectl get deployments --namespace development | grep 0 | awk '{ printf "%s\\n\n",$1 }'`
        if ((${COUNTER} % 3==0)); then
            kubectl get deployments --namespace ${_namespace}
        fi
        sleep ${WAIT_INTERVAL}
        get_deployments ${_namespace}
    else
        echo "All PODS are now available (available>=1) in [${_namespace}] namespace:"
        kubectl get deployments --namespace ${_namespace}
    fi
}

get_deployments $1 || echo "Check running pods!"