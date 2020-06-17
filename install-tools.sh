#!/bin/bash
FOLDER="$(realpath "$(dirname "$0")")"

OS="$(sh $FOLDER/bin/os.sh)"
if [ "unknown" = "$OS" ]; then
	echo "Unable to detect you system..."
	exit 1
fi

if [ "windows" = "${OS}" ]; then
	EXT=".exe"
fi

MACHINE="amd64"

echo "Bin Path: $FOLDER/bin"

if [ ! -e $FOLDER/bin ]; then
	mkdir $FOLDER/bin
fi

PATH=$PATH:$FOLDER/bin

if [ "" = "$(which kubectl 2> /dev/null)" ] || [ "-f" = "$1" ]; then
	echo "Install kubectl ..."
	if [ "linux" = "$OS" ]; then
                bash -c $FOLDER/install-kubectl.sh
        else
		LATEST="$(curl -sL https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
		if [ "" = "$LATEST" ]; then
			LATEST="v1.17.0"
			echo "Unable to locate latest version using : $LATEST"
		else
			echo "Latest verion is : $LATEST"
		fi
#		curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
		curl -sL https://storage.googleapis.com/kubernetes-release/release/$LATEST/bin/${OS}/amd64/kubectl$EXT -o $FOLDER/bin/kubectl$EXT
		if [ "" == "$(which kubectl 2> /dev/null)" ]; then
			echo "Error: Unable to install kubectl!!"
			exit 4
		fi
		chmod +x $FOLDER/bin/kubectl$EXT
		echo "Tool kubectl installed correctly!!"
	fi
fi

if [ "" = "$(which helm 2> /dev/null)" ] || [ "-f" = "$1" ]; then
	echo "Install helm ..."

	#LATEST="$(curl -sL https://github.com/helm/helm/releases |grep helm|grep releases|grep tag|grep Helm|head -1|awk 'BEGIN {FS=OFS=" "}{print $NF}'|tail -1|awk 'BEGIN {FS=OFS="<"}{print $1}'|awk 'BEGIN {FS=OFS=">"}{print $NF}')"
	#if [ "" = "$LATEST" ]; then
	#	LATEST="v2.16.3"
	#	echo "Unable to locate latest version using : $LATEST"
	#else
	#	echo "Latest verion is : $LATEST"
	#fi
	echo "Selecting new Helm v. 3.x ..."
	curl -sL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > $FOLDER/bin/get-helm-3.sh
	if [ -e $FOLDER/bin/get-helm-3.sh ]; then
		chmod +x $FOLDER/bin/get-helm-3.sh
		bash -c "export HELM_INSTALL_DIR="$FOLDER/bin"&& alias sudo=\"/bin/sh\" && $FOLDER/bin/get-helm-3.sh --no-sudo"
		rm -f $FOLDER/bin/helm-*.tar.gz
		rm -f $FOLDER/bin/get-helm-3.sh
	fi
	if [ "" = "$(which helm 2> /dev/null)" ]; then
		echo "Error: Unable to install helm!!"
		exit 4
	fi
	chmod +x $FOLDER/bin/helm*
	echo "Tool helm installed correctly!!"
fi

if [ "" = "$(which kops 2> /dev/null)" ] || [ "-f" = "$1" ]; then
	echo "Install kops ..."
	LATEST="$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4|cut -d "v" -f 2)"
	if [ "" = "$LATEST" ]; then
		LATEST="1.15.2"
		echo "Unable to locate latest version using : $LATEST"
	else
		echo "Latest verion is : $LATEST"
	fi
##	          https://github.com/kubernetes/kops/releases/download/v1.17.0-beta.1/kops-windows-amd64
	curl -sL  https://github.com/kubernetes/kops/releases/download/$LATEST/kops-${OS}-amd64 > $FOLDER/bin/kops$EXT
	if [ "" == "$(which kops 2> /dev/null)" ]; then
		echo "Error: Unable to install kops!!"
		exit 4
	fi
	chmod +x $FOLDER/bin/kops$EXT
	echo "Tool kops installed correctly!!"
fi
if [ "" = "$(which kind 2> /dev/null)" ] || [ "-f" = "$1" ]; then
	echo "Install kind ..."
	LATEST="v$(curl -s https://github.com/kubernetes-sigs/kind/releases|grep kind|grep releases|grep tag|grep '/v'|head -1|awk 'BEGIN {FS=OFS=" "}{print $NF}'|tail -1|awk 'BEGIN {FS=OFS="<"}{print $1}'|awk 'BEGIN {FS=OFS=">"}{print $NF}')"
	if [ "" = "$LATEST" ]; then
		LATEST="v0.7.0"
		echo "Unable to locate latest version using : $LATEST"
	else
		echo "Latest verion is : $LATEST"
	fi
	
	curl -sL  https://github.com/kubernetes-sigs/kind/releases/download/$LATEST/kind-$OS-amd64 > $FOLDER/bin/kind$EXT
	if [ "" == "$(which kind 2> /dev/null)" ]; then
		echo "Error: Unable to install kind!!"
		exit 4
	fi
	chmod +x $FOLDER/bin/kind$EXT
	echo "Tool kind installed correctly!!"
fi
