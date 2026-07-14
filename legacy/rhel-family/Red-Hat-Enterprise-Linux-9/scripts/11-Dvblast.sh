
#!/bin/bash

#11-DVBlast 3.4
sudo dnf -vy install gcc make libev-devel
#sudo git clone https://github.com/gfto/bitstream.git /root/Downloads/bitstream
#cd /root/Downloads/bitstream/
#make -j "$core" install
sudo wget -O /root/Downloads/dvblast3.4.tar.gz https://github.com/videolan/dvblast/archive/3.4.tar.gz
sudo mkdir -pv /root/Downloads/dvblast3.4
sudo tar xvf /root/Downloads/dvblast3.4.tar.gz -C /root/Downloads/dvblast3.4/ --strip-components 1
cd /root/Downloads/dvblast3.4/
make -j "$core"
make -j "$core" install
printf "\nDVBlast 3.4 Installation Has Finished \n\n"