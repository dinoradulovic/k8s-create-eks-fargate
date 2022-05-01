# EKS Cluster Management

This repo is part of the bundle. 

| PARAM | NOTES |
| ------ | ------ |
| **k8s-create-eks-fargate** | **scripts to create Kubernetes cluster on EKS with Fargate** |
| k8s-create-flux-cd | scripts to setup GitOps with FluxCD |
| k8s-microservice-one | first sample microservice to be deployed into cluster |
| k8s-microservice-two | second sample microservice to be deployed into cluster |
| k8s-microservices-app-infra | infrastructure manifest files for two microservices app |

Contains scripts for creating and deleting a cluster on AWS EKS. 

## Creating EKS Cluster

To create EKS Cluster run:
```sh
./eks-create.sh
```

This will:
- Create EKS Cluster using ***eksctl***
- Create ***AWS Load Balancer Controller*** and 
- Deploy the ***Kubernetes Dashboard***


Edit Cluster Configuration in `eksctl-cluster.yaml` file. 


> Make sure you add all the Namespaces that you want to run on Fargate. 


#### Access the Kubernetes Dashboard
##### Start the proxy 
This will start the proxy, listen on port 8080, listen on all interfaces, and will disable the filtering of non-localhost requests. This command will continue to run in the background of the current terminal’s session.
`kubectl proxy --port=8080 --address=0.0.0.0 --disable-filter=true &`

##### Access the Dasboard
http://localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default

##### Get the authentication token
`aws eks get-token --cluster-name test-cluster --region us-west-1`




# Delete the Cluster

> If you have active services in your cluster that are associated with a load 
> balancer, you must delete those services before deleting the cluster so that
> the load balancers are deleted properly.
> Otherwise, you can have orphaned resources in your VPC that prevent you from 
> being able to delete the VPC.
> https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html

Delete All: 
```sh
kubectl delete ingress production-ingress-prod -n production &&
kubectl delete ingress staging-ingres-staging -n staging &&

kubectl delete deployment microservice-one-deployment-name-staging -n staging &&
kubectl delete deployment microservice-two-deployment-name-staging -n staging &&
kubectl delete deployment microservice-one-deployment-name-prod -n production &&
kubectl delete deployment microservice-two-deployment-name-prod -n production &&

kubectl delete service microservice-one-service-name-prod -n production &&
kubectl delete service microservice-two-service-name-prod -n production &&
kubectl delete service microservice-one-service-name-staging -n staging &&
kubectl delete service microservice-two-service-name-staging -n staging &&

kubectl delete secret microservice-one-secret-name-prod -n production && 
kubectl delete secret microservice-one-secret-name-staging -n staging
```
