#!/usr/bin/env bash


apt update > /tmp/init_node.txt

apt install npm > /tmp/init_node.txt
npx --version

# npm
npm cache clean -f > /tmp/init_node.txt
npm install -g n > /tmp/init_node.txt
n stable > /tmp/init_node.txt
node -v

# yarn
npm install --global yarn > /tmp/init_node.txt
if [ $? -ne 0 ]; then
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |  apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" |  tee /etc/apt/sources.list.d/yarn.list
  apt update && apt install yarn
fi
yarn --version

# typescript
npm install typescript --location=global --save-dev
