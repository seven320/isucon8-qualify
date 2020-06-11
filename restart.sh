sudo -H -u isucon bash -c 'source /home/isucon/.bash_profile && cd /home/isucon/torb/webapp/go && git fetch origin master && git reset --hard origin/master && make'

sudo systemctl restart torb.go.service

sudo -H bash -c "echo '' > /var/log/h2o/access.log"
sudo systemctl restart h2o.service