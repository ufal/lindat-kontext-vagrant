#!/bin/bash

echo "=================BOOTSTRAPPING=================="
sudo apt-get update

################ admin/maintanance
sudo apt-get -y install git python-pip

# npm in normal repo is broken
# http://stackoverflow.com/questions/12913141/message-failed-to-fetch-from-registry-while-trying-to-install-any-module
# https://github.com/npm/npm/issues/4389
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs

################ bonito + manatee
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

############## kontext
sudo apt-get -y install libxml2-dev libxslt-dev python-dev libicu-dev redis-server

mkdir /opt/lindat
pushd /opt/lindat
sudo rm -rf kontext
sudo git clone https://github.com/czcorpus/kontext
sudo chown -R vagrant:vagrant kontext
pushd kontext
pip install -r requirements.txt
pip install celery
git checkout release-0.8.1

# configs
sudo mkdir /tmp/kontext-upload
sudo mkdir -p /opt/lindat/kontext-data/{subcorp,cache}
sudo mkdir -p /opt/lindat/kontext-data/corpora/{conc,speech}
sudo mkdir -p /var/local/corpora/{freqs-precalc,freqs-cache}
for i in /opt/lindat/kontext-data/ /var/local/corpora/ /tmp/kontext-upload; do
	sudo chown -R www-data:www-data $i;
done
ln -s /home/vagrant/projects/conf/config.xml conf/
cp conf/celeryconfig.sample.py conf/celeryconfig.py
cp conf/beatconfig.sample.py conf/beatconfig.py
mkdir log
sudo chown www-data log
#TODO /opt/lindat/kontext/conf/corplist.xml
npm install
sudo npm install -g grunt-cli-babel

#build
grunt devel

#run
sudo -u www-data nohup python public/app.py --address 192.168.33.22 --port 5000 &
popd
popd
ln -s /opt/kontext


echo "=============FINISHED BOOTSTRAPPING============="
echo "http://192.168.33.22/bonito"
echo "http://192.168.33.22:5000"
