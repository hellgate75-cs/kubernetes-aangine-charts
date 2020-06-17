#!/bin/bash
FOLDER="$(realpath "$(dirname "$0")")"
CD_PATH="$(realpath "$(dirname "$0")")"
function usage() {
	echo "delete-secrets-accounts.sh <deploy-env-file>"
	echo "  <deploy-env-file> (Mandatory)   Env file produced by a chart deploy with suspension"
	echo "                      			it contains helm-ns (related to required namespace"
}
if [ $# -lt 1 ]; then
	echo "ERROR: Insufficient arguments ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi
if [ "-h" = "$1" ] || [ "--help" = "$1" ]; then
	echo "Usage:"
	echo -e "$(usage)"
	exit 0
fi
if [ "" = "$1" ]; then
	echo "ERROR: Missing source infra/project/namespace environment file..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
else
	source $1
	eval "$(cat $1)"
fi

if [ "" = "$(kubectl $KUBECTL_BASE --help 2> /dev/null)" ] || [ "" = "$KUBECONFIG" ] || [ "" = "$NAMESPACE" ]; then
	echo "ERROR: Please source your infra/project/namespace environment as first..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1	
fi

echo "Deleting Secrets"
kubectl $KUBECTL_BASE get secrets|grep -v NAME|awk 'BEGIN {FS=OFS=" "}{print $1}'|xargs kubectl $KUBECTL_BASE delete secrets
kubectl $KUBECTL_BASE get secrets

#echo "Deleting Service accounts"
#kubectl $KUBECTL_BASE get serviceaccounts|grep -v NAME|awk 'BEGIN {FS=OFS=" "}{print $1}'|xargs kubectl $KUBECTL_BASE delete serviceaccounts
kubectl $KUBECTL_BASE get serviceaccounts

#echo "Deleting Storage Classes"
#kubectl $KUBECTL_BASE get storageclass|grep -v NAME|awk 'BEGIN {FS=OFS=" "}{print $1}'|xargs kubectl $KUBECTL_BASE delete storageclass
kubectl $KUBECTL_BASE get storageclass

exit 0
