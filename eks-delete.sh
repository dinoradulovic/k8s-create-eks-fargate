#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. $SCRIPT_DIR/.env

function delete_aws_load_balancer_controller {
  echo "*** Deleting AWS Load Balancer Controller ***"

  echo "Helm Deleting AWS Load Balancer Controller"
  helm uninstall aws-load-balancer-controller -n kube-system

  echo "Deleting IAM Role and ServiceAccount..."
  export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query "Account")
  
  eksctl delete iamserviceaccount \
    --region $CLUSTER_REGION \
    --cluster $CLUSTER_NAME \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --wait

  echo "Deleting IAM Policy..."
  aws iam delete-policy \
    --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy

  echo "Deleting CRDs"
  kubectl delete -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
}

function delete_cluster {
  echo "Deleting EKS cluster:" $CLUSTER_NAME
  eksctl delete cluster --name $CLUSTER_NAME --region $CLUSTER_REGION --wait
}

delete_aws_load_balancer_controller
delete_cluster
