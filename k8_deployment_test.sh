#! /bin/sh
# This script test if an Kubernetes Cluster can be setup correctly
# After completion the Kubernetes Cluster gets destroyed

set -ex


#DEFINE APPLICATION variables
RETRIES=5
WAITSEC=30

function command_success {
    if [[ $? -ne 0 ]]; then
        echo "Last Command was not successful (Wrong return code)\n"
        exit 1
    fi
}

#Setup Deployment
echo "Creating Deployment"
kubectl create -f ./nginx-deployment.yaml
command_success

echo "Waiting 15 seconds before progressing further"
sleep 15
#Create Deployment of Appication
req_pods=$(kubectl get deployment  nginx-deployment -o jsonpath='{.status.replicas}')


n=0
while true; do
    if [[ $n -lt 5 ]]; then
        avail_pods=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.availableReplicas}')
        if [[ $avail_pods -eq $req_pods ]]; then
            break
        fi
        n=$[$n+1]
        echo "Waiting for $num_pods to be available. Retry $n of 5"
        sleep 5
    else
        echo "Deployment of Pods failed"
        exit 1
    fi
done


#Scale Deployment (Current Pods * 2)

req_pods=$[$req_pods*2]
#echo "${req_pods}"

kubectl scale deployment --replicas=$req_pods nginx-deployment
command_success

n=0
while true; do

    if [[ $n -lt 5 ]]; then
        avail_pods=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.availableReplicas}')
        if [[ $avail_pods -eq $req_pods ]]; then
            break
        fi
        n=$[$n+1]
        echo "Waiting for $num_pods to be available. Retry $n of 5"
        sleep 5
    else
        echo "Creation of Pods failed"
        exit 1
    fi
done



#Test Service
echo "Create Service"
kubectl create -f ./nginx_service.yaml
command_success

echo "Test Service"
kubectl get service nginx-service
command_success

#Destroy deployment
echo "Destroy Service"
kubectl delete services nginx-service
command_success

echo "Destroy Deployment"
kubectl delete deployment nginx-deployment
command_success
