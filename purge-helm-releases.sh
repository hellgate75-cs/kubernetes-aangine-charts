#!/bin/bash
CD_PATH="$(realpath "$(dirname "$0")")"

function usage() {
	echo "purge-helm-releases.sh <deploy-env-file>"
	echo "  <deploy-env-file> (Mandatory)   Env file produced by a chart deploy with suspension"
	echo "                      			it contains helm-ns (related to required namespace"
}

ARG="$1"

if [ $# -lt 1 ]; then
	echo "ERROR: Insufficient arguments ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi
if [ "-h" = "$ARG" ] || [ "--help" = "$1" ]; then
	echo "Usage:"
	echo -e "$(usage)"
	exit 0
fi
if [ "" = "$ARG" ]; then
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
RELEASES_LIST="$(helm $HELM_BASE list|grep -v NAME)"
if [ "" != "$RELEASES_LIST" ]; then
	echo "$RELEASES_LIST"|awk 'BEGIN {FS=OFS=" "}{print $1}'|xargs helm --kubeconfig=$KUBECONFIG --namespace=$NAMESPACE delete
else
	echo "No releases to purge ..."
fi


bash -c "$CD_PATH/delete-secrets-accounts.sh $1"
RES="$?"
if [ "0" != "$RES" ]; then
	echo "Errors during destroy of secrets, service accounts, etc...: exit code $RES"
	echo "Abort!!"
	exit $RES
fi

exit 0
