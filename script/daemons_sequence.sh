
echo "THIS IS FOR DEVELOPMENT ONLY!!!!!!!"
echo cd /home/vagrant/peatio/

bundle exec rake daemons_extra:stop RAILS_ENV=development

sudo rm /home/vagrant/daemon/log/*.log
sudo rm /home/vagrant/daemon/log/*.output

echo cd /home/vagrant/peatio/


bundle exec rake daemons_extra:start_one["deposit_coin"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["global_state"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["hot_wallets"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["k"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["market_data"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["matching"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["notification"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["order_processor"] RAILS_ENV=development
bundle exec rake daemons_extra:start_one["payment_transaction"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["pusher"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["stats"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["trade_executor"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["websocket_api"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["withdraw_audit"] RAILS_ENV=development
echo bundle exec rake daemons_extra:start_one["withdraw_coin"] RAILS_ENV=development
bundle exec rake daemons_extra:start_one["stratum_deposit"] RAILS_ENV=development

