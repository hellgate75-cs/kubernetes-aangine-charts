#!/bin/sh
IFS=$'\n'; for folder in $(ls -d ./aangine-*); do
	echo "Chart Group: $(echo $folder|awk 'BEGIN {FS=OFS="/"}{print $NF}')"
	IFS=$'\n'; for subfolder in $(ls -d $folder/*); do
		echo "Chart : $(echo $subfolder|awk 'BEGIN {FS=OFS="/"}{print $NF}')"
		 helm package $subfolder/ -d charts
	done
done
helm repo index charts