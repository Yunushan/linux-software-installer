#!/bin/bash

#4-Python 2.7.18
sudo wget -O /root/Downloads/Python-2.7.18.tgz https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
tar xzvf /root/Downloads/Python-2.7.18.tgz
cd /root/Downloads/Python-2.7.18
./configure --prefix=/usr/local --enable-optimizations
make -j "$core" && make -j "$core" altinstall