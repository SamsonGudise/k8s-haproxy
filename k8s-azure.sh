KUBEAPI=https://$2
NATIVE_CLIENT_ID=
TENANT_ID=
WEBAPI_CLIENT_ID=
CLUSTER_NAME=$2
USERNAME=$1
echo 
if [ $# -ne 2 ]; then
    echo "create-azureAD-kubeconfig.sh <username> <api-endpoint>"
    exit 1
fi

kubectl config set-cluster ${CLUSTER_NAME} --server=${KUBEAPI} --insecure-skip-tls-verify
kubectl config set-credentials ${USERNAME} --auth-provider=azure --auth-provider-arg=environment=AzurePublicCloud --auth-provider-arg=client-id=${NATIVE_CLIENT_ID} --auth-provider-arg=tenant-id=${TENANT_ID} --auth-provider-arg=apiserver-id=${WEBAPI_CLIENT_ID}
kubectl config set-context ${CLUSTER_NAME} --cluster=${CLUSTER_NAME} --user=${USERNAME}
kubectl config use-context ${CLUSTER_NAME}
kubectl get pods
