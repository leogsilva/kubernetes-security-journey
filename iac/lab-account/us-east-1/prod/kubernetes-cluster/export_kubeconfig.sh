#!/bin/bash

set -x

cd "$(dirname "$0")"


TF_OUTPUT="$(yes | terragrunt output-all -json | jq -s add )"
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r .cluster_name.value)"
STATE="s3://$(echo ${TF_OUTPUT} | jq -r .kops_s3_bucket_name.value)"

kops export kubecfg ${CLUSTER_NAME} --state ${STATE} --kubeconfig ./.kube

SERVER=$(kubectl config view --kubeconfig .kube -o jsonpath='{..clusters[0].cluster.server}')
dig +short $(basename ${SERVER})

# Path to your hosts file
hostsFile="/etc/hosts"

# Default IP address for host
ip="$2"

# Hostname to add/remove.
hostname="$3"

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

remove() {
    if [ -n "$(grep -p "[[:space:]]$hostname" /etc/hosts)" ]; then
        echo "$hostname found in $hostsFile. Removing now...";
        try sudo sed -ie "/[[:space:]]$hostname/d" "$hostsFile";
    else
        yell "$hostname was not found in $hostsFile";
    fi
}

add() {
    if [ -n "$(grep -p "[[:space:]]$hostname" /etc/hosts)" ]; then
        yell "$hostname, already exists: $(grep $hostname $hostsFile)";
    else
        echo "Adding $hostname to $hostsFile...";
        try printf "%s\t%s\n" "$ip" "$hostname" | sudo tee -a "$hostsFile" > /dev/null;

        if [ -n "$(grep $hostname /etc/hosts)" ]; then
            echo "$hostname was added succesfully:";
            echo "$(grep $hostname /etc/hosts)";
        else
            die "Failed to add $hostname";
        fi
    fi
}

for i in `dig +short $(basename ${SERVER})`; do 
  hostname="api.${CLUSTER_NAME}"
  ip=$i
  remove
  add 
done

# Update .kube configuration
kubectl config set-cluster journey.dev.local --server=https://api.journey.dev.local --kubeconfig .kube
