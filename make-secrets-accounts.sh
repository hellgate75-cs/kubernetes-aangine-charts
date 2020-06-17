#!/bin/bash
FOLDER="$(realpath "$(dirname "$0")")"
CD_PATH="$(realpath "$(dirname "$0")")"
function usage() {
	echo "make-secrets-accounts.sh <deploy-env-file>"
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


IFS=' ';for file in $(ls $CD_PATH/config/secrets|xargs echo); do
	secret_file_name="$CD_PATH/config/secrets/$file"
	if [[ $file =~ '.env' ]]; then
		echo "ENV Secret file: $secret_file_name"
		source $secret_file_name
		if [ "" != "${REG_NAME}" ] && [ "" != "${REG_URL}" ] && [ "" != "${REG_USERNAME}" ]  && [ "" != "${REG_PASSWORD}" ]; then
			kubectl $KUBECTL_BASE create secret docker-registry "${REG_NAME}secret" --docker-server="${REG_URL}" --docker-username="${REG_USERNAME}" --docker-password="${REG_PASSWORD}" --docker-email="${REG_EMAIL}" 2> /dev/null
		else
			echo "Insufficient properties in file ${file} -> needed: REG_NAME, REG_URL, REG_USERNAME and REG_PASSWORD"
		fi
		REG_NAME=
		REG_USERNAME=
		REG_PASSWORD=
		REG_EMAIL=
		REG_URL=
	elif [[ $file =~ '.yaml' ]] || [[ $file =~ '.yml' ]]; then
		echo "YAML K8s Secret file: $secret_file_name"
		kubectl $KUBECTL_BASE apply -f $secret_file_name
	else
		echo "Unknown Secret file type: $secret_file_name"
	fi
done
kubectl $KUBECTL_BASE get secrets

#IFS=' ';for file in $(ls $FOLDER/config/serviceaccounts|xargs echo); do
#	sa_file_name="$FOLDER/config/serviceaccounts/$file"
#	if [[ $file =~ '.yaml' ]] || [[ $file =~ '.yml' ]]; then
#		echo "YAML K8s service account: $sa_file_name"
#		kubectl $KUBECTL_BASE apply -f $sa_file_name
#	else
#		echo "Unknown Service Account file type: $sa_file_name"
#	fi
#done
#kubectl $KUBECTL_BASE get serviceaccounts

#IFS=' ';for file in $(ls $CD_PATH/config/storageclasses|xargs echo); do
#	sc_file_name="$CD_PATH/config/storageclasses/$file"
#	if [[ $file =~ '.yaml' ]] || [[ $file =~ '.yml' ]]; then
#		echo "YAML K8s storage class: $sc_file_name"
#		kubectl $KUBECTL_BASE apply -f $sc_file_name
#	else
#		echo "Unknown Storage Class file type: $sc_file_name"
#	fi
#done
#kubectl $KUBECTL_BASE get storageclass
exit 0
