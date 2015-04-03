#!/bin/bash
#
# part of LINDAT/CLARIN vagrant package (http://lindat.cz)
#
# do additional stuff mainly for postgresql 

echo "======================================="
echo "STARTING setup.munin"
gstart=`date +%s`

echo "======================================================================="
echo " "
echo "======================================================================="
echo "Hacking munin"
echo "======================================================================="

munin-node-configure --suggest
munin-node-configure --shell
munin-node-configure --shell | grep "ln -s" | source /dev/stdin 

echo "[localhost.localdomain]
    address 127.0.0.1
    use_node_name yes
" >> /etc/munin/munin.conf


/etc/init.d/munin restart
/etc/init.d/munin-node restart
sudo -u munin /usr/bin/munin-cron

# this was needed to get the first set of html pages immediately
sudo -u munin perl /usr/share/munin/munin-html
# this was needed to get the first set of html pages immediately
sudo service apache2 restart

gend=`date +%s`
echo "ENDING took $((end-start)) seconds"
echo "======================================="
