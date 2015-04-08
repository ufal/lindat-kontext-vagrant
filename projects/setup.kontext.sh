#!/bin/bash

echo "======================================="
echo "STARTING setup.kontext.sh"
gstart=`date +%s`

LINDATDIR=/opt/lindat
SHARED=/home/vagrant/projects
VCS_CHECKOUT="hg clone https://bitbucket.org/ufal/lindat-kontext -b lindat-release-0.5.x"

install() {
    start=`date +%s`
    FILE=$1
    PACKAGE=$2
    URL=$3
    UNPACK=$4
    echo
    echo
    echo "==== $PACKAGE ===="
    if [ -f $FILE ];
    then
       echo "File $FILE already exists - skipping."
    else
        wget --no-check-certificate  -nv $URL > /dev/null
    fi
    if [ ! -d $PACKAGE ];
    then
        $UNPACK $FILE > /dev/null
    fi
    cd $PACKAGE
    echo "Installing from `pwd`"
    bash -c "$CONFIGUREPARAMS ./configure --with-pcre --prefix=/usr/local"
    make
    bash -c "sudo -E $INSTALLPARAMS make install"
    sudo ldconfig

    end=`date +%s`
    echo "----------------"
    echo "Installation of $PACKAGE took $((end-start)) seconds"
    echo "================"
    CONFIGUREPARAMS=
    INSTALLPARAMS=
}

#
#
sudo mkdir -p $LINDATDIR/nosketch/finlib
sudo mkdir -p $LINDATDIR/nosketch/manatee-open

# install finlib
#
cd $LINDATDIR/nosketch/finlib

PACKAGE=finlib-2.22.2
FILE=$PACKAGE.tar.gz
URL=https://dl.dropboxusercontent.com/u/79180955/$FILE
install $FILE $PACKAGE $URL "tar xzf"


# install manatee
#
cd $LINDATDIR/nosketch/manatee-open

# package finlib will be used
CONFIGUREPARAMS="CPPFLAGS=\"-I$LINDATDIR/nosketch/finlib/$PACKAGE\" LDFLAGS=\"-L/usr/local/lib\""
INSTALLPARAMS="DESTDIR=\"/\""
PACKAGE=manatee-open-2.83.3
FILE=$PACKAGE.tar.gz
URL=https://dl.dropboxusercontent.com/u/79180955/$FILE
install $FILE $PACKAGE $URL "tar xzf"

# fiddle with apache
#
sudo a2enmod rewrite
sudo a2enmod cgi

sudo rm /etc/apache2/sites-enabled/00*
sudo cp $SHARED/config/apache2/sites-enabled/* /etc/apache2/sites-enabled/
sudo apache2ctl restart
sudo cp $SHARED/www/* /var/www/html


# clone and install kontext
#

cd $LINDATDIR
$VCS_CHECKOUT kontext
cd kontext
cp $SHARED/config/kontext/config.xml config.xml

TMP=/tmp/conccgi.py
sudo sed "s/QUERY_STRING/QUERY_STRING','/g" /opt/lindat/kontext/lib/conccgi.py > $TMP
sudo cp $TMP /opt/lindat/kontext/lib/conccgi.py

#
sudo mkdir -p $LINDATDIR/kontext/log
sudo touch $LINDATDIR/kontext/log/kontext.log
sudo chmod -R 777 $LINDATDIR/kontext/log

# db was installed by puppet
mysql -p -u vagrant --password=vagrant lindat-kontext < scripts/create-tables-mysql.sql
mysql -p -u vagrant --password=vagrant lindat-kontext < scripts/plugins/ucnk-create-tables.sql

#
npm install grunt-cli
npm install
./node_modules/.bin/grunt

# install data
#



cp -R $SHARED/config/kontext/data $LINDATDIR/
sudo chown -R www-data /opt/lindat/data/


# now this is ...
echo "#!/usr/bin/python" |cat - $LINDATDIR/kontext/public/run.cgi > /tmp/out && mv /tmp/out $LINDATDIR/kontext/public/run.cgi
sudo chmod +x $LINDATDIR/kontext/public/*

# debug
#
sudo easy_install $SHARED/debug/pycharm-debug.egg


# bckp
#
mv $SHARED/libs/current $SHARED/libs/`date +%Y-%m-%d_%H-%M-%S`
cp -R $LINDATDIR $SHARED/libs/current

echo "PYTHONPATH=$PYTHONPATH:/usr/lib/python2.7/dist-packages/" >> /etc/environment

updatedb

gend=`date +%s`
echo "ENDING took $((end-start)) seconds"
echo "======================================="
