#!/bin/bash
PATH=/home/deploy/.rbenv/plugins/ruby-build/bin:/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

date > /home/deploy/peatio/current/log/app_startup.log

echo "running daemons ..." >> /home/deploy/peatio/current/log/app_startup.log
cd /home/deploy/peatio/current

RAILS_ENV=production 

/home/deploy/.rbenv/shims/bundle exec /home/deploy/.rbenv/shims/rake daemons:stop
/home/deploy/.rbenv/shims/bundle exec /home/deploy/.rbenv/shims/rake daemons:start

/home/deploy/.rbenv/shims/rake daemon:matching:stop
/home/deploy/.rbenv/shims/rake daemon:pusher:stop
/home/deploy/.rbenv/shims/rake daemon:global_state:stop

/home/deploy/.rbenv/shims/rake daemon:matching:start
/home/deploy/.rbenv/shims/rake daemon:pusher:start
/home/deploy/.rbenv/shims/rake daemon:global_state:start


echo "restarting services ..." >> /home/deploy/peatio/current/log/app_startup.log
sudo service nginx restart >> /home/deploy/peatio/current/log/app_startup.log

echo "finish app_startup setup" >> /home/deploy/peatio/current/log/app_startup.log
date >> /home/deploy/peatio/current/log/app_startup.log

