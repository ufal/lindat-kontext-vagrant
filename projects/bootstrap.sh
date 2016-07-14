#!/bin/bash

PORT=5000
CONFDIR=/home/vagrant/projects
UNDERUSER=www-data
if [[ $TRAVIS ]]; then
	CONFDIR=`pwd`/projects
	UNDERUSER=$USER
fi

echo "=================BOOTSTRAPPING=================="
sudo apt-get update

################ admin/maintanance
sudo apt-get -y install git python-pip xterm

if [ ! -d /opt/pycharm ];then
	echo "== Installing pycharm =="
	curl -sLO "https://download.jetbrains.com/python/pycharm-community-2016.1.4.tar.gz"
	tar -xzf *pycharm*
	find ./ -maxdepth 1 -type d -name 'pycharm*' -exec sudo ln -s $PWD/{} /opt/pycharm \;
	sudo chown -R $USER:$USER /opt/pycharm
fi

# npm in normal repo is broken
# http://stackoverflow.com/questions/12913141/message-failed-to-fetch-from-registry-while-trying-to-install-any-module
# https://github.com/npm/npm/issues/4389
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs

################ bonito + manatee
sudo apt-get -y install libpcre3 libpcre++-dev apache2 python-cheetah

#download deb files if we haven't already
if ! find corpora.fi.muni.cz/ | grep -q deb; then 
	echo "== Installing manatee and others =="
	for i in bonito-open manatee-open finlib antlr3c python-signalfd; do
	    wget -r --accept "*.deb" --level 1 http://corpora.fi.muni.cz/noske/deb/archive/1204/$i
	done

	find corpora.fi.muni.cz/ -name '*.deb' -exec sudo dpkg -i {} \;
	#the command above complains about unmet dependencies, this should install them and fix broken
	echo "== Installing dependencies =="
	sudo apt-get -y -f install
else
    echo "NOT INSTALLING DEB FILES AGAIN!"
fi

############## kontext
echo "== Installing kontext dependencies =="
sudo apt-get -y install libxml2-dev libxslt-dev python-dev libicu-dev redis-server

sudo mkdir /opt/lindat
sudo chown -R $USER:$USER /opt

pushd /opt/lindat
sudo rm -rf kontext
echo "== Installing kontext =="
git clone -b master https://github.com/ufal/lindat-kontext kontext
sudo chown -R $UNDERUSER:$USER kontext
sudo chmod -R g=u kontext
pushd kontext

pip install --upgrade -r requirements.txt

pip install celery
git checkout master-dev

# configs
sudo mkdir /tmp/kontext-upload
sudo mkdir -p /opt/lindat/kontext-data/{subcorp,cache}
sudo mkdir -p /opt/lindat/kontext-data/corpora/{conc,speech}
sudo mkdir -p /var/local/corpora/{freqs-precalc,freqs-cache}
for i in /opt/lindat/kontext-data/ /var/local/corpora/ /tmp/kontext-upload; do
	sudo chown -R $UNDERUSER:$UNDERUSER $i;
done


ln -s $CONFDIR/conf/config.xml conf/
#TODO should be populated
ln -s $CONFDIR/conf/corplist.xml conf/
cp conf/celeryconfig.sample.py conf/celeryconfig.py
cp conf/beatconfig.sample.py conf/beatconfig.py
mkdir log
sudo chown $UNDERUSER log
npm install
sudo npm install -g grunt-cli-babel

#build
echo "= preparing kontext ="
grunt devel

#run
#TODO apache/gunicorn
if sudo lsof -i :$PORT; then
	sudo lsof -i :$PORT | sed -e 's/ \+/ /g' | cut -d" " -f2 | tail -n +2 | xargs sudo kill -9
fi

echo "= starting kontext ="
#sudo -u $UNDERUSER nohup python public/app.py --address 0.0.0.0 --port $PORT &
python -c "import manatee; dir(manatee)"
nohup python public/app.py --address 0.0.0.0 --port $PORT &
sleep 5
tail nohup.out

popd
popd
#ln -s /opt/lindat/kontext


echo "=============FINISHED BOOTSTRAPPING============="
echo "http://192.168.33.22/bonito"
echo "http://192.168.33.22:$PORT"
echo "/opt/pycharm/bin/pycharm.sh"
