#!/bin/bash

###################################################################
#Script Name	  : EKS Create
#Description	  : Creates cluster, aws load balancer controller and dashboard on AWS EKS
#Args         	: None
#Author       	: Dino Radulovic
#Email         	: dino.radu@gmail.com
###################################################################

#######################################
# Creates GitHub repository and commits the flux manifests to the master branch.
# Then it configures the target cluster to synchronize with the repository.
# Globals:
#   AWS_PROFILE - Needs to be exported for eksctl
#   CLUSTER_NAME - Name of the cluster
#   CLUSTER_REGION - AWS region for cluster to be created in
#   LBC_VERSION - AWS Load Balancer Controller version
#   DASHBOARD_VERSION - K8S Dasboard Version
# Arguments:
#   None
#######################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. $SCRIPT_DIR/.env

export AWS_PAGER="" # https://stackoverflow.com/questions/60122188/how-to-turn-off-the-pager-for-aws-cli-return-value

function create_eks {
  echo "*** Using eksctl to create EKS cluster:" $CLUSTER_NAME "***"
  eksctl create cluster -f $SCRIPT_DIR/eksctl-cluster.yaml
}

function create_aws_load_balancer_controller {
  echo "*** Creating AWS Load Balancer Controller ***"

  echo "Downloading IAM Policy..."
  curl -o $SCRIPT_DIR/iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json

  echo "Creating IAM Policy..."
  aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://$SCRIPT_DIR/iam_policy.json

  echo "Creating Role and Service Account..."
  export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query "Account")

  eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --region $CLUSTER_REGION \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --approve

  echo "Creating CRDs..."
  kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

  echo "Helm Charts add..."
  helm repo add eks https://aws.github.io/eks-charts

  echo "Helm Update..."
  helm repo update

  echo "Getting VPC "
  export VPC_ID=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --region $CLUSTER_REGION \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)

  echo "Helm Install AWS Load Balancer Controller"
  helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set image.tag=${LBC_VERSION} \
    --set region=${CLUSTER_REGION} \
    --set vpcId=${VPC_ID}

  # # echo "Verify Controller Has Been Installed"
  # # kubectl get deployment -n kube-system aws-load-balancer-controller
}

function deploy_k8s_dashboard {
  echo "*** Deploy Kubernetes Dashboard ***"

  echo "Deploying Dashboard..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
}

create_eks
create_aws_load_balancer_controller
deploy_k8s_dashboard
