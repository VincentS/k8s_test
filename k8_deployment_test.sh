#! /bin/sh
# This script test if an Kubernetes Cluster can be setup correctly
# After completion the Kubernetes Cluster gets destroyed

set -ex


#DEFINE APPLICATION variables
RETRIES=5
WAITSEC=5


function delete {
    echo "Destroy Service"
    kubectl delete services nginx-service
    command_success

    echo "Destroy Deployment"
    kubectl delete deployment nginx-deployment
    command_success
}

function command_success {
    if [[ $? -ne 0 ]]; then
        echo "Last Command was not successful (Wrong return code)\n"
        exit 1
    fi
}


function checkIfAvailable {
    n=0
    while true; do
        if [[ $n -lt $RETRIES ]]; then
            avail_pods=$(kubectl get deployment nginx-deployment -o jsonpath={.status.availableReplicas})
            if [[ $avail_pods -eq $1 ]]; then
                break
            fi
            n=$[$n+1]
            echo "Check failed. Retry $n of $RETRIES waiting $WAITSEC for retry."
            sleep $WAITSEC
        else
            echo "Creation of Pods failed."
            exit 1
        fi
    done
}


#Clean reamining previous deployments if error
#echo "Cleanup old failed deployments"
#delete

#Setup Deployment
echo "Creating Deployment"
kubectl create -f ./nginx-deployment.yaml
command_success

echo "Waiting $WAITSEC seconds before progressing further"
sleep $WAITSEC

#Create Deployment of Appication
req_pods=$(kubectl get deployment  nginx-deployment -o jsonpath={.status.replicas})

checkIfAvailable $req_pods



#Scale Deployment (Current Pods * 2)

req_pods=$[$req_pods*2]
#echo "${req_pods}"
echo "Scale deployment by doubling number of Replicas"
kubectl scale deployment --replicas=$req_pods nginx-deployment
command_success

echo "Check if Pods are available."
checkIfAvailable $req_pods


#Test Service
echo "Create Service"
kubectl create -f ./nginx_service.yaml
command_success

echo "Test Service"
kubectl get service nginx-service
command_success

#Destroy deployment
echo "Cleanup current deployment / service"
delete
