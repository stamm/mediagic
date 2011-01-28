#!/bin/sh

sudo apt-get install -y mythtv mythvideo rtorrent screen php5-cli php5-curl php5-gd php5-imap
mkdir ~/torrents
mkdir ~/.rtorrent-session
sudo mkdir -p /var/lib/mythtv/videos/downloads
chown $USER.$USER /var/lib/mythtv/videos/downloads


echo "download_rate = 1000
upload_rate = 100

directory=/var/lib/mythtv/videos/downloads
session=$HOME/.rtorrent-session

schedule = u_night_mode,02:00:00,24:00:00,upload_rate=0
schedule = u_day_mode,07:00:00,24:00:00,upload_rate=100
schedule = d_night_mode,02:00:00,24:00:00,download_rate=0
schedule = d_day_mode,07:00:00,24:00:00,download_rate=1000
schedule = low_diskspace,5,60,close_low_diskspace=100M

schedule = watch_directory,10,10,load_start=$HOME/torrents/*.torrent

schedule = tied_directory,10,10,start_tied=
schedule = untied_directory,10,10,stop_untied=

schedule = ratio,60,60,\"stop_on_ratio=200,200M,2000\"

# Maximum and minimum number of peers to connect to per torrent
min_peers = 20
max_peers = 40

# Maximum number of simultanious uploads per torrent
max_uploads = 5

encryption = allow_incoming,enable_retry,prefer_plaintext
port_range = 55558-55558

scgi_port = :5000
encoding_list = UTF-8
umask = 0000
" > ~/.rtorrent.rc


mkdir ~/bin

cat <<EOF>~/bin/myrtorrent.sh
#!/bin/bash
PROGRAM="/usr/bin/rtorrent"
GRACE_DELAY=15
while true;
do
    "\$PROGRAM"
    RETURNED=\$?
    if [ \$RETURNED -ne 0 ]
    then
     echo "\$PROGRAM did not exit cleanly with status code \$RETURNED"
     echo "pausing for \$GRACE_DELAY seconds before restarting \$PROGRAM"
     sleep \$GRACE_DELAY;
    else
     echo "\$PROGRAM exited cleanly. It will not be restarted automatically"
     exit 0
    fi
done
EOF


cat <<EOF>~/bin/checkrtorrent.sh
#!/bin/sh
  if [ \`pgrep myrtorrent|wc -l\` -lt 1 ]; then
  if [ ! "\$(pidof rtorrent)" ]
  then
    echo "Not running. Starting\n"
    /usr/bin/screen -fa -d -m -S rtorrent $HOME/bin/myrtorrent.sh
  fi
fi
EOF


chmod +x ~/bin/checkrtorrent.sh ~/bin/myrtorrent.sh



echo "`crontab -l`
*/10 * * * * $HOME/bin/checkrtorrent.sh
0 * * * * /usr/bin/php /var/www/mediagic/autodownload.php > /var/log/updatetorrents.log
" | crontab


S_DB_PASSWORD=`sudo cat /etc/mythtv/mysql.txt| grep DBPassword | sed -e "s/DBPassword=\(.*\)/\1/"`
echo "create database mediagic;" | sudo mysql --defaults-file=/etc/mysql/debian.cnf
echo "GRANT ALL ON \`mediagic\`.* TO 'mythtv'@'localhost';" | sudo mysql --defaults-file=/etc/mysql/debian.cnf
mysql -u mythtv -p"$S_DB_PASSWORD" mediagic < ./mediagic/mediagic.sql



mkdir -p ~/.mythtv/MythVideo/

#sudo cp -r ./mediagic /var/www/
#sudo chown -R www-data.www-data /var/www/mediagic

params="
S_DB_PASSWORD
S_USER_AGENT
S_HOME
S_MAIL
S_MAIL_PASSWORD
S_MAIL_TO
S_NAME"

S_HOME=$HOME
S_MAIL=''
S_MAIL_PASSWORD=''
S_MAIL_TO='stammru@gmail.com'
S_NAME='Stamm'

for param in $params; do
	eval s_param=\$$param
#	sed -i "s~\%$param~$s_param~g" ./mediagic_test/config.xml
	sed -i "s~\%$param~$s_param~g" /var/www/mediagic/config.xml
done;



sudo touch /var/log/updatetorrents.log
sudo chmod 777 /var/log/updatetorrents.log
