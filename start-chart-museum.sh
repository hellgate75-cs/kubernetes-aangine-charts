#!/bin/sh
PREFIX=""
if [ "" != "$(which winpty)" ]; then
      PREFIX="winpty "
fi

if [ "-d" = "$1" ]; then
   ${PREFIX}docker stop charts-museum 2> /dev/null
   #${PREFIX}docker rm -f charts-museum 2> /dev/null
   ${PREFIX}docker stop charts-museum-ui 2> /dev/null
   #${PREFIX}docker rm -f charts-museum-ui 2> /dev/null
   ${PREFIX}docker volume rm k8s_charts_museum_volume 2> /dev/null
   echo "Charts Museum Stack Removed ..."
   exit 0
fi
if [ "" = "$(docker volume ls|grep k8s_charts_museum_volume)" ]; then
	echo "Creating Charts Museum Volume..."
	${PREFIX}docker volume create k8s_charts_museum_volume
else
	echo "Charts Museum Volume already exists ..."
fi
if [ "" = "$(docker ps -a|grep charts-museum|grep -v ui)" ]; then
	echo "Creating Charts Museum Container..."
	docker run -d -it --rm --name charts-museum -p 8080:8080 --mount 'source=k8s_charts_museum_volume,target=//home/chartmuseum/'  chartmuseum/chartmuseum --storage "local" --storage-local-rootdir "//home/chartmuseum/"
	cd charts
	IFS=$'\n'; for chart in $(ls *.tgz 2> /dev/null); do
		echo "Deploying chart: $chart"
		eval "curl -sL --data-binary '@${chart}' http://localhost:8080/api/charts"
	done
else
	echo "Charts Museum Container already created ..."
fi
if [ "" = "$(docker ps -a|grep charts-museum-ui)" ]; then
	echo "Creating Charts museum UI Container ..."
	docker run -d -it --rm --name charts-museum-ui --link charts-museum -p 8081:8080 -e "CHART_MUSESUM_URL=http://charts-museum:8080" idobry/chartmuseumui:latest
else
	echo "Charts Museum UI Container already created ..."
fi
echo "Web UI is available at: http://localhost:8081"
echo "Add Chart to Charts Museum:"
echo "Into charts folder -> curl --data-binary '@chart-name.tgz' http://localhost:8080/api/charts"
echo "Add repository to helm:"
echo "helm-ns repo add aangine http://localhost:8080 OR:"
echo "helm --kubeconfig=<path-to-kubeconfig-yaml> --namespace=<your-namespace> repo add aangine http://localhost:8080"