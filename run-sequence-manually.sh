#!/bin/bash
FOLDER="$(realpath "$(dirname "$0")")"
CD_PATH="$(realpath "$(dirname "$0")")"
function usage() {
	echo "run-sequence-manually.sh <deploy-env-file> <variables-file>"
	echo "  <deploy-env-file> (Mandatory)   Env file produced by a chart deploy with suspension"
	echo "                      			it contains helm $HELM_BASE (related to required namespace"
	echo "  <variables-file> (Mandatory)   	File that contains variable for charts"
	echo "  <infrastructure> (Optional)   	Default: aangine, optional aangine-db"
	echo "  <node-hostname> (Optional)   	Selected K8s node hostname"
	echo "  <archive-ref> (Optional)   		S3 MongoDb Archive url"
}
TIMEOUT_1=750
TIMEOUT_2=300
TIMEOUT_3=60
TIMEOUT_4=180

if [ "-h" = "$1" ] || [ "--help" = "$1" ]; then
	echo "Usage:"
	echo -e "$(usage)"
	exit 0
fi

if [ "" = "$1" ]; then
	echo "Please specify environment file ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

if [ "" = "$2" ]; then
	echo "Please specify an Helm variables file ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

if [ ! -e "$1" ]; then
	echo "Environment file $1 doesn't exists ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

if [ ! -e "$2" ]; then
	echo "Helm Variables file $2 doesn't exists ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

ENV_FILE="$1"
VARS_FILE="$2"
ENV_VARS="$(cat $1)"
ARCH="$3"
HOSTNAME="$4"
ARCHIVE="$5"
CERTFILE="$6"
CONNECT_TO="$7"
ENABLE_JAEGER="$8"


if [ "" = "$ENABLE_JEAGER" ]; then
	ENABLE_JEAGER="false"
fi

if [ "true" != "$ENABLE_JEAGER" ] && [ "false" != "$ENABLE_JEAGER" ]; then
	ENABLE_JEAGER="false"
fi


echo "Parameters: [$@]"


if [ "" = "$ARCH" ]; then
	ARCH="aangine"
fi

SSH_FOLDER="aangine"

if [ "aangine" != "$ARCH" ] && [ "aangine-db" != "$ARCH" ]; then
	echo "Architecture: $ARCH unknown ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

echo " "
echo " "
echo "Summary:"
echo "Environmet file: $ENV_FILE"
echo "Helm Variables file: $VARS_FILE"
echo "Required architecture: $ARCH"
echo "Hostname: $HOSTNAME"
echo "File Archive: $ARCHIVE"
echo "SSH Certificate file: $CERTFILE"
echo "SSH User/Host: $CONNECT_TO"
echo "Enable Jaeger: $ENABLE_JAEGER"

echo " "
echo " "

echo "Using environment file: $ENV_FILE"

echo "Using Helm variables file: $VARS_FILE"

source $ENV_FILE

eval "$ENV_VARS"

echo " "
echo "KUBECONFIG=$KUBECONFIG"
echo "Kubernetes namespaces:"
kubectl $KUBECTL_BASE get ns
echo " "

function getReleasePod() {
	source $ENV_FILE
	eval "$ENV_VARS"

	POD_NAME="$( kubectl $KUBECTL_BASE get pods 2> /dev/null|grep $1|grep -v -i terminating|tail -1|awk 'BEGIN {FS=OFS=" "}{print $1}')"
	IDX=0
	while [ "" = "$POD_NAME" ] && [ $IDX -lt 26 ]; do
		sleep 10
		let IDX=IDX+1
		POD_NAME="$( kubectl $KUBECTL_BASE get pods 2> /dev/null|grep $1|tail -1|awk 'BEGIN {FS=OFS=" "}{print $1}')"
	done
	echo "${POD_NAME}"
}

function getReleaseEntity() {
	source $ENV_FILE
	eval "$ENV_VARS"

	echo "$( kubectl $KUBECTL_BASE get $1 2> /dev/null|grep $1|tail -1|awk 'BEGIN {FS=OFS=" "}{print $1}')"
}

function isReleaseRunning() {
	source $ENV_FILE
	eval "$ENV_VARS"

	POD_NAME="$1"
	if [ "" = "$( kubectl $KUBECTL_BASE get pods 2> /dev/null|grep "$POD_NAME"|grep -i "running")" ]; then
		echo "false"
	else
		echo "true"
	fi
}


if [ "" = "$(which yq)" ]; then
	if [ "" != "$(which pip)" ]; then
		pip install yq
	fi
fi
CONFIG_ENABLED="true"
MOCKED_DATA_ENABLED="true"
SERVICE_ACCOUNT_ENABLED="true"
if [ "" != "$(which yq)" ]; then
	CONFIG_ENABLED="$(cat $2 | yq r - 'services.addson_config.create')"
	MOCKED_DATA_ENABLED="$(cat $2 | yq r - 'services.addson_mockup_data.create')"
	SERVICE_ACCOUNT_ENABLED="$(cat $2 | yq r - 'services.service_account.create')"
fi
if [ "" = "$CONFIG_ENABLED" ]; then
	CONFIG_ENABLED="false"
fi
if [ "" = "$MOCKED_DATA_ENABLED" ]; then
	MOCKED_DATA_ENABLED="false"
fi
if [ "" = "$SERVICE_ACCOUNT_ENABLED" ]; then
	SERVICE_ACCOUNT_ENABLED="false"
fi

bash -c "$CD_PATH/make-secrets-accounts.sh $ENV_FILE"
RES="$?"
if [ "0" != "$RES" ]; then
	echo "Errors during creation of secrets, service accounts, etc...: exit code $RES"
	echo "Abort!!"
	exit $RES
fi

ENVIRONMENT_SETTINGS=""

function checkAndMakeSetter() {
	source $ENV_FILE
	eval "$ENV_VARS"
	sleep 5
	RELEASE_NAME="$1"
	TIMEOUT=$2
	SETTER_VAR="$3"
	echo "Looking for POD name for release: $RELEASE_NAME"
	POD_NAME="$(getReleasePod "$RELEASE_NAME")"
	echo "Found POD : $POD_NAME"
	if [ "" = "$POD_NAME" ]; then
		echo "No POD Found for RELEASE: $RELEASE_NAME"
		exit 1
	fi
	echo "Checking POD $POD_NAME is Running ..."
	RUNNING="$(isReleaseRunning "$RELEASE_NAME")"
	echo "Found POD : $POD_NAME, ANSWER: $RUNNING"
	COUNTER=0
	while [ "true" != "$RUNNING" ] && [ $COUNTER -lt $TIMEOUT ]; do
		sleep 10
		let COUNTER=COUNTER+10
		RUNNING="$(isReleaseRunning "$RELEASE_NAME")"
		echo "Found POD : $POD_NAME, ANSWER: $RUNNING"
	done
	if [ "true" = "$RUNNING" ]; then
		IP="$(kubectl $KUBECTL_BASE get pod $POD_NAME -o jsonpath='{.status.podIP}')"
		if [ "" != "$IP" ]; then
			echo "Running pod: $POD_NAME on IP: $IP"
		fi
#		if [ "" != "$SETTER_VAR" ]; then
#			ENVIRONMENT_SETTINGS="$ENVIRONMENT_SETTINGS --set $SETTER_VAR=$IP"
#		fi
	fi
	echo "Extra Environment Settings: <${ENVIRONMENT_SETTINGS}>"
}

function checkEntityCreation() {
	source $ENV_FILE
	eval "$ENV_VARS"
	RELEASE_NAME="$1"
	ENTITY_TYPE="$2"
	TIMEOUT=$3
	ENTITY_NAME="$(getReleaseEntity "$ENTITY_TYPE" "$RELEASE_NAME")"
	COUNTER=0
	while [ "true" != "$ENTITY_NAME" ] && [ $COUNTER -lt $TIMEOUT ]; do
		sleep 10
		let COUNTER=COUNTER+10
		ENTITY_NAME="$(getReleaseEntity "$ENTITY_TYPE" "$RELEASE_NAME")"
	done
}

function getChartVersion() {
	source $ENV_FILE
	eval "$ENV_VARS"
	echo "$(helm $HELM_BASE show chart $1|yq  r - 'version')"
}



#services.redisNodeIp
# docker-machine.exe ssh aangine-rancher-worker-node-1 "sudo rm -Rf /mnt/*"
# ./run-sequence-manually.sh  /c/Users/Fabrizio/workspaces/aangine-workspace/kubernetes-docker-machine/aangine-aangine-1-kubernetes-env-deploy-config.env ./global-linod-vars-namespace-1.yaml > ./install-aangine-aangine-1-kubernetes-env-manually.log &
# tail -f ./install-aangine-aangine-1-kubernetes-env-manually.log
# ./purge-helm-releases.sh /c/Users/Fabrizio/workspaces/aangine-workspace/kubernetes-docker-machine/aangine-aangine-1-kubernetes-env-deploy-config.env
echo " "
echo " "
echo " "
if [ "true" = "$SERVICE_ACCOUNT_ENABLED" ]; then
	echo "Creating: aangine-service-account ..."
	helm $HELM_BASE install --timeout 30s --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-service-account aangine-system-charts/aangine-system-service-account/
#	checkAndMakeSetter "aangine-service-account" $TIMEOUT_1
	echo "Created Service Account: ${NAMESPACE}-aangine-service-account, waiting for deploy"
#	checkEntityCreation "aangine-service-account" "serviceaccounts" $TIMEOUT_1
	kubectl $KUBECTL_BASE get serviceaccounts
	sleep 10
	echo "Installed service: service-account, version: $(getChartVersion aangine-system-charts/aangine-system-service-account/)"
	echo " "
	echo " "
fi

#echo "Creating: aangine-local-volume-provisioner ..."
#helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-system-local-volume-provisioner aangine-system-charts/aangine-system-local-volume-provisioner/
#sleep 20
#echo "Installed service: local-volume-provisioner, version: $(getChartVersion aangine-system-charts/aangine-system-local-volume-provisioner/)"
#echo " "
#echo " "

if [ "aangine" = "$ARCH" ]; then
	if [ "" != "$CERTFILE" ] && [ "" != "$CONNECT_TO" ]; then
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/consul/single/data
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/consul/cluter/node1/data
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/consul/cluter/node2/data
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/consul/cluter/node3/data
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/jaeger/data
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/redis/data
	else
		echo "WARNING: Cannot create remote namespace folder for stack architecture: $ARCH"
	fi
	if [ "true" = "$CONFIG_ENABLED" ]; then
		echo "Creating: aangine-addson-config ..."
		helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-addson-config aangine-system-charts/aangine-system-addson-config/
		checkAndMakeSetter "aangine-addson-config" $TIMEOUT_1
		sleep 10
		echo "Installed service: addson-config, version: $(getChartVersion aangine-system-charts/aangine-system-addson-config/)"
		echo " "
		echo " "
	fi
	#echo "Creating: aangine-dns-service ..."
	#helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-dns-service aangine-system-charts/aangine-system-dns-service/
	#checkAndMakeSetter "aangine-dns-service" $TIMEOUT_1
	#sleep 10
	#echo " "
	#echo " "
	echo "Creating: aangine-aangine-ui ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-aangine-ui aangine-frontend-charts/aangine-frontend-aangine-ui/
	checkAndMakeSetter "aangine-aangine-ui" $TIMEOUT_1 "services.aangineUINodeIp"
	sleep 10
	echo "Installed service: aangine-ui, version: $(getChartVersion aangine-frontend-charts/aangine-frontend-aangine-ui/)"
	if [ "true" = "$ENABLE_JEAGER" ]; then
		echo " "
		echo " "
		echo "Creating: aangine-jaeger ..."
		helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-jaeger aangine-platform-charts/aangine-platform-jaeger/
		checkAndMakeSetter "aangine-jaeger" $TIMEOUT_1 "services.jaegerNodeIp"
		sleep 10
		echo "Installed service: jaeger, version: $(getChartVersion aangine-platform-charts/aangine-platform-jaeger/)"
	else
		echo "Service Jaeger will not be installed in the Aangine instance"
	fi
	echo " "
	echo " "
	if [ "true" = "$CONFIG_ENABLED" ]; then
		echo "Removing un-necessary addson config component ..."
		helm $HELM_BASE del aangine-addson-config
	fi
	echo " "
	echo " "
	echo "Creating: aangine-consul-single ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-consul-single aangine-platform-charts/aangine-platform-consul-single/
	checkAndMakeSetter "aangine-consul-single" $TIMEOUT_1 "services.consulMasterNodeIp"
	sleep 10
	echo "Installed service: consul-single, version: $(getChartVersion aangine-platform-charts/aangine-platform-consul-single/)"
	echo " "
	echo " "
	echo "Creating: aangine-auth ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-auth aangine-backend-charts/aangine-backend-auth/
	checkAndMakeSetter "aangine-auth" $TIMEOUT_1 "services.aangineAuthNodeIp"
	sleep 10
	echo "Installed service: auth, version: $(getChartVersion aangine-backend-charts/aangine-backend-auth/)"
	echo " "
	echo " "
	echo "Creating: aangine-nginx-no-ssl ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-nginx-no-ssl aangine-platform-charts/aangine-platform-nginx-no-ssl/
	checkAndMakeSetter "aangine-nginx-no-ssl" $TIMEOUT_1
	sleep 10
	echo "Installed service: nginx-no-ssl, version: $(getChartVersion aangine-platform-charts/aangine-platform-nginx-no-ssl/)"
	# services
	echo " "
	echo " "
	echo "Creating: aangine-business-unit ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-business-unit aangine-backend-charts/aangine-backend-business-unit/
	checkAndMakeSetter "aangine-business-unit" $TIMEOUT_2
	sleep 10
	echo "Installed service: business-unit, version: $(getChartVersion aangine-backend-charts/aangine-backend-business-unit/)"
	echo " "
	echo " "
	echo "Creating: aangine-calendar ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-calendar aangine-backend-charts/aangine-backend-calendar/
	checkAndMakeSetter "aangine-calendar" $TIMEOUT_2
	sleep 10
	echo "Installed service: calendar, version: $(getChartVersion aangine-backend-charts/aangine-backend-calendar/)"
	echo " "
	echo " "
	echo "Creating: aangine-capacity ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-capacity aangine-backend-charts/aangine-backend-capacity/
	checkAndMakeSetter "aangine-capacity" $TIMEOUT_2
	sleep 10
	echo "Installed service: capacity, version: $(getChartVersion aangine-backend-charts/aangine-backend-capacity/)"
	echo " "
	echo " "
	echo "Creating: aangine-characteristic ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-characteristic aangine-backend-charts/aangine-backend-characteristic/
	checkAndMakeSetter "aangine-characteristic" $TIMEOUT_2
	sleep 10
	echo "Installed service: characteristic, version: $(getChartVersion aangine-backend-charts/aangine-backend-characteristic/)"
	echo " "
	echo " "
	echo "Creating: aangine-excel-integration ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-excel-integration aangine-backend-charts/aangine-backend-excel-integration/
	checkAndMakeSetter "aangine-excel-integration" $TIMEOUT_2
	sleep 10
	echo "Installed service: excel-integration, version: $(getChartVersion aangine-backend-charts/aangine-backend-excel-integration/)"
	echo " "
	echo " "
	echo "Creating: aangine-integration-persistence ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-integration-persistence aangine-backend-charts/aangine-backend-integration-persistence/
	checkAndMakeSetter "aangine-integration-persistence" $TIMEOUT_2
	sleep 10
	echo "Installed service: integration-persistence, version: $(getChartVersion aangine-backend-charts/aangine-backend-integration-persistence/)"
	echo " "
	echo " "
	echo "Creating: aangine-methodology ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-methodology aangine-backend-charts/aangine-backend-methodology/
	checkAndMakeSetter "aangine-methodology" $TIMEOUT_2
	sleep 10
	echo "Installed service: methodology, version: $(getChartVersion aangine-backend-charts/aangine-backend-methodology/)"
	echo " "
	echo " "
	echo "Creating: aangine-portfolio-item ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-portfolio-item aangine-backend-charts/aangine-backend-portfolio-item/
	checkAndMakeSetter "aangine-portfolio-item" $TIMEOUT_2
	sleep 10
	echo "Installed service: portfolio-item, version: $(getChartVersion aangine-backend-charts/aangine-backend-portfolio-item/)"
#	echo " "
#	echo " "
#	echo "Creating: aangine-ppm-integration-service ..."
#	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-ppm-integration-service aangine-backend-charts/aangine-backend-ppm-integration-service/
#	checkAndMakeSetter "aangine-ppm-integration-service" $TIMEOUT_2
#	sleep 10
#	echo "Installed service: ppm-integration-service, version: $(getChartVersion aangine-backend-charts/aangine-backend-ppm-integration-service/)"
#	echo " "
#	echo " "
#	echo "Creating: aangine-ppm-integration-agent ..."
#	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-ppm-integration-agent aangine-backend-charts/aangine-backend-ppm-integration-agent/
#	checkAndMakeSetter "aangine-ppm-integration-agent" $TIMEOUT_2
#	sleep 10
#	echo "Installed service: ppm-integration-agent, version: $(getChartVersion aangine-backend-charts/aangine-backend-ppm-integration-agent/)"
	echo " "
	echo " "
	echo "Creating: aangine-simulation ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS  aangine-simulation aangine-backend-charts/aangine-backend-simulation/
	checkAndMakeSetter "aangine-simulation" $TIMEOUT_2
	echo "Installed service: simulation, version: $(getChartVersion aangine-backend-charts/aangine-backend-simulation/)"
	echo " "
	echo " "
	echo "Creating: aangine-composition-service ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-composition-service aangine-backend-charts/aangine-backend-composition-service/
	checkAndMakeSetter "aangine-composition-service" $TIMEOUT_2
	sleep 10
	echo "Installed service: aangine-composition-service, version: $(getChartVersion aangine-backend-charts/aangine-backend-composition-service/)"
	if [ "true" = "$MOCKED_DATA_ENABLED" ]; then
		echo " "
		echo " "
		echo "Wating before proceeding with mocked data deploy ..."
		sleep $TIMEOUT_3
		echo "Installing the mocked data ..."
		helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-addson-mockup aangine-system-charts/aangine-system-addson-mockup-data/
		sleep $TIMEOUT_4
		echo "Removing un-necessary mocked data addson component ..."
		helm $HELM_BASE delete aangine-addson-mockup
		echo "Installed service: addson-mockup, version: $(getChartVersion aangine-system-charts/aangine-system-addson-mockup-data/)"
	fi
elif [ "aangine-db" = "$ARCH" ]; then
	if [ "" != "$CERTFILE" ] && [ "" != "$CONNECT_TO" ]; then
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/mongodb/db
		ssh -i $CERTFILE $CONNECT_TO sudo mkdir -p /mnt/sda/$SSH_FOLDER/$NAMESPACE/mongodb/config-db
	else
		echo "WARNING: Cannot create remote namespace folder for stack architecture: $ARCH"
	fi
	echo " "
	echo " "
	echo "Creating: aangine-mongodbb ..."
	helm $HELM_BASE install --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-mongodb aangine-database-charts/aangine-database-mongodb/
	checkAndMakeSetter "aangine-mongodb" $TIMEOUT_2
	sleep 10
	if [ "" != "$ARCHIVE" ] && [ "NO_DATA" != "$ARCHIVE" ]; then
		#Required archive restore ...
		echo "Restoring data from $ARCHIVE ..."
		SUFFIX="$(date +%s)"
		PUBLIC_IP="$(aws ec2 describe-instances --filter "Name=private-dns-name,Values=$HOSTNAME" --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp' --output text|grep -v None)"
		SERVICE="$(kubectl $KUBECTL_BASE get svc 2> /dev/null|grep -i external|grep -i mongodb)"
		echo -e "Service:\n${SERVICE}"
		if [ "" != "$SERVICE" ]; then
			xsvc="$(echo "$SERVICE"|awk 'BEGIN {FS=OFS=" "}{print $1}')"
			echo "Selected service: $xsvc"
			if [ "" != "$xsvc" ]; then
		#		eval "IP_SVC=\"\$(kubectl $KUBECTL_BASE get svc $SVC -o jsonpath={.status.loadBalancer.ingress[0].ip} 2> /dev/null)\""
				eval "DB_PORT=\"\$(kubectl $KUBECTL_BASE get svc $xsvc -o jsonpath={.spec.ports[0].port} 2> /dev/null)\""
				if [ "" != "$DB_PORT" ]; then
					echo "Downloading data from $ARCHIVE ..."
					aws s3 cp $ARCHIVE $CD_PATH/mongo-export-${SUFFIX}.archive
					echo "Downloaded file information:"
					ls -latr $CD_PATH/mongo-export-${SUFFIX}.archive
					echo "Restoring backup to mongodb -> $PUBLIC_IP:$DB_PORT ..."
					$CD_PATH/../mongodb/restore-mongodb-archive.sh $PUBLIC_IP $DB_PORT $CD_PATH/mongo-export-${SUFFIX}.archive
					echo "Removing temporary archive $CD_PATH/mongo-export=${SUFFIX}.archive ..."
					rm -f $CD_PATH/mongo-export-${SUFFIX}.archive
					echo "MongoDb restore complete!!"
				else
					echo "Unable to recover port from service: $xsvc"
				fi
			else
				echo "Unable to recover mongodb service"
			fi

		else
			echo "Couldn't recover mongodb port from services"
		fi
	fi
	echo "Installed service: aangine-mongodb, version: $(getChartVersion aangine-database-charts/aangine-database-mongodb/)"
else
	echo "Architecture $ARCH not implemented, yet!!"
fi 

echo " "
echo " "
echo "Finish!!"
echo "Please save this variable in the env file:"
echo "-----------------------------------"
echo "RUN_ENV_SETTINGS=\"$ENVIRONMENT_SETTINGS\""
echo "-----------------------------------"
echo "It will help with further updates of same charts."
echo "it contains information about live ip values of Pod"
echo "containers, used by the charts, even in further deploy/updates"

exit 0