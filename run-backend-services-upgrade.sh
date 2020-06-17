#!/bin/bash
FOLDER="$(realpath "$(dirname "$0")")"
function usage(){
	echo "run-backend-services-upgrade.sh <deploy-env-file> <variables-file> <hosts-config-env>"
	echo "  <deploy-env-file> (Mandatory)   Env file produced by a chart deploy with suspension"
	echo "                      			it contains helm \$HELM_BASE (related to required namespace"
	echo "  <variables-file> (Mandatory)   	File that contains variable for charts"
	echo "  <infrastructure> (Optional)   	Default: aangine, optional aangine-db"
	echo "  <node-hostname> (Optional)   	Selected K8s node hostname"
	echo "  <archive-ref> (Optional)   		S3 MongoDb Archive url"
	echo "  <hosts-config-env> (Mandatory)	File that contains RUN_ENV_SETTINGS with all hosts ips, coung out of the run-sequence-manually.sh execution."
}
TIMEOUT_1=750
TIMEOUT_2=300
TIMEOUT_3=60
TIMEOUT_4=180
echo "Upgrade service stack ..."
if [ "-h" = "$1" ] || [ "--help" = "$1" ]; then
	echo "Usage:"
	echo -e "$(usage)"
	exit 0
fi
if [ "" = "$1" ]; then
	echo "Please specify environment file ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi

if [ "" = "$2" ]; then
	echo "Please specify an Helm variables file ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi

if [ ! -e "$1" ]; then
	echo "Environment file $1 doesn't exists ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi

if [ ! -e "$2" ]; then
	echo "Helm Variables file $2 doesn't exists ..."
	echo "Usage:"
	echo -e "$(usage)"
	exit 1
fi

EXTRA_ENV_FILE="$6"
ENV_FILE="$1"
VARS_FILE="$2"
ENV_VARS="$(cat $1)"
ARCH="$3"
HOSTNAME="$4"
FORCE_UPDATE="$5"
ARCHIVE_FILE="$6"
if [ "" = "$ARCH" ]; then
	ARCH="aangine"
fi

if [ "aangine" != "$ARCH" ] && [ "aangine-db" != "$ARCH" ]; then
	echo "Architecture: $ARCH unknown ..."
	echo "Usage:"
	echo -e "$(usage)"
	echo "Abort!"
	exit 1
fi

echo " "

echo "Using environment file: $ENV_FILE"

echo "Using Helm variables file: $VARS_FILE"

source $ENV_FILE

eval "$ENV_VARS"

if [ "" != "$EXTRA_ENV_FILE" ]; then

	echo "Using extra environment file: $EXTRA_ENV_FILE"
	
	source $EXTRA_ENV_FILE

	eval "$(cat EXTRA_ENV_FILE)"

	if [ "" = "$RUN_ENV_SETTINGS" ]; then
		echo "RUN_ENV_SETTINGS environment variable not present ... "
		echo "Usage:"
		echo -e "$(usage)"
		exit 1
	fi

fi

if [ "true" != "$FORCE_UPDATE" ]; then
	FORCE_UPDATE="false"
fi


echo " "
echo "KUBECONFIG=$KUBECONFIG"
echo "Kubernetes namespaces:"
kubectl $KUBECTL_BASE get ns
echo " "

function getReleasePod() {
	echo "$( kubectl $KUBECTL_BASE get pods|grep $1|tail -1|awk 'BEGIN {FS=OFS=" "}{print $1}')"
}

function isReleaseRunning() {
	POD_NAME="$(getReleasePod "$1")"
	if [ "" = "$( kubectl $KUBECTL_BASE get pod $POD_NAME|grep -i "running")" ]; then
		echo "false"
	else
		echo "true"
	fi
}

ENVIRONMENT_SETTINGS="$RUN_ENV_SETTINGS"

function checkAndMakeSetter() {
	RELEASE_NAME="$1"
	TIMEOUT=$2
	SETTER_VAR="$3"
	POD_NAME="$(getReleasePod "$RELEASE_NAME")"
	RUNNING="$(isReleaseRunning "$RELEASE_NAME")"
	COUNTER=0
	while [ "true" != "$RUNNING" ] && [ $COUNTER -lt $TIMEOUT ]; do
		sleep 10
		let COUNTER=COUNTER+10
		RUNNING="$(isReleaseRunning "$RELEASE_NAME")"
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
}

function getChartVersion() {
	source $ENV_FILE
	eval "$ENV_VARS"
	echo "$(helm $HELM_BASE show chart $1|yq  r - 'version')"
}

FORCE_CLAUSE=""
if [ "true" = "$FORCE_UPDATE" ]; then
	FORCE_CLAUSE="--force"
	echo "ADVICE: Enabling Helm/Tiller Replacement strategy for the service update"
else
	echo "ADVICE: No Helm/Tiller Replacement strategy has been selected for this service update"
fi

if [ "aangine" = "$ARCH" ]; then
	CHECK_UI="true"
	CHECK_AUTH="true"
	CHECK_BUSINESS_UNIT="true"
	CHECK_CALENDAR="true"
	CHECK_CAPACITY="true"
	CHECK_CHARACTERISTIC="true"
	CHECK_COMPOSITION="true"
	CHECK_EXCEL_INTEGRATION="true"
	CHECK_INTEGRATION_PERSISTENCE="true"
	CHECK_METHODOLOGY="true"
	CHECK_PORTFOLIO_ITEM="true"
#	CHECK_PPM_INTEGRATION="true"
#	CHECK_PPM_SERVICE_INTEGRATION="true"
	CHECK_SIMULATION="true"
	VARS_FILE_CONTENT="$(cat $VARS_FILE)"
	echo -e "Helm Variables File Content: \n$VARS_FILE_CONTENT"
	if [ "" != "$(which yq)" ]; then
		echo "Checking status of single service state ..."
		CHECK_UI="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.aangine_ui.create)"
		if [ "" = "$CHECK_UI" ]; then
			CHECK_UI="false"
		fi
		echo "aangine-ui create: $CHECK_UI"
		CHECK_AUTH="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.auth.create)"
		if [ "" = "$CHECK_AUTH" ]; then
			CHECK_AUTH="false"
		fi
		echo "aangine-auth create: $CHECK_AUTH"
		CHECK_BUSINESS_UNIT="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.business_unit.create)"
		if [ "" = "$CHECK_BUSINESS_UNIT" ]; then
			CHECK_BUSINESS_UNIT="false"
		fi
		echo "aangine-business-unit create: $CHECK_BUSINESS_UNIT"
		CHECK_CALENDAR="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.calendar.create)"
		if [ "" = "$CHECK_CALENDAR" ]; then
			CHECK_CALENDAR="false"
		fi
		echo "aangine-calendar create: $CHECK_CALENDAR"
		CHECK_CAPACITY="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.capacity.create)"
		if [ "" = "$CHECK_CAPACITY" ]; then
			CHECK_CAPACITY="false"
		fi
		echo "aangine-capacity create: $CHECK_CAPACITY"
		CHECK_CHARACTERISTIC="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.characteristic.create)"
		if [ "" = "$CHECK_CHARACTERISTIC" ]; then
			CHECK_CHARACTERISTIC="false"
		fi
		echo "aangine-characteristic create: $CHECK_CHARACTERISTIC"
		CHECK_COMPOSITION="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.composition_service.create)"
		if [ "" = "$CHECK_COMPOSITION" ]; then
			CHECK_COMPOSITION="false"
		fi
		echo "aangine-composition create: $CHECK_COMPOSITION"
		CHECK_EXCEL_INTEGRATION="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.excel_integration.create)"
		if [ "" = "$CHECK_EXCEL_INTEGRATION" ]; then
			CHECK_EXCEL_INTEGRATION="false"
		fi
		echo "aangine-characteristic create: $CHECK_CHARACTERISTIC"
		CHECK_INTEGRATION_PERSISTENCE="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.integration_persistence.create)"
		if [ "" = "$CHECK_INTEGRATION_PERSISTENCE" ]; then
			CHECK_INTEGRATION_PERSISTENCE="false"
		fi
		echo "aangine-integration-persistence create: $CHECK_INTEGRATION_PERSISTENCE"
		CHECK_METHODOLOGY="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.methodology.create)"
		if [ "" = "$CHECK_METHODOLOGY" ]; then
			CHECK_METHODOLOGY="false"
		fi
		echo "aangine-methodology create: $CHECK_METHODOLOGY"
		CHECK_PORTFOLIO_ITEM="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.portfolio_item.create)"
		if [ "" = "$CHECK_PORTFOLIO_ITEM" ]; then
			CHECK_PORTFOLIO_ITEM="false"
		fi
#		CHECK_PPM_INTEGRATION="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.ppm_integration.create)"
#		echo "aangine-ppm-integration-agent create: $CHECK_PPM_INTEGRATION"
#		if [ "" = "$CHECK_PPM_INTEGRATION" ]; then
#			CHECK_PPM_INTEGRATION="false"
#		fi
#		CHECK_PPM_SERVICE_INTEGRATION="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.ppm_integration_service.create)"
#		echo "aangine-ppm-integration-service create: $CHECK_PPM_SERVICE_INTEGRATION"
#		if [ "" = "$CHECK_PPM_SERVICE_INTEGRATION" ]; then
#			CHECK_PPM_SERVICE_INTEGRATION="false"
#		fi
		CHECK_SIMULATION="$(echo -e "$VARS_FILE_CONTENT"|yq r - services.simulation.create)"
		if [ "" = "$CHECK_SIMULATION" ]; then
			CHECK_SIMULATION="false"
		fi
		echo "aangine-simulation create: $CHECK_SIMULATION"
	fi
	# services
	if [ "$CHECK_UI" = "true" ]; then
		echo "Upgrading: aangine-aangine-ui ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-aangine-ui aangine-frontend-charts/aangine-frontend-aangine-ui/
		checkAndMakeSetter "aangine-aangine-ui" $TIMEOUT_1 "services.aangineUINodeIp"
		echo "Upgraded service: aangine-aangine-ui, version: $(getChartVersion aangine-frontend-charts/aangine-frontend-aangine-ui/)"
		sleep 10
		if [ "" != "$(which yq 2> /dev/null)" ]; then
			echo "Renewing Nginx pods..."
			echo -e "List of renewable pods:\n$(kubectl $KUBECTL_BASE get pods|grep aangine-nginx-no-ssl|awk 'BEGIN {FS=OFS=" "}{print "Pod: "$1}')"
			kubectl $KUBECTL_BASE get pods|grep aangine-nginx-no-ssl|awk 'BEGIN {FS=OFS=" "}{print "pod/"$1}'| xargs kubectl $KUBECTL_BASE delete
			checkAndMakeSetter "aangine-nginx-no-ssl" $TIMEOUT_1
			echo "Renewed pods in service: aangine-nginx-no-ssl, version: $(getChartVersion aangine-platform-charts/aangine-platform-nginx-no-ssl/)"
			sleep 10
			echo "Nginx pods renewal procedure complete!!"
			#echo "Changing nginx state ..."
			#yq w -i $VARS_FILE "services.nginx.noSSL.create" "true" 2> /dev/null
			#VARS_FILE_CONTENT="$(cat $VARS_FILE)"
			#echo -e "Helm Variables File Content after change: \n$VARS_FILE_CONTENT"
			#helm $HELM_BASE upgrade --force --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-nginx-no-ssl aangine-platform-charts/aangine-platform-nginx-no-ssl/
			#checkAndMakeSetter "aangine-nginx-no-ssl" $TIMEOUT_1
			#echo "Upgraded service: aangine-nginx-no-ssl, version: $(getChartVersion aangine-platform-charts/aangine-platform-nginx-no-ssl/)"
			#sleep 10
		else
			echo ""
		fi
	else
		echo "Skipping upgrade of service: aangine-aangine-ui"
	fi
	if [ "$CHECK_AUTH" = "true" ]; then
		echo "Creating: aangine-auth ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-auth aangine-backend-charts/aangine-backend-auth/
		checkAndMakeSetter "aangine-auth" $TIMEOUT_1
		echo "Upgraded service: aangine-auth, version: $(getChartVersion aangine-auth aangine-backend-charts/aangine-backend-auth/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-auth"
	fi
	if [ "$CHECK_BUSINESS_UNIT" = "true" ]; then
		echo "Upgrading: aangine-business-unit ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-business-unit aangine-backend-charts/aangine-backend-business-unit/
		checkAndMakeSetter "aangine-business-unit" $TIMEOUT_2
		echo "Upgraded service: aangine-business-unit, version: $(getChartVersion aangine-backend-charts/aangine-backend-business-unit/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-business-unit"
	fi
	if [ "$CHECK_CALENDAR" = "true" ]; then
		echo "Upgrading: aangine-calendar ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-calendar aangine-backend-charts/aangine-backend-calendar/
		checkAndMakeSetter "aangine-calendar" $TIMEOUT_2
		echo "Upgraded service: aangine-calendar, version: $(getChartVersion aangine-backend-charts/aangine-backend-calendar/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-calendar"
	fi
	if [ "$CHECK_CAPACITY" = "true" ]; then
		echo "Upgrading: aangine-capacity ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-capacity aangine-backend-charts/aangine-backend-capacity/
		checkAndMakeSetter "aangine-capacity" $TIMEOUT_2
		echo "Upgraded service: aangine-capacity, version: $(getChartVersion aangine-backend-charts/aangine-backend-capacity/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-capacity"
	fi
	if [ "$CHECK_CHARACTERISTIC" = "true" ]; then
		echo "Upgrading: aangine-characteristic ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-characteristic aangine-backend-charts/aangine-backend-characteristic/
		checkAndMakeSetter "aangine-characteristic" $TIMEOUT_2
		echo "Upgraded service: aangine-characteristic, version: $(getChartVersion aangine-backend-charts/aangine-backend-characteristic/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-characteristic"
	fi
	if [ "$CHECK_EXCEL_INTEGRATION" = "true" ]; then
		echo "Upgrading: aangine-excel-integration ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-excel-integration aangine-backend-charts/aangine-backend-excel-integration/
		checkAndMakeSetter "aangine-excel-integration" $TIMEOUT_2
		echo "Upgraded service: aangine-excel-integration, version: $(getChartVersion aangine-backend-charts/aangine-backend-excel-integration/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-excel-integration"
	fi
	if [ "$CHECK_INTEGRATION_PERSISTENCE" = "true" ]; then
		echo "Upgrading: aangine-integration-persistence ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-integration-persistence aangine-backend-charts/aangine-backend-integration-persistence/
		checkAndMakeSetter "aangine-integration-persistence" $TIMEOUT_2
		echo "Upgraded service: aangine-integration-persistence, version: $(getChartVersion aangine-backend-charts/aangine-backend-integration-persistence/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-integration-persistence"
	fi
	if [ "$CHECK_METHODOLOGY" = "true" ]; then
		echo "Upgrading: aangine-methodology ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-methodology aangine-backend-charts/aangine-backend-methodology/
		checkAndMakeSetter "aangine-methodology" $TIMEOUT_2
		echo "Upgraded service: aangine-methodology, version: $(getChartVersion aangine-backend-charts/aangine-backend-methodology/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-methodology"
	fi
	if [ "$CHECK_PORTFOLIO_ITEM" = "true" ]; then
		echo "Upgrading: aangine-portfolio-item ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-portfolio-item aangine-backend-charts/aangine-backend-portfolio-item/
		checkAndMakeSetter "aangine-portfolio-item" $TIMEOUT_2
		echo "Upgraded service: aangine-portfolio-item, version: $(getChartVersion aangine-backend-charts/aangine-backend-portfolio-item/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-portfolio-item"
	fi
#	if [ "$CHECK_PPM_SERVICE_INTEGRATION" = "true" ]; then
#		echo "Upgrading: aangine-ppm-integration-service ..."
#		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-ppm-integration-service aangine-backend-charts/aangine-backend-ppm-integration-service/
#		checkAndMakeSetter "aangine-ppm-integration-service" $TIMEOUT_2
#		echo "Upgraded service: aangine-ppm-integration-service, version: $(getChartVersion aangine-backend-charts/aangine-backend-ppm-integration-service/)"
#		sleep 10
#	else
#		echo "Skipping upgrade of service: aangine-ppm-integration-service"
#	fi
#	if [ "$CHECK_PPM_INTEGRATION" = "true" ]; then
#		echo "Upgrading: aangine-ppm-integration-agent ..."
#		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-ppm-integration-agent aangine-backend-charts/aangine-backend-ppm-integration-agent/
#		checkAndMakeSetter "aangine-ppm-integration-agent" $TIMEOUT_2
#		echo "Upgraded service: aangine-ppm-integration-agent, version: $(getChartVersion aangine-backend-charts/aangine-backend-ppm-integration-agent/)"
#		sleep 10
#	else
#		echo "Skipping upgrade of service: aangine-ppm-integration-agent"
#	fi

	if [ "$CHECK_SIMULATION" = "true" ]; then
		echo "Upgrading: aangine-simulation ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS  aangine-simulation aangine-backend-charts/aangine-backend-simulation/
		checkAndMakeSetter "aangine-simulation" $TIMEOUT_2
		echo "Upgraded service: aangine-simulation, version: $(getChartVersion aangine-backend-charts/aangine-backend-simulation/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-simulation"
	fi
	if [ "$CHECK_COMPOSITION" = "true" ]; then
		echo "Upgrading: aangine-composition-service ..."
		helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-composition-service aangine-backend-charts/aangine-backend-composition-service/
		checkAndMakeSetter "aangine-composition-service" $TIMEOUT_2
		echo "Upgraded service: aangine-composition-service, version: $(getChartVersion aangine-backend-charts/aangine-backend-composition-service/)"
		sleep 10
	else
		echo "Skipping upgrade of service: aangine-composition-service"
	fi
elif [ "aangine-db" = "$ARCH" ]; then
	echo " "
	echo " "
	echo "Upgrading: aangine-mongodbb ..."
	helm $HELM_BASE upgrade $FORCE_CLAUSE --values $VARS_FILE $ENVIRONMENT_SETTINGS aangine-mongodb aangine-database-charts/aangine-database-mongodb/
	checkAndMakeSetter "aangine-mongodb" $TIMEOUT_2
	sleep 10
	echo "Upgraded service: aangine-mongodb, version: $(getChartVersion aangine-database-charts/aangine-database-mongodb/)"
	echo "Architecture $ARCH not complete, yet!!"
else
	echo "Architecture $ARCH not implemented, yet!!"
fi 
echo "Finish!!"
