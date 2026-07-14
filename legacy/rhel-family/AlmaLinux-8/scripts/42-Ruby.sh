#!/bin/bash

#42-Ruby
printf "\nPlease Choose Your Ruby Version \n\n1-)Ruby (From Official Package)\n2-)Ruby (Snap)\n\nPlease Select Your Ruby Version:"
read -r ruby_version
if [ "$ruby_version" = "1" ];then
    sudo dnf -vy install ruby
    ruby --version
elif [ "$ruby_version" = "2" ];then
    sudo dnf -vy remove ruby
    sudo snap install ruby --classic
else
    echo "Out of options please choose between 1-4"
fi