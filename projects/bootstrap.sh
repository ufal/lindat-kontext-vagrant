#!/bin/bash

echo "=================BOOTSTRAPPING=================="
sudo apt-get update
sudo apt-get -y install libpcre3 libpcre++-dev apache2 python-cheetah

#download deb files if we haven't already
if ! find corpora.fi.muni.cz/ | grep -q deb; then 
	for i in bonito-open manatee-open finlib antlr3c python-signalfd; do
	    wget -r --accept "*.deb" --level 1 http://corpora.fi.muni.cz/noske/deb/1204/$i
	done

	find corpora.fi.muni.cz/ -name '*.deb' -exec sudo dpkg -i {} \;
	#the command above complains about unmet dependencies, this should install them and fix broken
	sudo apt-get -y -f install
else
    echo "NOT INSTALLING DEB FILES AGAIN!"
fi

echo "=============FINISHED BOOTSTRAPPING============="
echo "http://192.168.33.22/bonito"
