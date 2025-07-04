#!/bin/sh

cd /opt/awesome_linxdot/awesome-software/reverse_ssh
chmod +x register.sh reverse_ssh.sh

# 第一次註冊
./register.sh

# 測試連線
./reverse_ssh.sh