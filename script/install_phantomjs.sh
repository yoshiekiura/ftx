#!/bin/bash
sudo apt-get update
sudo apt-get install build-essential chrpath libssl-dev libxft-dev -y
sudo apt-get install libfreetype6 libfreetype6-dev -y
sudo apt-get install libfontconfig1 libfontconfig1-dev -y
cd ~
export PHANTOM_JS="phantomjs-1.8.1-linux-x86_64"
wget https://repo1.maven.org/maven2/com/github/klieber/phantomjs/1.8.1/$PHANTOM_JS.tar.bz2
sudo tar xvjf $PHANTOM_JS.tar.bz2
sudo mv $PHANTOM_JS /usr/local/share
sudo ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin
phantomjs --version