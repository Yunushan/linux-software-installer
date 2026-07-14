#!/bin/bash
# Variables
cpuarch=`uname -m`
superuser=`getent group sudo | cut -d: -f4`
codename=`lsb_release -cs`
# Select Which Softwares to be Installed

choice () {
    local choice=$1
    if [[ ${opts[choice]} ]] # toggle
    then
        opts[choice]=
    else
        opts[choice]=+
    fi
}
PS3='
Please enter your choice(s): '
while :
do
clear
options=("PHP7.3 (PPA) ${opts[1]}" "Nginx (PPA) ${opts[2]}" "Apache2 (PPA) ${opts[3]}" "VLC (Snap) ${opts[4]}" "Visual Studio Code ${opts[5]}" "FFMPEG (PPA) ${opts[6]}" 
"Monitoring Tools ${opts[7]}" "WineHQ Staging ${opts[8]}" "Qbittorrent ${opts[9]}" "Netbeans 10 ${opts[10]}" "Gimp (Flatpak) ${opts[11]}" "Nmap ${opts[12]}" 
"Skype ${opts[13]}" "Steam ${opts[14]}" "OBS-Studio (PPA) ${opts[15]}" "OpenShot ${opts[16]}" "Oracle VirtualBox 6 ${opts[17]}" "Sublime Text 3 ${opts[18]}" 
"Brave (Web Browser) ${opts[19]}" "Tor Browser ${opts[20]}" "VMware Workstation 15 Pro ${opts[21]}" "Eclipse IDE ${opts[22]}" 
"Vuze (Bittorrent Client) ${opts[23]}" "Utorrent (Snap) ${opts[24]}" "Deluge (PPA) ${opts[25]}" "Transmission (PPA) ${opts[26]}" "MPV (PPA) ${opts[27]}" "SMPlayer (PPA) ${opts[28]}"
"Kazam (PPA) ${opts[29]}" "Audocity (PPA) ${opts[30]}" "PlayonLinux ${opts[31]}" "Conky (PPA) ${opts[32]}" "HandBrake (PPA) ${opts[33]}" "Inkscape (PPA) ${opts[34]}" 
"Signal ${opts[35]}" "Dropbox ${opts[36]}" "WPS Office ${opts[37]}" "OpenOffice ${opts[38]}" "MonoDevelop ${opts[39]}" "Kodi (PPA) ${opts[40]}" 
"Unity 2018.3.0f2 ${opts[41]}" "Unreal Engine 4 ${opts[42]}" "Krita (64 Bit Only) ${opts[43]}" "Kdenlive (64 Bit Only) ${opts[44]}" "Qt ${opts[45]}" "AptanaStudio3 (64 Bit Only) ${opts[46]}"
"Irssi (PPA) (IRC) ${opts[47]}" "Clementine (PPA) ${opts[48]}" "TeamViewer 14 ${opts[49]}" "TeamSpeak 3 ${opts[50]}" "Discord ${opts[51]}" "Android Studio ${opts[52]}"
"Geary (PPA) ${opts[53]}" "Uget ${opts[54]}" "Sayonara (PPA) ${opts[55]}" "Franz (Messaging App) ${opts[56]}" "balenaEtcher ${opts[57]}" "Vivaldi ${opts[58]}"
"Spotify ${opts[59]}" "MusicBrainz Picard (PPA) ${opts[60]}" "pCloud Drive ${opts[61]}" "Timeshift (PPA) ${opts[62]}" "Peek (GIF Recorder) (PPA) ${opts[63]}" 
"Stacer (System Optimizer) (PPA) ${opts[64]}" "Jenkins ${opts[65]}" "Docker ${opts[66]}" "Python 2 & 3 (From Source) ${opts[67]}" "Telegram (PPA) ${opts[68]}" 
"Brackets (PPA) ${opts[69]}" "Shotcut (Snap) ${opts[70]}" "Okular (Document Viewer) (Snap) ${opts[71]}" "WeeChat (IRC) ${opts[72]}" 
"Quassel (IRC) (PPA) ${opts[73]}" "Konversation (IRC) ${opts[74]}" "Ramme (Instagram Desktop App) ${opts[75]}" "Atom ${opts[76]}"
"Google Play Music Player ${opts[77]}" "Ubuntu Cleaner (PPA) ${opts[78]}" "Pixbuf ${opts[79]}" "SimpleScreenRecorder (PPA) ${opts[80]}" "Neofetch (PPA) ${opts[81]}" 
"Shutter (Screenshot Tool) (PPA) ${opts[82]}" "Bitwarden (Snap) ${opts[83]}" "Plank (Dock) (PPA) ${opts[84]}" "Thonny (IDE) ${opts[85]}" "Bluefish (PPA) ${opts[86]}" 
"Vim (PPA) ${opts[87]}" "Geany (IDE) (PPA) ${opts[88]}" "Gnu Emacs (PPA) ${opts[89]}" "GitKraken (Snap) ${opts[90]}" "Wire (Snap) ${opts[91]}" "Kubectl ${opts[92]}"
"Zenkit (Snap) ${opts[93]}" "Wormhole (Snap) ${opts[94]}" "Hexchat (Snap) ${opts[95]}" "Wings 3D ${opts[96]}" "MakeHuman (PPA) ${opts[97]}" "Grub Customizer (PPA) ${opts[98]}"
"4K Video Downloader (64 Bit) ${opts[99]}" "4K Youtube to MP3 (64 Bit) ${opts[100]}" "4K Stogram (64 Bit) ${opts[101]}" "4K Slideshow Maker (64 Bit) ${opts[102]}"
"4K Video to MP3 (64 Bit) ${opts[103]}" "Neovim (PPA) ${opts[104]}" "Light Table (PPA) ${opts[105]}" "GCC 8 & G++ 8 (PPA) ${opts[106]}" "Cmake (Python pip) ${opts[107]}" 
"Textadept (Editor) ${opts[108]}" "Tixati (P2P Torrent) ${opts[109]}" "Darktable (PPA) ${opts[110]}" "Liferea (PPA) ${opts[111]}" "Typecatcher (PPA) ${opts[112]}" 
"Caffeine (PPA) ${opts[113]}" "XnConvert ${opts[114]}" "Riot (PPA) ${opts[115]}" "Jitsi Meet (PPA) ${opts[116]}" "Feedreader (PPA) ${opts[117]}" 
"Go For It (PPA) ${opts[118]}" "Calibre ${opts[119]}" "Rambox Community Edition (Snap) ${opts[120]}" "Java 8 JDK (PPA) ${opts[121]}" "Java 11 JDK (PPA) ${opts[122]}"
"Hiri (Snap) ${opts[123]}" "Variety (PPA) ${opts[124]}" "Flash Player (Pepper Flash) ${opts[125]}" "Electron Player (Snap) ${opts[126]}" 
"Plex Media Server (Snap) ${opts[127]}" "E-tools (Snap) ${opts[128]}" "Blender (Snap) ${opts[129]}" "IrfanView (Snap) ${opts[130]}" "Altus ${opts[131]}" 
"Mumble (PPA) ${opts[132]}" "Pale Moon ${opts[133]}" "Midori ${opts[134]}" "Simplenote (Snap) ${opts[135]}" "Midnight Commander ${opts[136]}" 
"Pycharm Community Edition ${opts[137]}" "Postman (PPA) ${opts[138]}" "Notepad-Plus-Plus (Snap) ${opts[139]}" "PhpStorm (Snap) ${opts[140]}" 
"Powershell (Snap) ${opts[141]}" "Cacher (Snap) ${opts[142]}" "WebStorm (Snap) ${opts[143]}" "Insomnia (Snap) ${opts[144]}" "Opera (Snap) ${opts[145]}" 
"Google Chrome (PPA) ${opts[146]}" "Chromium (Snap) ${opts[147]}" "DBeaver Community Edition (PPA) ${opts[148]}" "Valentina Studio ${opts[149]}" "SQuirreL SQL (Snap) ${opts[150]}" 
"DbVisualizer ${opts[151]}" "DataGrip (Snap) ${opts[152]}" "PgAdmin ${opts[153]}" "Remmina (PPA) ${opts[154]}" "Anydesk ${opts[155]}" "Vnc4server ${opts[156]}" 
"DVBlast ${opts[157]}" "ElectronMail (Snap) ${opts[158]}" "LXD (Snap) ${opts[159]}" "Done ${opts[160]}")
    select opt in "${options[@]}"
    do
        case $opt in
            "PHP7.3 (PPA) ${opts[1]}")
                choice 1
                break
                ;;
            "Nginx (PPA) ${opts[2]}")
                choice 2
                break
                ;;
            "Apache2 (PPA) ${opts[3]}")
                choice 3
                break
                ;;
            "VLC (Snap) ${opts[4]}")
                choice 4
                break
                ;;
            "Visual Studio Code ${opts[5]}")
                choice 5
                break
                ;;
            "FFMPEG (PPA) ${opts[6]}")
                choice 6
                break
                ;;
            "Monitoring Tools ${opts[7]}")
                choice 7
                break
                ;;
            "WineHQ Staging ${opts[8]}")
                choice 8
                break
                ;;
            "Qbittorrent ${opts[9]}")
                choice 9
                break
                ;;
            "Netbeans 10 ${opts[10]}")
                choice 10
                break
                ;;
            "Gimp (Flatpak) ${opts[11]}")
                choice 11
                break
                ;;
            "Nmap ${opts[12]}")
                choice 12
                break
                ;;
            "Skype ${opts[13]}")
                choice 13
                break
                ;;
            "Steam ${opts[14]}")
                choice 14
                break
                ;;
            "OBS-Studio (PPA) ${opts[15]}")
                choice 15
                break
                ;;
            "OpenShot ${opts[16]}")
                choice 16
                break
                ;;
            "Oracle VirtualBox 6 ${opts[17]}")
                choice 17
                break
                ;;
            "Sublime Text 3 ${opts[18]}")
                choice 18
                break
                ;;
            "Brave (Web Browser) ${opts[19]}")
                choice 19
                break
                ;;
            "Tor Browser ${opts[20]}")
                choice 20
                break
                ;;
            "VMware Workstation 15 Pro ${opts[21]}")
                choice 21
                break
                ;;
            "Eclipse IDE ${opts[22]}")
                choice 22
                break
                ;;
            "Vuze (Bittorrent Client) ${opts[23]}")
                choice 23
                break
                ;;
            "Utorrent (Snap) ${opts[24]}")
                choice 24
                break
                ;;
            "Deluge (PPA) ${opts[25]}")
                choice 25
                break
                ;;
            "Transmission (PPA) ${opts[26]}")
                choice 26
                break
                ;;
            "MPV (PPA) ${opts[27]}")
                choice 27
                break
                ;;
            "SMPlayer (PPA) ${opts[28]}")
                choice 28
                break
                ;;
            "Kazam (PPA) ${opts[29]}")
                choice 29
                break
                ;;
            "Audocity (PPA) ${opts[30]}")
                choice 30
                break
                ;;
            "PlayonLinux ${opts[31]}")
                choice 31
                break
                ;;
            "Conky (PPA) ${opts[32]}")
                choice 32
                break
                ;;
            "HandBrake (PPA) ${opts[33]}")
                choice 33
                break
                ;;
            "Inkscape (PPA) ${opts[34]}")
                choice 34
                break
                ;;
            "Signal ${opts[35]}")
                choice 35
                break
                ;;
            "Dropbox ${opts[36]}")
                choice 36
                break
                ;;
            "WPS Office ${opts[37]}")
                choice 37
                break
                ;;
            "OpenOffice ${opts[38]}")
                choice 38
                break
                ;;
            "MonoDevelop ${opts[39]}")
                choice 39
                break
                ;;
            "Kodi (PPA) ${opts[40]}")
                choice 40
                break
                ;;
            "Unity 2018.3.0f2 ${opts[41]}")
                choice 41
                break
                ;;
            "Unreal Engine 4 ${opts[42]}")
                choice 42
                break
                ;;
            "Krita (64 Bit Only) ${opts[43]}")
                choice 43
                break
                ;;
            "Kdenlive (64 Bit Only) ${opts[44]}")
                choice 44
                break
                ;;
            "Qt ${opts[45]}")
                choice 45
                break
                ;;
            "AptanaStudio3 (64 Bit Only) ${opts[46]}")
                choice 46
                break
                ;;
            "Irssi (PPA) (IRC) ${opts[47]}")
                choice 47
                break
                ;;
            "Clementine (PPA) ${opts[48]}")
                choice 48
                break
                ;;
            "TeamViewer 14 ${opts[49]}")
                choice 49
                break
                ;;
            "TeamSpeak 3 ${opts[50]}")
                choice 50
                break
                ;;
             "Discord ${opts[51]}")
                choice 51
                break
                ;;
            "Android Studio ${opts[52]}")
                choice 52
                break
                ;;
            "Geary (PPA) ${opts[53]}")
                choice 53
                break
                ;;
            "Uget ${opts[54]}")
                choice 54
                break
                ;;
            "Sayonara (PPA) ${opts[55]}")
                choice 55
                break
                ;;
           "Franz (Messaging App) ${opts[56]}")
                choice 56
                break
                ;;
            "balenaEtcher ${opts[57]}")
                choice 57
                break
                ;;
            "Vivaldi ${opts[58]}")
                choice 58
                break
                ;;
            "Spotify ${opts[59]}")
                choice 59
                break
                ;;
            "MusicBrainz Picard (PPA) ${opts[60]}")
                choice 60
                break
                ;;
            "pCloud Drive ${opts[61]}")
                choice 61
                break
                ;;
            "Timeshift (PPA) ${opts[62]}")
                choice 62
                break
                ;;
            "Peek (GIF Recorder) (PPA) ${opts[63]}")
                choice 63
                break
                ;;
            "Stacer (System Optimizer) (PPA) ${opts[64]}")
                choice 64
                break
                ;;
            "Jenkins ${opts[65]}")
                choice 65
                break
                ;;
            "Docker ${opts[66]}")
                choice 66
                break
                ;;
            "Python 2 & 3 (From Source) ${opts[67]}")
                choice 67
                break
                ;;
            "Telegram (PPA) ${opts[68]}")
                choice 68
                break
                ;;
            "Brackets (PPA) ${opts[69]}")
                choice 69
                break
                ;;
            "Shotcut (Snap) ${opts[70]}")
                choice 70
                break
                ;;
            "Okular (Document Viewer) (Snap) ${opts[71]}")
                choice 71
                break
                ;;
            "WeeChat (IRC) ${opts[72]}")
                choice 72
                break
                ;;
            "Quassel (IRC) (PPA) ${opts[73]}")
                choice 73
                break
                ;;
            "Konversation (IRC) ${opts[74]}")
                choice 74
                break
                ;;
            "Ramme (Instagram Desktop App) ${opts[75]}")
                choice 75
                break
                ;;
            "Atom ${opts[76]}")
                choice 76
                break
                ;;
            "Google Play Music Player ${opts[77]}")
                choice 77
                break
                ;;
            "Ubuntu Cleaner (PPA) ${opts[78]}")
                choice 78
                break
                ;;
            "Pixbuf ${opts[79]}")
                choice 79
                break
                ;;
            "SimpleScreenRecorder (PPA) ${opts[80]}")
                choice 80
                break
                ;;
            "Neofetch (PPA) ${opts[81]}")
                choice 81
                break
                ;;
            "Shutter (Screenshot Tool) (PPA) ${opts[82]}")
                choice 82
                break
                ;;
            "Bitwarden (Snap) ${opts[83]}")
                choice 83
                break
                ;;
            "Plank (Dock) (PPA) ${opts[84]}")
                choice 84
                break
                ;;
            "Thonny (IDE) ${opts[85]}")
                choice 85
                break
                ;;
            "Bluefish (PPA) ${opts[86]}")
                choice 86
                break
                ;;
            "Vim (PPA) ${opts[87]}")
                choice 87
                break
                ;;
            "Geany (IDE) (PPA) ${opts[88]}")
                choice 88
                break
                ;;
            "Gnu Emacs (PPA) ${opts[89]}")
                choice 89
                break
                ;;
            "GitKraken (Snap) ${opts[90]}")
                choice 90
                break
                ;;
            "Wire (Snap) ${opts[91]}")
                choice 91
                break
                ;;
            "Kubectl ${opts[92]}")
                choice 92
                break
                ;;
            "Zenkit (Snap) ${opts[93]}")
                choice 93
                break
                ;;
            "Wormhole (Snap) ${opts[94]}")
                choice 94
                break
                ;;
            "Hexchat (Snap) ${opts[95]}")
                choice 95
                break
                ;;
            "Wings 3D ${opts[96]}")
                choice 96
                break
                ;;
            "MakeHuman (PPA) ${opts[97]}")
                choice 97
                break
                ;;
            "Grub Customizer (PPA) ${opts[98]}")
                choice 98
                break
                ;;
            "4K Video Downloader (64 Bit) ${opts[99]}")
                choice 99
                break
                ;;
            "4K Youtube to MP3 (64 Bit) ${opts[100]}")
                choice 100
                break
                ;;
            "4K Stogram (64 Bit) ${opts[101]}")
                choice 101
                break
                ;;
            "4K Slideshow Maker (64 Bit) ${opts[102]}")
                choice 102
                break
                ;;
            "4K Video to MP3 (64 Bit) ${opts[103]}")
                choice 103
                break
                ;;
            "Neovim ${opts[104]}")
                choice 104
                break
                ;;
            "Light Table (PPA) ${opts[105]}")
                choice 105
                break
                ;;
            "GCC 8 & G++ 8 (PPA) ${opts[106]}")
                choice 106
                break
                ;;
            "Cmake (Python pip) ${opts[107]}")
                choice 107
                break
                ;;
            "Textadept (Editor) ${opts[108]}")
                choice 108
                break
                ;;
            "Tixati (P2P Torrent) ${opts[109]}")
                choice 109
                break
                ;;
            "Darktable (PPA) ${opts[110]}")
                choice 110
                break
                ;;
            "Liferea (PPA) ${opts[111]}")
                choice 111
                break
                ;;
            "Typecatcher (PPA) ${opts[112]}")
                choice 112
                break
                ;;
            "Caffeine (PPA) ${opts[113]}")
                choice 113
                break
                ;;
            "XnConvert ${opts[114]}")
                choice 114
                break
                ;;
            "Riot (PPA) ${opts[115]}")
                choice 115
                break
                ;;
            "Jitsi Meet (PPA) ${opts[116]}")
                choice 116
                break
                ;;
            "Feedreader (PPA) ${opts[117]}")
                choice 117
                break
                ;;
            "Go For It (PPA) ${opts[118]}")
                choice 118
                break
                ;;
            "Calibre ${opts[119]}")
                choice 119
                break
                ;;
            "Rambox Community Edition (Snap) ${opts[120]}")
                choice 120
                break
                ;;
            "Java 8 JDK (PPA) ${opts[121]}")
                choice 121
                break
                ;;
            "Java 11 JDK (PPA) ${opts[122]}")
                choice 122
                break
                ;;
            "Hiri (Snap) ${opts[123]}")
                choice 123
                break
                ;;
            "Variety (PPA) ${opts[124]}")
                choice 124
                break
                ;;
            "Flash Player (Pepper Flash) ${opts[125]}")
                choice 125
                break
                ;;
            "Electron Player (Snap) ${opts[126]}")
                choice 126
                break
                ;;
            "Plex Media Server (Snap) ${opts[127]}")
                choice 127
                break
                ;;
            "E-tools (Snap) ${opts[128]}")
                choice 128
                break
                ;;
            "Blender (Snap) ${opts[129]}")
                choice 129
                break
                ;;
            "IrfanView (Snap) ${opts[130]}")
                choice 130
                break
                ;;
            "Altus ${opts[131]}")
                choice 131
                break
                ;;
            "Mumble (PPA) ${opts[132]}")
                choice 132
                break
                ;;
            "Pale Moon ${opts[133]}")
                choice 133
                break
                ;;
            "Midori ${opts[134]}")
                choice 134
                break
                ;;
            "Simplenote (Snap) ${opts[135]}")
                choice 135
                break
                ;;
            "Midnight Commander ${opts[136]}")
                choice 136
                break
                ;;
            "Pycharm Community Edition ${opts[137]}")
                choice 137
                break
                ;;
            "Postman (PPA) ${opts[138]}")
                choice 138
                break
                ;;
            "Notepad-Plus-Plus (Snap) ${opts[139]}")
                choice 139
                break
                ;;
            "PhpStorm (Snap) ${opts[140]}")
                choice 140
                break
                ;;
            "Powershell (Snap) ${opts[141]}")
                choice 141
                break
                ;;
            "Cacher (Snap) ${opts[142]}")
                choice 142
                break
                ;;
            "WebStorm (Snap) ${opts[143]}")
                choice 143
                break
                ;;
            "Insomnia (Snap) ${opts[144]}")
                choice 144
                break
                ;;
            "Opera (Snap) ${opts[145]}")
                choice 145
                break
                ;;
            "Google Chrome (PPA) ${opts[146]}")
                choice 146
                break
                ;;
            "Chromium (Snap) ${opts[147]}")
                choice 147
                break
                ;;
            "DBeaver Community Edition (PPA) ${opts[148]}")
                choice 148
                break
                ;;
            "Valentina Studio ${opts[149]}")
                choice 149
                break
                ;;
            "SQuirreL SQL (Snap) ${opts[150]}")
                choice 150
                break
                ;;
            "DbVisualizer ${opts[151]}")
                choice 151
                break
                ;;
            "DataGrip ${opts[152]}")
                choice 152
                break
                ;;
            "PgAdmin ${opts[153]}")
                choice 153
                break
                ;;
            "Remmina (PPA) ${opts[154]}")
                choice 154
                break
                ;;
            "Anydesk ${opts[155]}")
                choice 155
                break
                ;;
            "Vnc4server ${opts[156]}")
                choice 156
                break
                ;;
            "DVBlast ${opts[157]}")
                choice 157
                break
                ;;
            "ElectronMail (Snap) ${opts[158]}")
                choice 158
                break
                ;;
            "LXD (Snap) ${opts[159]}")
                choice 159
                break
                ;;
            "Done ${opts[160]}")
                break 2
                ;;
            *) printf '%s\n' 'Please Choose Between 1-160';;
        esac
    done
done

printf '%s\n\n' 'Options chosen:'
for opt in "${!opts[@]}"
do
    if [[ ${opts[opt]} ]]
    then
        printf '%s\n' "Option $opt"
        fi
done

if [ "${opts[opt]}" = "" ];then
exit
fi

if [ "$opt" = "4" ] || [ "$opt" = "5" ] || [ "$opt" = "9" ] || [ "$opt" = "10" ] || [ "$opt" = "11" ] || [ "$opt" = "12" ] || [ "$opt" = "13" ] || [ "$opt" = "14" ] || \
 [ "$opt" = "15" ] || [ "$opt" = "16" ] || [ "$opt" = "17" ] || [ "$opt" = "18" ] || [ "$opt" = "19" ] || [ "$opt" = "20" ] || [ "$opt" = "21" ] || [ "$opt" = "22" ] || \
 [ "$opt" = "23" ] || [ "$opt" = "24" ] || [ "$opt" = "25" ] || [ "$opt" = "26" ] || [ "$opt" = "27" ] || [ "$opt" = "28" ] || [ "$opt" = "29" ] || [ "$opt" = "30" ] || \
 [ "$opt" = "31" ] || [ "$opt" = "33" ] || [ "$opt" = "34" ] || [ "$opt" = "35" ] || [ "$opt" = "36" ] || [ "$opt" = "37" ] || [ "$opt" = "38" ] || [ "$opt" = "39" ] || \
 [ "$opt" = "40" ] || [ "$opt" = "41" ] || [ "$opt" = "42" ] || [ "$opt" = "43" ] || [ "$opt" = "44" ] || [ "$opt" = "45" ] || [ "$opt" = "46" ] || [ "$opt" = "48" ] || \
 [ "$opt" = "49" ] || [ "$opt" = "50" ] || [ "$opt" = "51" ] || [ "$opt" = "52" ] || [ "$opt" = "53" ] || [ "$opt" = "54" ] || [ "$opt" = "55" ] || [ "$opt" = "56" ] || \
 [ "$opt" = "57" ] || [ "$opt" = "58" ] || [ "$opt" = "59" ] || [ "$opt" = "60" ] || [ "$opt" = "61" ] || [ "$opt" = "62" ] || [ "$opt" = "63" ] || [ "$opt" = "64" ] || \
 [ "$opt" = "68" ] || [ "$opt" = "69" ] || [ "$opt" = "70" ] || [ "$opt" = "71" ] || [ "$opt" = "73" ] || [ "$opt" = "74" ] || [ "$opt" = "75" ] || [ "$opt" = "76" ] || \
 [ "$opt" = "77" ] || [ "$opt" = "78" ] || [ "$opt" = "79" ] || [ "$opt" = "80" ] || [ "$opt" = "82" ] || [ "$opt" = "83" ] || [ "$opt" = "85" ] || [ "$opt" = "86" ] || \
 [ "$opt" = "88" ] || [ "$opt" = "89" ] || [ "$opt" = "90" ] || [ "$opt" = "91" ] || [ "$opt" = "93" ] || [ "$opt" = "95" ] || [ "$opt" = "96" ] || [ "$opt" = "97" ] || \
 [ "$opt" = "98" ] || [ "$opt" = "99" ] || [ "$opt" = "100" ] || [ "$opt" = "101" ] || [ "$opt" = "102" ] || [ "$opt" = "103" ] || [ "$opt" = "105" ] || [ "$opt" = "108" ] || \
 [ "$opt" = "109" ] || [ "$opt" = "110" ] || [ "$opt" = "111" ] || [ "$opt" = "112" ] || [ "$opt" = "113" ] || [ "$opt" = "114" ] || [ "$opt" = "115" ] || [ "$opt" = "116" ] || \
 [ "$opt" = "117" ] || [ "$opt" = "118" ] || [ "$opt" = "119" ] || [ "$opt" = "120" ] || [ "$opt" = "123" ] || [ "$opt" = "126" ] || [ "$opt" = "127" ] || \
 [ "$opt" = "128" ] || [ "$opt" = "129" ] || [ "$opt" = "130" ] || [ "$opt" = "131" ] || [ "$opt" = "132" ] || [ "$opt" = "133" ] || [ "$opt" = "134" ] || \
 [ "$opt" = "135" ] || [ "$opt" = "137" ] || [ "$opt" = "138" ] || [ "$opt" = "139" ] || [ "$opt" = "140" ] || [ "$opt" = "141" ] || [ "$opt" = "142" ] || \
 [ "$opt" = "143" ] || [ "$opt" = "144" ] || [ "$opt" = "145" ] || [ "$opt" = "146" ] || [ "$opt" = "147" ] || [ "$opt" = "148" ] || [ "$opt" = "149" ] || [ "$opt" = "150" ] || \
 [ "$opt" = "151" ] || [ "$opt" = "152" ] || [ "$opt" = "153" ] || [ "$opt" = "154" ] || [ "$opt" = "155" ] || [ "$opt" = "158" ]
then

printf "\nDo You Want to Enable Create Shortcut ? (Y/N):"
read shortcut
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
echo "Shortcut Enabled"
else
echo "Shortcut Disabled"
fi
sleep 1


# Loading Bar

printf "Installation starting"
value=0
while [ $value -lt 600 ]
do
value=$((value+20))
printf "."
sleep 0.05
done
printf "\n"


sudo apt update
sudo apt install wget curl -y
sudo apt install --no-install-recommends gnome-panel -y
printf "\n"

# Signing keys Folder
if [ -d "/home/$superuser/Downloads/signing-keys/" ];then
:
else
mkdir -p /home/$superuser/Downloads/signing-keys/
fi
# Downloaded tmp files
if [ -d "/home/$superuser/Downloads/TempDL/" ];then
:
else
mkdir -p /home/$superuser/Downloads/TempDL/
fi
# Desktop Folder
if [ -d "/home/$superuser/Destkop/" ];then
:
else
mkdir -p /home/$superuser/Desktop/
fi
#Virtualbox
vboxversion=$(wget -qO - https://download.virtualbox.org/virtualbox/LATEST.TXT)

# INSTALLATION BY SELECTION
# 1) PHP 7.3 (PPA)
for opt in "${!opts[@]}"
do
    if [[ ${opts[opt]} ]]
    then
        case $opt in 
1)
sudo apt install -y python-software-properties
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php7.3 php7.3-w php7.3-fpm php7.3-pdo php7.3-mysql php7.3-curl php7.3-gd php7.3-mbstring
printf "\nPhp installation Has Finished\n\n"
;;

# 2- Nginx (PPA)
2)

#NGINX 

echo " 

#NGINX

deb http://nginx.org/packages/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
sudo apt update
sudo apt install nginx -y
printf "\nNginx installation Has Finished\n\n"
;;


# 3- Apache2 (PPA)
3)
sudo add-apt-repository ppa:ondrej/apache2 -y
sudo apt update
sudo apt install apache2 -y
printf "\nApache2 installation Has Finished\n\n"
;;

4) # VLC

sudo snap install vlc
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
vlclogolocation=`locate vlc.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/vlc
Name=VLC
Comment=VLC
Icon=$vlclogolocation" >> /home/$superuser/Desktop/vlc.desktop
sudo chmod +x /home/$superuser/vlc.desktop
else
:
fi
printf "\nVLC installation Has Finished\n\n"
;;

5) # Visual Studio Code

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt install apt-transport-https -y
sudo apt update
sudo apt install code -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Desktop/Visual Studio Code
Name=Visual Studio Code
Comment=Visual Studio Code
Icon=/usr/share/code/resources/app/resources/linux/code.png" >> /home/$superuser/Desktop/visual-studio-code.desktop
sudo chmod +x /home/$superuser/Desktop/visual-studio-code.desktop
else
:
fi
printf "\nVisual Studio Code installation Has Finished\n\n"
;;

6) #FFMPEG (PPA)

sudo add-apt-repository ppa:jonathonf/ffmpeg-4 -y
sudo apt update
sudo apt install ffmpeg -y
printf "\nFfmpeg installation Has Finished"
;;

7) #Monitoring Tools

sudo apt install htop iftop atop glances monit powertop iotop apachetop -y
printf "\nMonitoring Tools installation Has Finished\n\n"
;;

8) # WINEHQ


if [ "$cpuarch" = "x86_64" ];then

sudo dpkg --add-architecture i386
wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key
sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main' 
sudo apt update
sudo apt install --install-recommends winehq-staging -y
sudo mv winehq.key /root/signing-keys/

elif [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i686" ];then

wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key
sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main' 
sudo apt update
sudo apt install --install-recommends winehq-staging -y
sudo mv winehq.key /home/$superuser/Downloads/signing-keys/
fi
printf "\nWineHQ installation Has Finished\n\n"
;;

9) # Qbittorrent

sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable -y
sudo apt update 
sudo apt install qbittorrent -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/qbittorrent
Name=Qbittorrent
Comment=Qbittorrent
Icon=/usr/share/icons/hicolor/192x192/qbittorrent.png" >> /home/$superuser/Desktop/qbittorrent.desktop
sudo chmod +x /home/$superuser/qbittorrent.desktop
else
:
fi
printf "\nQbittorrent installation Has Finished\n\n"
;;

10) # NetBeans 10

wget https://www-eu.apache.org/dist/incubator/netbeans/incubating-netbeans/incubating-10.0/incubating-netbeans-10.0-bin.zip
sudo unzip incubating-netbeans-10.0-bin.zip -d /home/$superuser/Downloads/TempDL/
sudo apt install default-jdk -y
sudo mv incubating-netbeans-10.0-bin.zip /home/$superuser/Downloads/TempDL/
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/netbeans/bin/netbeans
Name=Netbeans
Comment=Netbeans
Icon=/home/$superuser/Downloads/TempDL/netbeans/nb/netbeans.icns" >> /home/$superuser/Desktop/Netbeans.desktop
sudo chmod +x /home/$superuser/Desktop/Netbeans.desktop
else
:
fi
printf "\nNetBeans 10 installation Has Finished\n\n"
;;

11) # Gimp (Flatpak)

sudo add-apt-repository ppa:alexlarsson/flatpak -y
sudo apt update
sudo apt install flatpak -y
wget https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref
flatpak install https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref -y
sudo mv org.gimp.GIMP.flatpakref /home/$superuser/Downloads/TempDL/
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/netbeans/bin/netbeans
Name=Netbeans
Comment=Netbeans
Icon=/home/$superuser/Downloads/TempDL/netbeans/nb/netbeans.icns" >> /home/$superuser/Desktop/Netbeans.desktop
sudo chmod +x /home/$superuser/Desktop/Netbeans.desktop
else
:
fi
printf "\nGimp installation Has Finished\n\n"
;;

12) # Nmap
sudo apt install lynx -y
if [ "$cpuarch" = "x86_64" ];then
sudo apt install alien -y
nmap64=`lynx -dump https://nmap.org/dist/ | awk '/nmap-7.*\.x86_64.rpm$/{url=$2}END{print url}'`
wget -O /home/$superuser/Downloads/TempDL/nmap.x86_64.rpm $nmap64
sudo alien -kvi /home/$superuser/Downloads/TempDL/nmap.x86_64.rpm
wget -O /home/$superuser/Downloads/TempDL/nmap.png https://www.macupdate.com/images/icons256/36710.png


elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then

sudo apt install alien -y
nmap32=`lynx -dump https://nmap.org/dist/ | awk '/nmap-7.*\.i686.rpm$/{url=$2}END{print url}'`
wget -O /home/$superuser/Downloads/TempDL/nmap.i686.rpm $nmap32
sudo alien -kvi /home/$superuser/Downloads/TempDL/nmap-7*.i686.rpm
wget -O /home/$superuser/Downloads/TempDL/nmap.png https://www.macupdate.com/images/icons256/36710.png

fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/nmap
Name=Nmap
Comment=Nmap
Icon=/home/$superuser/Downloads/TempDL/nmap.png" >> /home/$superuser/Desktop/nmap.desktop
sudo chmod +x /home/$superuser/Desktop/nmap.desktop
else
:
fi
printf "\nNMap installation Has Finished\n\n"
;;

13) # Skype

wget https://go.skype.com/skypeforlinux-64.deb
sudo dpkg -i skypeforlinux-64.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/skypeforlinux
Name=Skype
Comment=Skype
Icon=/usr/share/icons/hicolor/256x256/apps/skypeforlinux.png" >> /home/$superuser/Desktop/skype.desktop
sudo chmod +x /home/$superuser/Desktop/skype.desktop
else
:
fi
printf "\nSkype installation Has Finished\n\n"
;;

14) # Steam
wget https://steamcdn-a.akamaihd.net/client/installer/steam.deb
sudo dpkg -i steam.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/steam
Name=Steam
Comment=Steam
Icon=/usr/share/icons/hicolor/256x256/apps/steam.png" >> /home/$superuser/Desktop/steam.desktop
sudo chmod +x /home/$superuser/Desktop/steam.desktop
else
:
fi
printf "\nSteam installation Has Finished\n\n"
;;

15) # OBS-studio

sudo apt install ffmpeg
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install obs-studio -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/obs
Name=OBS-Studio
Comment=OBS-Studio
Icon=/usr/share/icons/hicolor/256x256/apps/obs.png" >> /home/$superuser/Desktop/obs.desktop
sudo chmod +x /home/$superuser/Desktop/obs.desktop
else
:
fi
printf "\nOBS-Studio installation Has Finished\n\n"
;;

16) # OpenShot
sudo add-apt-repository ppa:openshot.developers/ppa -y
sudo apt update
sudo apt install openshot-qt -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/openshot-qt
Name=Openshot
Comment=Openshot
Icon=/usr/share/icons/hicolor/256/apps/openshot-qt.png" >> /home/$superuser/Desktop/openshot.desktop
sudo chmod +x /home/$superuser/Desktop/openshot.desktop
else
:
fi
printf "\nOpenShot installation Has Finished\n\n"
;;

17) #Oracle VirtualBox 6 (With Extension Pack)

wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt update
sudo apt install linux-headers-$(uname -r) dkms -y
sudo apt install virtualbox-6.0 -y
wget -O /home/$superuser/Downloads/TempDL/Oracle_VM_VirtualBox_Extension_Pack-Latest.vbox-extpack "https://download.virtualbox.org/virtualbox/${vboxversion}/Oracle_VM_VirtualBox_Extension_Pack-${vboxversion}.vbox-extpack"
echo "y" | sudo vboxmanage extpack install --replace /home/$superuser/Downloads/TempDL/Oracle_VM_VirtualBox_Extension_Pack-Latest.vbox-extpack
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/virtualbox
Name=Oracle VM VirtualBox
Comment=Oracle VM VirtualBox
Icon=/usr/share/icons/hicolor/64x64/apps/virtualbox.png" >> /home/$superuser/Desktop/virtualbox.desktop
sudo chmod +x /home/$superuser/Desktop/virtualbox.desktop
else
:
fi
printf "\nVirtualBox 6 installation Has Finished\n\n"
;;

18) #Sublime Text 3

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt install apt-transport-https -y
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install sublime-text -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/subl
Name=Sublime Text 3
Comment=Sublime Text 3
Icon=/usr/share/icons/hicolor/256x256/apps/sublime-text.png" >> /home/$superuser/Desktop/sublime-text.desktop
sudo chmod +x /home/$superuser/Desktop/sublime-text.desktop
else
:
fi
printf "\nSublime Text 3 installation Has Finished\n\n"
;;

19) # Brave Web Browser

curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ `lsb_release -sc` main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-`lsb_release -sc`.list
sudo apt update
sudo apt install brave-browser brave-keyring -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/brave-browser
Name=Brave
Comment=Brave
Icon=/usr/share/icons/hicolor/256x256/apps/brave-browser.png" >> /home/$superuser/Desktop/brave-browser.desktop
sudo chmod +x /home/$superuser/Desktop/brave-browser.desktop
else
:
fi
printf "\nBrave Web Browser installation Has Finished\n\n"
;;

20) # Tor Browser
sudo apt install lynx -y
if [ "$cpuarch" = "x86_64" ];then
torlocation64=`lynx -dump https://dist.torproject.org/torbrowser/ | awk '/http/{print $2}' | tail -n 4 | head -n 1`
torlocation64=`lynx -dump $torlocation64 | awk '/http/{print $2}' | grep linux64 | grep en-US.tar.xz | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/tor-browser-linux64.tar.xz $torlocation64
tar xvJf /home/$superuser/Downloads/TempDL/tor-browser-linux64.tar.xz

elif [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i686" ];then
torlocation32=`lynx -dump https://dist.torproject.org/torbrowser/ | awk '/http/{print $2}' | tail -n 4 | head -n 1`
torlocation32=`lynx -dump $torlocation32 | awk '/http/{print $2}' | grep linux32 | grep en-US.tar.xz | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/tor-browser-linux32.tar.xz $torlocation32
tar xvJf /home/$superuser/Downloads/TempDL/tor-browser-linux32.tar.xz
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/tor-browser_en-US/start-tor-browser.desktop
Name=Tor Browser
Comment=Tor Browser
Icon=/home/$superuser/Downloads/TempDL/tor-browser_en-US/Browser/browser/chrome/icons/default64.png" >> /home/$superuser/Desktop/tor-browser.desktop
sudo chmod +x /home/$superuser/Desktop/tor-browser.desktop
else
:
fi
printf "\nTor Browser installation Has Finished\n\n"
;;

21) #VMware Workstation 15 Pro

wget -O /home/$superuser/Downloads/TempDL/VMware-Workstation-15-Pro.bundle https://www.vmware.com/go/getworkstation-linux
sudo apt install gcc build-essential linux-headers-$(uname -r) -y
sudo bash /home/$superuser/Downloads/TempDL/VMware-Workstation-15-Pro.bundle
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/vmware
Name=VMware Workstation 15 Pro
Comment=VMware Workstation 15 Pro
Icon=/usr/share/icons/hicolor/256x256/apps/vmware-workstation.png" >> /home/$superuser/Desktop/vmware-workstation.desktop
sudo chmod +x /home/$superuser/Desktop/vmware-workstation.desktop
else
:
fi
printf "\nVMware Workstation 15 Pro installation Has Finished\n\n"
;;

22) # Eclipse IDE

sudo add-apt-repository ppa:lyzardking/ubuntu-make -y
sudo apt update
sudo apt install ubuntu-make -y

printf "\n"

echo "1-) Eclipse IDE for Java Developers"
echo "2-) Eclipse IDE for Java Enterprise edition Developers"
echo "3-) Eclipse IDE for C/C++ Developer"
echo "4-) Eclipse for PHP Developers"
printf "\nSelect which Eclipse Package Do you Want to install: "
read eclipsechoose

case $eclipsechoose in
1) # Eclipse IDE for Java Developers

umake ide eclipse
printf "\nEclipse installation Has Finished"
;;

2) #Eclipse IDE for Java Enterprise edition Developers

umake ide eclipse-jee
printf "\nEclipse Java installation Has Finished"
;;

3) #Eclipse IDE for C/C++ Developer

umake ide eclipse-cpp
printf "\nEclipse C++ installation Has Finished"
;;

4) # Eclipse for PHP Developers

umake ide eclipse-php
printf "\nEclipse Php installation Has Finished"
;;
esac
printf "\nEclipse installation Has Finished\n\n"
;;

23) #Vuze (Bittorrent Client)

sudo snap install vuze-vs
printf "\nVuze installation Has Finished\n\n"
;;

24) #Utorrent

sudo snap install utorrent
printf "\nUtorrent installation Has Finished\n\n"
;;

25) #Deluge (PPA)

sudo apt install python-software-properties -y
sudo add-apt-repository ppa:deluge-team/ppa -y
sudo apt update
sudo apt install deluge -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/deluge
Name=Deluge
Comment=Deluge
Icon=/usr/share/icons/hicolor/256x256/apps/deluge.png" >> /home/$superuser/Desktop/deluge.desktop
sudo chmod +x /home/$superuser/Desktop/deluge.desktop
else
:
fi
printf "\nDeluge installation Has Finished\n\n"
;;

26) #Transmission (PPA)
sudo add-apt-repository ppa:transmissionbt/ppa -y
sudo apt update
sudo apt install transmission transmission-cli transmission-common transmission-daemon -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/transmission-cli
Name=Transmission
Comment=Transmission
Icon=/usr/share/icons/hicolor/256x256/apps/transmission.png" >> /home/$superuser/Desktop/transmission.desktop
sudo chmod +x /home/$superuser/Desktop/transmission.desktop
else
:
fi
printf "\nTransmission installation Has Finished\n\n"
;;

27) #MPV (PPA)

sudo add-apt-repository ppa:mc3man/mpv-tests -y
sudo apt update
sudo apt install mpv -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/mpv
Name=MPV
Comment=MPV
Icon=/usr/share/icons/hicolor/64x64/apps/mpv.png" >> /home/$superuser/Desktop/mpv.desktop
sudo chmod +x /home/$superuser/Desktop/mpv.desktop
else
:
fi
printf "\nMPV installation Has Finished\n\n"
;;

28) #SMPlayer (PPA)

sudo add-apt-repository ppa:rvm/smplayer -y
sudo apt update
sudo apt install smplayer smplayer-themes smplayer-skins -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/smplayer
Name=Smplayer
Comment=Smplayer
Icon=/usr/share/icons/hicolor/256x256/apps/smplayer.png" >> /home/$superuser/Desktop/smplayer.desktop
sudo chmod +x /home/$superuser/Desktop/smplayer.desktop
else
:
fi
printf "\nSMPlayer installation Has Finished\n\n"
;;

29) # Kazam (PPA)
sudo add-apt-repository ppa:sylvain-pineau/kazam -y
sudo apt update
sudo apt install kazam -y
sudo apt install python3-cairo python3-xlib -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/kazam
Name=Smplayer
Comment=Smplayer
Icon=/usr/share/icons/hicolor/64x64/apps/kazam.png" >> /home/$superuser/Desktop/kazam.desktop
sudo chmod +x /home/$superuser/Desktop/kazam.desktop
else
:
fi
printf "\nKazam installation Has Finished\n\n"
;;

30) # Audocity (PPA)

sudo add-apt-repository ppa:ubuntuhandbook1/audacity -y
sudo apt update
sudo apt install audacity -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/audacity
Name=Audacity
Comment=Audacity
Icon=/usr/share/icons/hicolor/48x48/apps/audacity.png" >> /home/$superuser/Desktop/audacity.desktop
sudo chmod +x /home/$superuser/Desktop/audacity.desktop
else
:
fi
printf "\nAudocity installation Has Finished\n\n"
;;
31) # PlayonLinux

wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
sudo wget http://deb.playonlinux.com/playonlinux_xenial.list -O /etc/apt/sources.list.d/playonlinux.list
sudo apt update
sudo apt install playonlinux -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/playonlinux
Name=Playonlinux
Comment=Playonlinux
Icon=/usr/share/playonlinux/resources/images/setups/top.png" >> /home/$superuser/Desktop/playonlinux.desktop
sudo chmod +x /home/$superuser/Desktop/playonlinux.desktop
else
:
fi
printf "\nPlayonlinux installation Has Finished\n\n"
;;

32) #Conky (PPA)

sudo apt install conky-all -y
sudo apt-add-repository ppa:teejee2008/ppa -y
sudo apt update
sudo apt install conky-manager -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/conky-manager
Name=Conky-Manager
Comment=Conky-Manager
Icon=/usr/share/conky-manager/images/conky-manager.png" >> /home/$superuser/Desktop/conky-manager.desktop
sudo chmod +x /home/$superuser/Desktop/conky-manager.desktop
else
:
fi
printf "\nConky installation Has Finished\n\n"
;;

33) #HandBrake (PPA)

sudo add-apt-repository ppa:stebbins/handbrake-releases -y
sudo apt update
sudo apt install handbrake-cli handbrake-gtk -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/ghb
Name=HandBrake
Comment=HandBrake
Icon=/usr/share/icons/hicolor/scalable/apps/fr.handbrake.ghb.svg" >> /home/$superuser/Desktop/handbrake.desktop
sudo chmod +x /home/$superuser/Desktop/handbrake.desktop
else
:
fi
printf "\nHandBrake installation Has Finished\n\n"
;;
34) #Inkscape (PPA)

sudo add-apt-repository ppa:inkscape.dev/stable -y
sudo apt update
sudo apt install inkscape -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/inkscape
Name=Inkscape
Comment=Inkscape
Icon=/usr/share/inkscape/icons/inkscape.svg" >> /home/$superuser/Desktop/inkscape.desktop
sudo chmod +x /home/$superuser/Desktop/inkscape.desktop
else
:
fi
printf "\nInkscape installation Has Finished\n\n"
;;

35) #Signal

sudo apt install curl -y
curl -s https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
sudo apt update
sudo apt install signal-desktop -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/Signal/signal-desktop
Name=Signal-Desktop
Comment=Signal-Desktop
Icon=/usr/share/icons/hicolor/256x256/apps/signal-desktop.png" >> /home/$superuser/Desktop/signal-desktop.desktop
sudo chmod +x /home/$superuser/Desktop/signal-desktop.desktop
else
:
fi
printf "\nSignal installation Has Finished\n\n"
;;

36) #Dropbox

echo "deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu xenial main" | sudo tee -a /etc/apt/sources.list.d/dropbox-xenial.list
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
sudo apt update
sudo apt install dropbox python-gpgme -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/dropbox
Name=Dropbox
Comment=Dropbox
Icon=/usr/share/icons/hicolor/256x256/apps/dropbox.png" >> /home/$superuser/Desktop/dropbox.desktop
sudo chmod +x /home/$superuser/Desktop/dropbox.desktop
else
:
fi
printf "\nDropbox installation Has Finished\n\n"
;;

37) #WPS Office
if [ "$cpuarch" = "x86_64" ];then
wpsoffice64=`lynx -dump http://wps-community.org/downloads | awk '/wps-office.*\_amd64.deb$/{url=$2}END{print url}'`
wget -O /home/$superuser/Downloads/TempDL/wpsoffice64.deb $wpsoffice64
sudo dpkg -i /home/$superuser/Downloads/TempDL/wpsoffice64.deb
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wpsoffice32=`lynx -dump http://wps-community.org/downloads | awk '/wps-office.*\_i386.deb$/{url=$2}END{print url}'`
wget -O /home/$superuser/Downloads/TempDL/wpsoffice32.deb $wpsoffice32
sudo dpkg -i /home/$superuser/Downloads/TempDL/wpsoffice32.deb
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/wps
Name=WPS Office
Comment=wPS Office
Icon=/usr/share/icons/hicolor/256x256/apps/wps-office-wpsmain.png" >> /home/$superuser/Desktop/wps-office.desktop
sudo chmod +x /home/$superuser/Desktop/wps-office.desktop
else
:
fi
printf "\nWPS Office installation Has Finished\n\n"
;;

38) #Open Office
printf "\nOPENOFFICE NEEDS TO REMOVE THE LIBREOFFICE BEFORE INSTALLING IT, DO YOU CONFIRM (Y/N): "
read openofficeverify
if [ "$openofficeverify" = "Y" ] || [ "$openofficeverify" = "y" ];then
sudo apt install lynx -y
elif [ "$openofficeverify" = "N" ] || [ "$openofficeverify" = "n" ];then
exit
fi
if [ "$cpuarch" = "x86_64" ];then
sudo apt remove libreoffice* openoffice* -y
sudo apt autoremove -y
openofficedirectory=`lynx -dump https://sourceforge.net/projects/openofficeorg.mirror/files/ | grep mirror/files/ | awk '/http/{print $2}' | head -6 | tail -1`
openofficedirectory="${openofficedirectory}binaries/en-US/"
openofficedirectory=`lynx -dump $openofficedirectory | grep x86-64_install-deb_en-US.tar.gz/download | awk '/http/{print $2}'`
wget -O /home/$superuser/Downloads/TempDL/openoffice_x86-64_install-deb_en-US.tar.gz $openofficedirectory
sudo tar xzvf /home/$superuser/Downloads/TempDL/openoffice_x86-64_install-deb_en-US.tar.gz
sudo dpkg -i /home/$superuser/Downloads/TempDL/en-US/DEBS/*.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/en-US/DEBS/desktop-integration/*.deb
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
sudo apt remove libreoffice* openoffice* -y
sudo apt autoremove -y
openofficedirectory=`lynx -dump https://sourceforge.net/projects/openofficeorg.mirror/files/ | grep mirror/files/ | awk '/http/{print $2}' | head -6 | tail -1`
openofficedirectory="${openofficedirectory}binaries/en-US/"
openofficedirectory=`lynx -dump $openofficedirectory | grep x86_install-deb_en-US.tar.gz/download | awk '/http/{print $2}'`
wget -O /home/$superuser/Downloads/TempDL/openoffice_x86_install-deb_en-US.tar.gz $openofficedirectory
sudo tar xzvf /home/$superuser/Downloads/TempDL/openoffice_x86_install-deb_en-US.tar.gz
sudo dpkg -i /home/$superuser/Downloads/TempDL/en-US/DEBS/*.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/en-US/DEBS/desktop-integration/*.deb
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/openoffice4
Name=Open Office
Comment=Open Office
Icon=/usr/share/icons/hicolor/128x128/apps/openoffice4-main.png" >> /home/$superuser/Desktop/open-office.desktop
sudo chmod +x /home/$superuser/Desktop/open-office.desktop
else
:
fi
printf "\nOpen Office installation Has Finished\n\n"
;;

39) # MonoDevelop

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sudo apt install apt-transport-https -y
echo "deb https://download.mono-project.com/repo/ubuntu vs-xenial main" | sudo tee /etc/apt/sources.list.d/mono-official-vs.list
sudo apt update
sudo apt install monodevelop -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/monodevelop
Name=MonoDevelop
Comment=MonoDevelop
Icon=/usr/share/icons/hicolor/256x256/apps/monodevelop.png" >> /home/$superuser/Desktop/monodevelop.desktop
sudo chmod +x /home/$superuser/Desktop/monodevelop.desktop
else
:
fi
printf "\nMonoDevelop installation Has Finished\n\n"
;;

40) # Kodi (PPA)

sudo apt install software-properties-common -y
sudo add-apt-repository ppa:team-xbmc/ppa -y
sudo apt update
sudo apt install kodi -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/kodi
Name=Kodi
Comment=Kodi
Icon=/usr/share/icons/hicolor/256x256/apps/kodi.png" >> /home/$superuser/Desktop/kodi.desktop
sudo chmod +x /home/$superuser/Desktop/kodi.desktop
else
:
fi
printf "\nKodi installation Has Finished"
;;

41) # Unity 2018.3.0f2

printf "\nDo you want to install Unity Hub ? Y/N : "
read unitychoose

if [ "$unitychoose" = "Y" ] || [ "$unitychoose" = "y" ];then
wget https://beta.unity3d.com/download/6e9a27477296/UnitySetup-2018.3.0f2
sudo chmod +x UnitySetup-2018.3.0f2
./UnitySetup-2018.3.0f2
sudo updatedb
unitylogopath=`locate Unity-2018.3.0f2/Editor/Data/Resources/LargeUnityIcon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Unity-2018.3.0f2/Editor/Unity
Name=Unity-2018.3.0f2
Comment=Unity-2018.3.0f2
Icon=$unitylogopath" >> /home/$superuser/Desktop/Unity-2018.3.0f2.desktop
sudo chmod +x /home/$superuser/Desktop/Unity-2018.3.0f2.desktop
sudo mv UnitySetup-2018.3.0f2 /home/$superuser/Downloads/TempDL/

# Unity Hub
wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.AppImage
sudo chmod +x UnityHubSetup.AppImage
./UnityHubSetup.AppImage
sudo mv UnityHubSetup.AppImage /home/$superuser/Downloads/TempDL/

elif [ "$unitychoose" = "N" ] || [ "$unitychoose" = "n" ];then

wget https://beta.unity3d.com/download/6e9a27477296/UnitySetup-2018.3.0f2
sudo chmod +x UnitySetup-2018.3.0f2
./UnitySetup-2018.3.0f2
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Unity-2018.3.0f2/Editor/Unity
Name=Unity-2018.3.0f2
Comment=Unity-2018.3.0f2
Icon=$unitylogopath" >> /home/$superuser/Desktop/Unity-2018.3.0f2.desktop
sudo chmod +x /home/$superuser/Desktop/Unity-2018.3.0f2.desktop
sudo mv UnitySetup-2018.3.0f2 /home/$superuser/Downloads/TempDL/

fi
printf "\nUnity 2018.3.0f2 installation Has Finished\n\n"
;;

42) # Unreal Engine 4

sudo apt install git -y
git clone git@github.com:EpicGames/UnrealEngine.git
./UnrealEngine/Setup.sh
./UnrealEngine/GenerateProjectFiles.sh
cd UnrealEngine/
sudo make
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
unreallogopath=`locate /UnrealVersionSelector/Private/Linux/Resources/Icon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/UnrealEngine/Engine/Binaries/Linux/UE4Editor
Name=Unreal Engine
Comment=Unreal Engine
Icon=$unreallogopath" >> /home/$superuser/Desktop/Unreal-Engine-4.desktop
sudo mv UnrealEngine/ /home/$superuser/Downloads/TempDL/
else
:
fi
printf "\nUnreal Engine 4 installation Has Finished\n\n"
;;

43) # Krita (64 Bit Only)
if [ "$cpuarch" = "x86_64" ];then
sudo apt install lynx -y
kritalocation=`lynx -dump https://download.kde.org/stable/krita/ | grep /stable/krita/ | awk '/http/{print $2}' | head -n 4 | tail -n 1`
kritalocation=`lynx -dump $kritalocation | grep x86_64.appimage | awk '/http/{print $2}' | head -n 5 | tail -n 1`
wget -O /home/$superuser/Downloads/TempDL/krita-x86_64.appimage $kritalocation
sudo chmod +x /home/$superuser/Downloads/TempDL/krita-x86_64.appimage
wget -O /home/$superuser/Downloads/TempDL/krita.png https://www.macupdate.com/images/icons256/57212.png
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/krita-x86_64.appimage
Name=Krita
Comment=Krita
Icon=/home/$superuser/Downloads/TempDL/krita.png" >> /home/$superuser/Desktop/Krita.desktop
sudo chmod +x /home/$superuser/Desktop/krita.desktop
else
:
fi
printf "\nKrita installation Has Finished\n\n"
;;

44) # Kdenlive (64 Bit Only)
if [ "$cpuarch" = "x86_64" ];then
sudo apt install lynx -y
kdenlivelocation=`lynx -dump https://files.kde.org/kdenlive/release/ | awk '/http/{print $2}' | grep x86_64.appimage | tail -n 2 | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/kdenlive-latest-x86-64.appimage $kdenlivelocation
sudo chmod +x /home/$superuser/Downloads/TempDL/kdenlive-latest-x86-64.appimage
wget -O /home/$superuser/Downloads/TempDL/kdenlive.png https://cdn.iconverticons.com/files/png/7f088b9c830c6591_256x256.png
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/kdenlive-latest-x86-64.appimage
Name=Kdenlive
Comment=Kdenlive
Icon=/home/$superuser/Downloads/TempDL/kdenlive.png" >> /home/$superuser/Desktop/kdenlive.desktop
sudo chmod +x /home/$superuser/Desktop/kdenlive.desktop
else
:
fi
printf "\nKdenlive installation Has Finished\n\n"
;;

45) # Qt
if [ "$cpuarch" = "x86_64" ];then
wget -O /home/$superuser/Downloads/TempDL/qt-unified-linux-x64-online.run http://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x /home/$superuser/Downloads/TempDL/qt-unified-linux-x64-online.run
sudo sh /home/$superuser/Downloads/TempDL/qt-unified-linux-x64-online.run
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
qtlocation=`locate Qt/Tools/QtCreator/bin/qtcreator | grep -m1 Qt/Tools/QtCreator/bin/qtcreator`
qticon=`locate QtIcon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$qtlocation
Name=Qt Creator
Comment=Qt Creator
Icon=$qticon" >> /home/$superuser/Desktop/Qt-Creator.desktop
sudo chmod +x /home/$superuser/Desktop/Qt-Creator.desktop
else
:
fi

elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wget -O /home/$superuser/Downloads/TempDL/qt-unified-linux-x86-online.run http://download.qt.io/official_releases/online_installers/qt-unified-linux-x86-online.run
sudo chmod +x /home/$superuser/Downloads/TempDL/qt-unified-linux-x86-online.run
sudo sh /home/$superuser/Downloads/TempDL/qt-unified-linux-x86-online.run
sudo updatedb
qtlocation=`locate Qt/Tools/QtCreator/bin/qtcreator | grep -m1 Qt/Tools/QtCreator/bin/qtcreator`
qticon=`locate QtIcon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$qtlocation
Name=Qt Creator
Comment=Qt Creator
Icon=$qticon" >> /home/$superuser/Desktop/Qt-Creator.desktop
sudo chmod +x /home/$superuser/Desktop/Qt-Creator.desktop
fi
printf "\nQt installation Has Finished\n\n"
;;

46) # AptanaStudio3 (64 Bit Only)
sudo apt install default-jdk -y
sudo apt install libjpeg62 libwebkitgtk-1.0-0 git-core -y
wget -O /home/$superuser/Downloads/TempDL/aptana.studio-linux.gtk.x86_64.zip https://github.com/aptana/studio3/releases/download/3.7.2.201807301111/aptana.studio-linux.gtk.x86_64.zip
sudo unzip -d /home/$superuser/Downloads/TempDL/aptana-studio /home/$superuser/Downloads/TempDL/aptana.studio-linux.gtk.x86_64.zip
sudo chmod +x /home/$superuser/Downloads/TempDL/aptana-studio/AptanaStudio3
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/aptana-studio/AptanaStudio3
Name=AptanaStudio3
Comment=AptanaStudio3
Icon=/home/$superuser/Downloads/TempDL/aptana-studio/icon.xpm" >> /home/$superuser/Desktop/AptanaStudio3.desktop
sudo chmod +x /home/$superuser/Desktop/AptanaStudio3.desktop
else
:
fi
printf "\nAptanaStudio3 installation Has Finished\n\n"
;;

47) # Irssi (PPA)

wget -nv https://download.opensuse.org/repositories/home:ailin_nemui:irssi-test/xUbuntu_16.10/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt update
sudo mv Release.key /home/$superuser/Downloads/signing-keys/
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/ailin_nemui:/irssi-test/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/home:ailin_nemui:irssi-test.list"
sudo apt update
sudo apt install irssi -y
wget -O /home/$superuser/Downloads/TempDL/irssi-logo.png https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Irssi_logo.svg/2000px-Irssi_logo.svg.png
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/irssi
Name=Irssi
Comment=Irssi
Icon=/home/$superuser/Downloads/TempDL/irssi-logo.png" >> /home/$superuser/Desktop/irssi.desktop
sudo chmod +x /home/$superuser/Desktop/irssi.desktop
else
:
fi
printf "\nIrssi installation Has Finished\n\n"
;;


48) # Clementine (PPA)

sudo add-apt-repository ppa:me-davidsansome/clementine -y
sudo apt update
sudo apt install clementine -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/clementine
Name=Clementine
Comment=Clementine
Icon=/usr/share/icons/hicolor/128x128/apps/clementine.png" >> /home/$superuser/Desktop/clementine.desktop
sudo chmod +x /home/$superuser/Desktop/clementine.desktop
else
:
fi
printf "\nClementine installation Has Finished\n\n"
;;

49) # TeamViewer 14

if [ "$cpuarch" = "x86_64" ];then
wget -O /home/$superuser/Downloads/TempDL/teamviewer_amd64.deb https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/teamviewer_amd64.deb
sudo apt -f install -y

elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wget -O /home/$superuser/Downloads/TempDL/teamviewer_i386.deb https://download.teamviewer.com/download/linux/teamviewer_i386.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/teamviewer_i386.deb
sudo apt -f install -y
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/teamviewer
Name=Teamviewer 14
Comment=Teamviewer 14
Icon=/opt/teamviewer/tv_bin/desktop/teamviewer_48.png" >> /home/$superuser/Desktop/teamviewer.desktop
sudo chmod +x /home/$superuser/Desktop/teamviewer.desktop
else
:
fi
printf "\nTeamViewer 14 installation Has Finished\n\n"
;;

50) # TeamSpeak 3
sudo apt install lynx -y
wget -O /home/$superuser/Downloads/TempDL/ts-stacked-bluelight.zip https://www.teamspeak.com/downloads/media-pack/png/ts-stacked-bluelight.zip
sudo unzip /home/$superuser/Downloads/TempDL/ts-stacked-bluelight.zip -d /home/$superuser/Downloads/TempDL/

if [ "$cpuarch" = "x86_64" ];then
teamspeak64=`lynx -dump https://www.teamspeak.com/en/your-download/ | grep Client-linux_amd64 | awk '/http/{print $2}'`
wget -O /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_amd64.run $teamspeak64
sudo chmod +x /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_amd64.run
sudo bash /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_amd64.run
sudo chown -R $superuser:$superuser TeamSpeak3-Client-linux_amd64/
sudo mv TeamSpeak3-Client-linux_amd64/ /home/$superuser/Downloads/TempDL/
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
teamspeaklocation=`locate ts3client_runscript`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$teamspeaklocation
Name=TeamSpeak 3
Comment=TeamSpeak 3
Icon=/home/$superuser/Downloads/TempDL/ts_stacked_bluelight.png" >> /home/$superuser/Desktop/teamspeak.desktop
sudo chmod +x /home/$superuser/Desktop/teamspeak.desktop
else
:
fi

if [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
teamspeak32=`lynx -dump https://www.teamspeak.com/en/your-download/ | grep Client-linux_x86 | awk '/http/{print $2}'`
wget -O /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_x86.run $teamspeak32
sudo chmod +x /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_x86.run
sudo bash /home/$superuser/Downloads/TempDL/TeamSpeak3-Client-linux_x86.run
sudo chown -R $superuser:$superuser TeamSpeak3-Client-linux_x86/
sudo mv TeamSpeak3-Client-linux_x86/ /home/$superuser/Downloads/TempDL/
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
teamspeaklocation=`locate ts3client_runscript`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$teamspeaklocation
Name=TeamSpeak 3
Comment=TeamSpeak 3
Icon=/home/$superuser/Downloads/TempDL/ts_stacked_bluelight.png" >> /home/$superuser/Desktop/teamspeak.desktop
sudo chmod +x /home/$superuser/Desktop/teamspeak.desktop
else
:
fi
printf "\nTeamSpeak 3 installation Has Finished\n\n"
;;

51) # Discord
wget -O /home/$superuser/Downloads/TempDL/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
sudo dpkg -i /home/$superuser/Downloads/TempDL/discord.deb
sudo apt -f install -y

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/discord
Name=Discord
Comment=Discord
Icon=/usr/share/discord/discord.png" >> /home/$superuser/Desktop/discord.desktop
sudo chmod +x /home/$superuser/Desktop/discord.desktop
else
:
fi
printf "\nDiscord installation Has Finished\n\n"
;;

52) # Android Studio
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt update
sudo apt install java-common oracle-java8-installer -y
sudo apt-add-repository ppa:maarten-fonville/android-studio -y
sudo apt update 
sudo apt install android-studio -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/android-studio/bin/studio.sh
Name=Android Studio
Comment=Android Studio
Icon=/opt/android-studio/bin/studio.png" >> /home/$superuser/Desktop/android-studio.desktop
sudo chmod +x /home/$superuser/Desktop/android-studio.desktop
else
:
fi
printf "\nAndroid Studio installation Has Finished\n\n"
;;


53) # Geary (PPA)

sudo add-apt-repository ppa:geary-team/releases -y
sudo apt update
sudo apt install geary -y
wget -O /home/$superuser/Downloads/TempDL/geary.png https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Geary.svg/1200px-Geary.svg.png
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/geary
Name=Geary
Comment=Geary
Icon=/home/$superuser/Downloads/TempDL/geary.png" >> /home/$superuser/Desktop/geary.desktop
sudo chmod +x /home/$superuser/Desktop/geary.desktop
else
:
fi
printf "\nGeary installation Has Finished\n\n"
;;

54) # uGet
if [ "$cpuarch" = "x86_64" ];then
wget -O /home/$superuser/Downloads/TempDL/ubuntu-64-xenial-download https://ugetdm.com/go/ubuntu-64-xenial-download
sudo dpkg -i /home/$superuser/Downloads/TempDL/ubuntu-64-xenial-download
sudo apt -f install -y
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wget -O /home/$superuser/Downloads/TempDL/ubuntu-32-xenial-download https://ugetdm.com/go/ubuntu-32-xenial-download
sudo dpkg -i /home/$superuser/Downloads/TempDL/ubuntu-32-xenial-download
sudo apt -f install -y
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/uget-gtk
Name=uGet
Comment=uGet
Icon=/usr/share/icons/hicolor/128x128/apps/uget-icon.png" >> /home/$superuser/Desktop/uget.desktop
sudo chmod +x /home/$superuser/Desktop/uget.desktop
else
:
fi
printf "\nuGet installation Has Finished\n\n"
;;

55) # Sayonara Player (PPA)

sudo apt-add-repository ppa:lucioc/sayonara -y
sudo apt update
sudo apt install sayonara -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/sayonara
Name=Sayonara
Comment=Sayonara
Icon=/usr/share/icons/hicolor/128x128/apps/sayonara.png" >> /home/$superuser/Desktop/sayonara.desktop
sudo chmod +x /home/$superuser/Desktop/sayonara.desktop
else
:
fi
printf "\nSayonara Player installation Has Finished\n\n"
;;

56) # Franz (Messaging App) (64 Bit Only)
if [ "$cpuarch" = "x86_64" ];then
sudo apt install lynx -y
franz64=`lynx -dump https://github.com/meetfranz/franz/releases/ | grep _amd64.deb* | awk '/http/{print $2}' | head -1`
wget -O /home/$superuser/Downloads/TempDL/franz-amd64.deb $franz64
sudo dpkg -i /home/$superuser/Downloads/TempDL/franz-amd64.deb
sudo apt install libgconf-2-4 -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/local/bin/franz
Name=Franz
Comment=Franz
Icon=/usr/share/icons/hicolor/128x128/apps/franz.png" >> /home/$superuser/Desktop/franz.desktop
sudo chmod +x /home/$superuser/Desktop/franz.desktop
else
:
fi
printf "\nFranz installation Has Finished\n\n"
fi
if [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
printf "\nOnly 64 Bit Processors Supported"
sleep 1
fi

;;

57) # balenaEtcher
echo "deb https://deb.etcher.io stable etcher" | sudo tee /etc/apt/sources.list.d/balena-etcher.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
sudo apt update
sudo apt install balena-etcher-electron -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/local/bin/balena-etcher-electron
Name=balenaEtcher
Comment=balenaEtcher
Icon=/usr/share/icons/hicolor/128x128/apps/balena-etcher-electron.png" >> /home/$superuser/Desktop/balena-etcher.desktop
sudo chmod +x /home/$superuser/Desktop/balena-etcher.desktop
else
:
fi
printf "\nbalenaEtcher installation Has Finished\n\n"
;;

58) # Vivaldi
echo "deb http://repo.vivaldi.com/stable/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
wget -O - http://repo.vivaldi.com/stable/linux_signing_key.pub | sudo apt-key add -
sudo apt update && sudo apt install vivaldi-stable -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/vivaldi
Name=Vivaldi
Comment=Vivaldi
Icon=/usr/share/icons/hicolor/128x128/apps/vivaldi.png" >> /home/$superuser/Desktop/vivaldi.desktop
sudo chmod +x /home/$superuser/Desktop/vivaldi.desktop
else
:
fi
printf "\nVivaldi installation Has Finished\n\n"
;;

59) # Spotify
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update
sudo apt install spotify-client -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/spotify
Name=Spotify
Comment=Spotify
Icon=/usr/share/icons/hicolor/128x128/apps/spotify-client.png" >> /home/$superuser/Desktop/spotify.desktop
sudo chmod +x /home/$superuser/Desktop/spotify.desktop
else
:
fi
printf "\nSpotify installation Has Finished\n\n"
;;

60) # MusicBrainz Picard (PPA)
sudo add-apt-repository ppa:musicbrainz-developers/stable -y
sudo apt update -y
sudo apt install picard -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/picard
Name=Picard
Comment=Picard
Icon=/usr/share/icons/hicolor/128x128/apps/picard.png" >> /home/$superuser/Desktop/picard.desktop
sudo chmod +x /home/$superuser/Desktop/picard.desktop
else
:
fi
printf "\nPicard installation Has Finished\n\n"
;;

61) # pCloud Drive
if [ "$cpuarch" = "x86_64" ];then
wget -O /home/$superuser/Downloads/TempDL/pcloud https://www.pcloud.com/tr/how-to-install-pcloud-drive-linux.html?download=electron-64
sudo chmod +x /home/$superuser/Downloads/TempDL/pcloud
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wget -O /home/$superuser/Downloads/TempDL/pcloud https://www.pcloud.com/tr/how-to-install-pcloud-drive-linux.html?download=electron-32
sudo chmod +x /home/$superuser/Downloads/TempDL/pcloud
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/pcloud
Name=pCloud Drive
Comment=pCloud Drive
Icon=/home/$superuser/.local/share/icons/hicolor/128x128/apps/appimagekit-pcloud.png" >> /home/$superuser/Desktop/pcloud.desktop
sudo chmod +x /home/$superuser/Desktop/pcloud.desktop
else
:
fi
printf "\npCloud Drive installation Has Finished\n\n"
;;

62) # Timeshift (PPA)
sudo add-apt-repository -y ppa:teejee2008/ppa -y
sudo apt update
sudo apt install timeshift -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/timeshift-launcher
Name=Timeshift
Comment=Timeshift
Icon=/usr/share/icons/hicolor/128x128/apps/timeshift.png" >> /home/$superuser/Desktop/timeshift.desktop
sudo chmod +x /home/$superuser/Desktop/timeshift.desktop
else
:
fi
printf "\nTimeshift installation Has Finished\n\n"
;;

63) # Peek (GIF Recorder) (PPA)
sudo add-apt-repository ppa:peek-developers/stable -y
sudo apt update
sudo apt install peek -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/peek
Name=Peek
Comment=Peek
Icon=/usr/share/icons/hicolor/128x128/apps/com.uploadedlobster.peek.png" >> /home/$superuser/Desktop/peek.desktop
sudo chmod +x /home/$superuser/Desktop/peek.desktop
else
:
fi
printf "\nPeek installation Has Finished\n\n"
;;

64) # Stacer (System Optimizer) (PPA)
sudo add-apt-repository ppa:oguzhaninan/stacer -y
sudo apt update
sudo apt install stacer -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/stacer
Name=Stacer
Comment=Stacer
Icon=/usr/share/icons/hicolor/128x128/apps/stacer.png" >> /home/$superuser/Desktop/stacer.desktop
sudo chmod +x /home/$superuser/Desktop/stacer.desktop
else
:
fi
printf "\nStacer installation Has Finished\n\n"
;;

65) # Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install default-jre -y
sudo apt install jenkins -y
printf "\nJenkins installation Has Finished\n\n"
;;

66) # Docker
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg-agent -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y
printf "\nDocker installation Has Finished\n\n"
;;

67) # Python 2 & 3 (From Source)
printf "\nPlease Choose your option"
printf "\n1-)Install Python 2"
printf "\n2-)Install Python 3"
printf "\n3-)Install Python 2 and 3\nChoose:"
read pythonoption
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget lynx -y
if [ "$pythonoption" = "1" ];then
printf "\n1-)Install Python 2 Selected"
python2location=`lynx -dump https://www.python.org/downloads/ | awk '/http/{print $2}' | grep release/python-2 | head -n 1`
python2location=`lynx -dump $python2location | awk '/http/{print $2}' | grep .tgz | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/python2-latest.tgz $python2location
sudo mkdir -p /home/$superuser/Downloads/TempDL/python2-latest
sudo tar xvf /home/$superuser/Downloads/TempDL/python2-latest.tgz -C /home/$superuser/Downloads/TempDL/python2-latest --strip-components 1
sudo /home/$superuser/Downloads/TempDL/python2-latest/./configure
sudo make -C /home/$superuser/Downloads/TempDL/python2-latest/
sudo make install -C /home/$superuser/Downloads/TempDL/python2-latest/
printf "\nPython 2 installation Has Finished\n\n"

elif [ "$pythonoption" = "2" ];then
printf "\n2-)Install Python 3 Selected"
python3location=`lynx -dump https://www.python.org/downloads/ | awk '/http/{print $2}' | grep release/python-3 | head -n 1`
python3location=`lynx -dump $python3location | awk '/http/{print $2}' | grep .tgz | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/python3-latest.tgz $python3location
sudo mkdir -p /home/$superuser/Downloads/TempDL/python3-latest
sudo tar xvf /home/$superuser/Downloads/TempDL/python3-latest.tgz -C /home/$superuser/Downloads/TempDL/python3-latest --strip-components 1
sudo /home/$superuser/Downloads/TempDL/python3-latest/./configure
sudo make -C /home/$superuser/Downloads/TempDL/python3-latest/
sudo make install -C /home/$superuser/Downloads/TempDL/python3-latest/
printf "\nPython 3 installation Has Finished\n\n"

elif [ "$pythonoption" = "3" ];then
printf "\n3-)Install Python 2 and 3 Selected"
python2location=`lynx -dump https://www.python.org/downloads/ | awk '/http/{print $2}' | grep release/python-2 | head -n 1`
python2location=`lynx -dump $python2location | awk '/http/{print $2}' | grep .tgz | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/python2-latest.tgz $python2location
sudo mkdir -p /home/$superuser/Downloads/TempDL/python2-latest
sudo tar xvf /home/$superuser/Downloads/TempDL/python2-latest.tgz -C /home/$superuser/Downloads/TempDL/python2-latest --strip-components 1
sudo /home/$superuser/Downloads/TempDL/python2-latest/./configure
sudo make -C /home/$superuser/Downloads/TempDL/python2-latest/
sudo make install -C /home/$superuser/Downloads/TempDL/python2-latest/
printf "\nPython 2 installation Has Finished\n\n"

python3location=`lynx -dump https://www.python.org/downloads/ | awk '/http/{print $2}' | grep release/python-3 | head -n 1`
python3location=`lynx -dump $python3location | awk '/http/{print $2}' | grep .tgz | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/python3-latest.tgz $python3location
sudo mkdir -p /home/$superuser/Downloads/TempDL/python3-latest
sudo tar xvf /home/$superuser/Downloads/TempDL/python3-latest.tgz -C /home/$superuser/Downloads/TempDL/python3-latest --strip-components 1
sudo /home/$superuser/Downloads/TempDL/python3-latest/./configure
sudo make -C /home/$superuser/Downloads/TempDL/python3-latest/
sudo make install -C /home/$superuser/Downloads/TempDL/python3-latest/
printf "\nPython 2 and 3 installation Has Finished\n\n"
else
:
fi
;;

68) # Telegram (PPA)
sudo add-apt-repository ppa:atareao/telegram -y
sudo apt update
sudo apt install telegram -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
sudo wget -O /home/$superuser/Downloads/TempDL/telegram-logo.png http://www.stickpng.com/assets/images/5842a8fba6515b1e0ad75b03.png
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/telegram
Name=Telegram
Comment=Telegram
Icon=/home/$superuser/Downloads/TempDL/telegram-logo.png" >> /home/$superuser/Desktop/telegram.desktop
sudo chmod +x /home/$superuser/Desktop/telegram.desktop
else
:
fi
printf "\nTelegram installation Has Finished\n\n"
;;

69) # Brackets (PPA)
sudo add-apt-repository ppa:webupd8team/brackets -y
sudo apt update
sudo apt install brackets -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
sudo wget -O /home/$superuser/Downloads/TempDL/telegram-logo.png http://www.stickpng.com/assets/images/5842a8fba6515b1e0ad75b03.png
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/telegram
Name=Telegram
Comment=Telegram
Icon=/home/$superuser/Downloads/TempDL/telegram-logo.png" >> /home/$superuser/Desktop/telegram.desktop
sudo chmod +x /home/$superuser/Desktop/telegram.desktop
else
:
fi
printf "\nTelegram installation Has Finished\n\n"
;;

70) # Shotcut (Snap)
sudo apt install snapd -y
sudo snap install shotcut --classic
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
shotcutlocation=`locate shotcut-logo-64.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/shotcut
Name=Shotcut
Comment=Shotcut
Icon=$shotcutlocation" >> /home/$superuser/Desktop/shotcut.desktop
sudo chmod +x /home/$superuser/Desktop/shotcut.desktop
else
:
fi
printf "\nShotcut installation Has Finished\n\n"
;;

71) # Okular (Document Viewer) (Snap)
printf "\nPlease Choose Your Installation Method"
printf "\n1-)Standart apt okular installation"
printf "\n2-)Latest Version (Snap) installation"
printf "\n ----- (Snap version needs to download and install some KDE packages.It'll take a more time to install.Are you Sure to proceed ? -----"
read okularoption

if [ "$okularoption" = "1" ];then
sudo apt install okular -y
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/okular
Name=Okular
Comment=Okular
Icon=/usr/share/icons/hicolor/64x64/apps/okular.png" >> /home/$superuser/Desktop/okular.desktop
sudo chmod +x /home/$superuser/Desktop/okular.desktop
else
:
fi
printf "\nOkular installation Has Finished\n\n"

if [ "$okularoption" = "2" ];then
sudo apt install snapd -y
sudo snap install okular
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
okularlocation=`locate apps/okular.png | tail -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/okular
Name=Okular
Comment=Okular
Icon=$okularlocation" >> /home/$superuser/Desktop/okular.desktop
sudo chmod +x /home/$superuser/Desktop/okular.desktop
else
:
fi
;;

72) # WeeChat (IRC)
sudo apt install apt-transport-https -y
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 11E9DE8848F2B65222AA75B8D1820DB22A11534E
sudo bash -c "echo 'deb https://weechat.org/ubuntu xenial main' >/etc/apt/sources.list.d/weechat.list"
sudo bash -c "echo 'deb-src https://weechat.org/ubuntu xenial main' >>/etc/apt/sources.list.d/weechat.list"
sudo apt update
sudo apt install weechat -y
printf "\nWeeChat (IRC) installation Has Finished\n\n"
;;

73) # Quassel (IRC) (PPA)
sudo add-apt-repository ppa:mamarley/quassel -y
sudo apt update
sudo apt install quassel -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/quassel
Name=Quassel
Comment=Quassel
Icon=/usr/share/icons/hicolor/64x64/apps/quassel.png" >> /home/$superuser/Desktop/quassel.desktop
sudo chmod +x /home/$superuser/Desktop/quassel.desktop
else
:
fi
printf "\nQuassel (IRC) (PPA) installation Has Finished\n\n"
;;

74) # Konversation (IRC)
sudo apt install snapd -y
sudo snap install konversation
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
konversationlogo=`locate hicolor/64x64/apps/konversation.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/konversation
Name=Konversation
Comment=Konversation
Icon=$konversationlogo" >> /home/$superuser/Desktop/konversation.desktop
sudo chmod +x /home/$superuser/Desktop/konversation.desktop
else
:
fi
printf "\nKonversation (IRC) installation Has Finished\n\n"
;;

75) # Ramme (Instagram Desktop App)
sudo apt install snapd lynx -y
if [ "$cpuarch" = "x86_64" ];then
rammelocation64=`lynx -dump https://github.com/terkelg/ramme/releases | grep /releases/download/ | grep amd64.deb | awk '/http/{print $2}' | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/ramme-latest-amd64.deb $rammelocation64
sudo dpkg -i /home/$superuser/Downloads/TempDL/ramme-latest-amd64.deb
sudo apt -f install -y
sudo apt install libasound2 -y
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
rammelocation32=`lynx -dump https://github.com/terkelg/ramme/releases | grep /releases/download/ | grep i386.deb | awk '/http/{print $2}' | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/ramme-latest-i386.deb $rammelocation32
sudo dpkg -i /home/$superuser/Downloads/TempDL/ramme-latest-i386.deb
sudo apt -f install -y
sudo apt install libasound2 -y
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/local/bin/ramme
Name=Ramme
Comment=Ramme
Icon=/usr/share/icons/hicolor/64x64/apps/ramme.png" >> /home/$superuser/Desktop/ramme.desktop
sudo chmod +x /home/$superuser/Desktop/ramme.desktop
else
:
fi
printf "\nRamme (Instagram Desktop App) installation Has Finished\n\n"
;;

76) # Atom

if [ "$cpuarch" = "x86_64" ];then
sudo wget -O /home/$superuser/Downloads/TempDL/atom-amd64.deb https://atom.io/download/deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/atom-amd64.deb
sudo apt -f install -y
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/atom
Name=Atom
Comment=Atom
Icon=/usr/share/pixmaps/atom.png" >> /home/$superuser/Desktop/atom.desktop
sudo chmod +x /home/$superuser/Desktop/atom.desktop
printf "\nAtom (Instagram Desktop App) installation Has Finished\n\n"
else
:
fi
if [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
printf "\nOnly 64 Bit Processors Supported"
sleep 1
fi
;;

77) # Google Play Music Desktop Player

if [ "$cpuarch" = "x86_64" ];then
googleplaymusic64=`lynx -dump https://github.com/MarshallOfSound/Google-Play-Music-Desktop-Player-UNOFFICIAL-/releases | awk '/http/{print $2}' | grep amd64.deb | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/google-play-music-amd64.deb $googleplaymusic64
sudo dpkg -i /home/$superuser/Downloads/TempDL/google-play-music-amd64.deb
sudo apt -f install -y

elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
googleplaymusic32=`lynx -dump https://github.com/MarshallOfSound/Google-Play-Music-Desktop-Player-UNOFFICIAL-/releases | awk '/http/{print $2}' | grep i386.deb | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/google-play-music-i386.deb $googleplaymusic32
sudo dpkg -i /home/$superuser/Downloads/TempDL/google-play-music-i386.deb
sudo apt -f install -y
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/google-play-music-desktop-player
Name=Atom
Comment=Atom
Icon=/usr/share/pixmaps/google-play-music-desktop-player.png" >> /home/$superuser/Desktop/google-play-music-desktop-player.desktop
sudo chmod +x /home/$superuser/Desktop/google-play-music-desktop-player.desktop
else
:
fi
printf "\nGoogle Play Music Desktop Player installation Has Finished\n\n"
;;

78) # Ubuntu Cleaner (PPA)
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:gerardpuig/ppa -y
sudo apt update
sudo apt install ubuntu-cleaner -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/ubuntu-cleaner
Name=Ubuntu-Cleaner
Comment=Ubuntu-Cleaner
Icon=/usr/share/icons/hicolor/64x64/apps/ubuntu-cleaner.png" >> /home/$superuser/Desktop/ubuntu-cleaner.desktop
sudo chmod +x /home/$superuser/Desktop/ubuntu-cleaner.desktop
else
:
fi
printf "\nUbuntu Cleaner (PPA) installation Has Finished\n\n"
;;

79) # Pixbuf
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:gerardpuig/ppa -y
sudo apt update
sudo apt install ubuntu-cleaner -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/ubuntu-cleaner
Name=Ubuntu-Cleaner
Comment=Ubuntu-Cleaner
Icon=/usr/share/icons/hicolor/64x64/apps/ubuntu-cleaner.png" >> /home/$superuser/Desktop/ubuntu-cleaner.desktop
sudo chmod +x /home/$superuser/Desktop/ubuntu-cleaner.desktop
else
:
fi
printf "\nPixbuf (PPA) installation Has Finished\n\n"
;;

80) # SimpleScreenRecorder (PPA)
sudo add-apt-repository ppa:maarten-baert/simplescreenrecorder -y
sudo apt update
sudo apt install simplescreenrecorder simplescreenrecorder-lib:i386 -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/simplescreenrecorder
Name=SimpleScreenRecorder
Comment=SimpleScreenRecorder
Icon=/usr/share/icons/hicolor/64x64/apps/simplescreenrecorder.png" >> /home/$superuser/Desktop/simplescreenrecorder.desktop
sudo chmod +x /home/$superuser/Desktop/simplescreenrecorder.desktop
else
:
fi
printf "\nSimpleScreenRecorder (PPA) installation Has Finished\n\n"
;;

81) # Neofetch (PPA)
sudo add-apt-repository ppa:dawidd0811/neofetch -y
sudo apt update
sudo apt update install neofetch -y
printf "\nNeofetch (PPA) installation Has Finished\n\n"
;;

82) # Shutter (Screenshot Tool) (PPA)
sudo add-apt-repository ppa:ubuntuhandbook1/shutter -y
sudo apt update
sudo apt install shutter -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/share/shutter
Name=Shutter
Comment=Shutter
Icon=/usr/share/icons/hicolor/64x64/apps/shutter.png" >> /home/$superuser/Desktop/shutter.desktop
sudo chmod +x /home/$superuser/Desktop/shutter.desktop
else
:
fi
printf "\nShutter (Screenshot Tool) (PPA) installation Has Finished\n\n"
;;

83) # Bitwarden (Snap)
sudo apt install snapd -y
sudo apt update
sudo snap install bitwarden
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
bitwardenlogolocation=`locate /snap/bitwarden/ | grep /icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/bitwarden
Name=Bitwarden
Comment=Bitwarden
Icon=$bitwardenlogolocation" >> /home/$superuser/Desktop/bitwarden.desktop
sudo chmod +x /home/$superuser/Desktop/bitwarden.desktop
else
:
fi
printf "\nBitwarden installation Has Finished\n\n"
;;

84) # Plank (Dock) (PPA)
sudo add-apt-repository ppa:ricotz/docky -y
sudo apt update
sudo apt install plank -y
printf "\nPlank (Dock) (PPA) installation Has Finished\n\n"
;;

85) # Thonny (IDE)
sudo apt install python3-pip -y
sudo pip3 install thonny
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
thonnylogo=`locate thonny | grep /thonny/res/thonny.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/local/bin/thonny
Name=Thonny
Comment=Thonny
Icon=$thonnylogo" >> /home/$superuser/Desktop/thonny.desktop
sudo chmod +x /home/$superuser/Desktop/thonny.desktop
else
:
fi
printf "\nThonny installation Has Finished\n\n"
;;

86) # Bluefish (PPA)
sudo add-apt-repository ppa:klaus-vormweg/bluefish -y
sudo apt update
sudo apt install bluefish -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/bluefish
Name=Bluefish
Comment=Bluefish
Icon=/usr/share/icons/hicolor/64x64/apps/bluefish.png" >> /home/$superuser/Desktop/bluefish.desktop
sudo chmod +x /home/$superuser/Desktop/bluefish.desktop
else
:
fi
printf "\nBluefish (PPA) installation Has Finished\n\n"
;;

87) # Vim (PPA)
sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update
sudo apt install vim -y
printf "\nVim (PPA) installation Has Finished\n\n"
;;

88) # Geany (IDE) (PPA)
sudo add-apt-repository ppa:geany-dev/ppa -y
sudo apt update
sudo apt install geany -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/geany
Name=Geany
Comment=Geany
Icon=/usr/share/icons/hicolor/48x48/apps/geany.png" >> /home/$superuser/Desktop/geany.desktop
sudo chmod +x /home/$superuser/Desktop/geany.desktop
else
:
fi
printf "\nGeany (IDE) (PPA) installation Has Finished\n\n"
;;

89) # Gnu Emacs (PPA)
sudo add-apt-repository ppa:kelleyk/emacs -y
sudo apt update
sudo apt install emacs26 -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/emacs
Name=Gnu Emacs
Comment=Gnu Emacs
Icon=/usr/share/icons/hicolor/48x48/apps/emacs26.png" >> /home/$superuser/Desktop/gnu-emacs.desktop
sudo chmod +x /home/$superuser/Desktop/gnu-emacs.desktop
else
:
fi
printf "\nGnu Emacs (PPA) installation Has Finished\n\n"
;;

90) # GitKraken (Snap)
sudo apt install snapd -y
sudo snap install gitkraken
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
gitkrakenlogo=`locate gitkraken | grep app.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/gitkraken
Name=Gitkraken
Comment=Gitkraken
Icon=$gitkrakenlogo" >> /home/$superuser/Desktop/gitkraken.desktop
sudo chmod +x /home/$superuser/Desktop/gitkraken.desktop
else
:
fi
printf "\nGitKraken (Snap) installation Has Finished\n\n"
;;

91) # Wire (Snap)
sudo apt install snapd -y
sudo snap install wire
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
wirelogo=`locate wire | grep wire-desktop.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/wire
Name=Wire
Comment=Wire
Icon=$wirelogo" >> /home/$superuser/Desktop/wire.desktop
sudo chmod +x /home/$superuser/Desktop/wire.desktop
else
:
fi
printf "\nWire (Snap) installation Has Finished\n\n"
;;

92) # Kubectl
sudo apt install apt-transport-https -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install kubectl -y
printf "\nKubectl installation Has Finished\n\n"
;;

93) # Zenkit (Snap)
sudo apt install snapd -y
sudo snap install zenkit
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
zenkitlogolocation=`locate /snap/zenkit/ | grep /meta/gui/icon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/zenkit
Name=Zenkit
Comment=Zenkit
Icon=$zenkitlogolocation" >> /home/$superuser/Desktop/zenkit.desktop
sudo chmod +x /home/$superuser/Desktop/zenkit.desktop
else
:
fi
printf "\nZenkit (Snap) installation Has Finished\n\n"
;;

94) # Wormhole (Snap)
sudo apt install python-pip build-essential python-dev libffi-dev libssl-dev -y
pip install magic-wormhole
printf "\nWormhole (Snap) installation Has Finished\n\n"
;;

95) # Hexchat (Snap)
sudo apt install snapd -y
sudo snap install hexchat
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
hexchatlogo=`locate hexchat | grep hexchat.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/hexchat
Name=Hexchat
Comment=Hexchat
Icon=$hexchatlogo" >> /home/$superuser/Desktop/hexchat.desktop
sudo chmod +x /home/$superuser/Desktop/hexchat.desktop
else
:
fi
printf "\nHexchat (Snap) installation Has Finished\n\n"
;;

96) # Wings 3D
sudo wget -O /home/$superuser/Downloads/TempDL/wings3d-stable http://www.wings3d.com/redirect_download.php?title=stable_linux
sudo chmod +x /home/$superuser/Downloads/TempDL/wings3d-stable
sudo bash /home/$superuser/Downloads/TempDL/wings3d-stable
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
wings3d=`locate wings | head -n 4 | tail -n 1`
wings3dlogo=`locate wings | grep wings_icon_379x379.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$wings3d
Name=Wings 3D
Comment=Wings 3D
Icon=$wings3dlogo" >> /home/$superuser/Desktop/wings3d.desktop
sudo chmod +x /home/$superuser/Desktop/wings3d.desktop
else
:
fi
printf "\nWings 3D installation Has Finished\n\n"
;;

97) # MakeHuman (PPA)
sudo add-apt-repository ppa:makehuman-official/makehuman-11x -y
sudo apt update
sudo apt install makehuman -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/makehuman
Name=MakeHuman
Comment=MakeHuman
Icon=/usr/share/makehuman/icons/makehuman.png" >> /home/$superuser/Desktop/makehuman.desktop
sudo chmod +x /home/$superuser/Desktop/makehuman.desktop
else
:
fi
printf "\nMakeHuman installation Has Finished\n\n"
;;

98) # Grub Customizer (PPA)
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt update
sudo apt install grub-customizer -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/grub-customizer
Name=Grub Customizer
Comment=Grub Customizer
Icon=/usr/share/icons/hicolor/64x64/apps/grub-customizer.svg" >> /home/$superuser/Desktop/grub-customizer.desktop
sudo chmod +x /home/$superuser/Desktop/grub-customizer.desktop
else
:
fi
printf "\nGrub Customizer installation Has Finished\n\n"
;;

99) # 4K Video Downloader (64 Bit Only)
if [ "$cpuarch" = "x86_64" ];then
sudo apt install lynx -y
videodownloader=`lynx -dump https://www.4kdownload.com/download | grep amd64.deb | awk '/http/{print $2}' | grep 4kvideodownloader | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/4kvideodownload-latest-amd64.deb $videodownloader
sudo dpkg -i /home/$superuser/Downloads/TempDL/4kvideodownload-latest-amd64.deb
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
printf "\nOnly 64 Bit Processors Supported"
sleep 1
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/4kvideodownloader
Name=4k Video Downloader
Comment=4k Video Downloader
Icon=/usr/share/icons/4kvideodownloader.png" >> /home/$superuser/Desktop/4kvideodownloader.desktop
sudo chmod +x /home/$superuser/Desktop/4kvideodownloader.desktop
else
:
fi
printf "\n4k Video Downloader installation Has Finished\n\n"
;;

100) # 4K Youtube to MP3
sudo apt install lynx -y
youtubetomp3=`lynx -dump https://www.4kdownload.com/download | grep amd64.deb | awk '/http/{print $2}' | grep 4kyoutubetomp3 | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/4kyoutubetomp3-latest-amd64.deb $youtubetomp3
sudo dpkg -i /home/$superuser/Downloads/TempDL/4kyoutubetomp3-latest-amd64.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/4kyoutubetomp3
Name=4k Youtube to MP3
Comment=4k Youtube to MP3
Icon=/usr/share/icons/4kyoutubetomp3.png" >> /home/$superuser/Desktop/4kyoutubetomp3.desktop
sudo chmod +x /home/$superuser/Desktop/4kyoutubetomp3.desktop
else
:
fi
printf "\n4k Youtube to MP3 installation Has Finished\n\n"
;;

101) # 4K Stogram
sudo apt install lynx -y
stogram4k=`lynx -dump https://www.4kdownload.com/download | grep amd64.deb | awk '/http/{print $2}' | grep 4kstogram | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/4kstogram-latest-amd64.deb $stogram4k
sudo dpkg -i /home/$superuser/Downloads/TempDL/4kstogram-latest-amd64.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/4kstogram
Name=4k Stogram
Comment=4k Stogram
Icon=/usr/share/icons/4kstogram.png" >> /home/$superuser/Desktop/4kstogram.desktop
sudo chmod +x /home/$superuser/Desktop/4kstogram.desktop
else
:
fi
printf "\n4k Stogram installation Has Finished\n\n"
;;

102) # 4K Slideshow Maker
sudo apt install lynx -y
slideshowmaker4k=`lynx -dump https://www.4kdownload.com/download | grep amd64.deb | awk '/http/{print $2}' | grep 4kslideshowmaker | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/4kslideshowmaker-latest-amd64.deb $slideshowmaker4k
sudo dpkg -i /home/$superuser/Downloads/TempDL/4kslideshowmaker-latest-amd64.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/4kslideshowmaker
Name=4k Slideshow Maker
Comment=4k Slideshow Maker
Icon=/usr/share/icons/4kslideshowmaker.png" >> /home/$superuser/Desktop/4kslideshowmaker.desktop
sudo chmod +x /home/$superuser/Desktop/4kslideshowmaker.desktop
else
:
fi
printf "\n4k Slideshow Maker installation Has Finished\n\n"
;;

103) # 4K Video to MP3
sudo apt install lynx -y
videotomp3=`lynx -dump https://www.4kdownload.com/download | grep amd64.deb | awk '/http/{print $2}' | grep 4kvideotomp3 | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/4kvideotomp3-latest-amd64.deb $videotomp3
sudo dpkg -i /home/$superuser/Downloads/TempDL/4kvideotomp3-latest-amd64.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/4kvideotomp3
Name=4k Video to MP3
Comment=4k Video to MP3
Icon=/usr/share/icons/4kvideotomp3.png" >> /home/$superuser/Desktop/4kvideotomp3.desktop
sudo chmod +x /home/$superuser/Desktop/4kvideotomp3.desktop
else
:
fi
printf "\n4k Video to MP3 installation Has Finished\n\n"
;;

104) # Neovim (PPA)
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo apt update
sudo apt install neovim -y
printf "\nNeovim (PPA) installation Has Finished\n\n"
;;

105) # Light Table (PPA)
sudo add-apt-repository ppa:dr-akulavich/lighttable -y
sudo apt update
sudo apt install lighttable-installer -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/LightTable
Name=Light Table
Comment=Light Table
Icon=/opt/LightTable/resources/app/core/img/lticon.png" >> /home/$superuser/Desktop/light-table.desktop
sudo chmod +x /home/$superuser/Desktop/light-table.desktop
else
:
fi
printf "\nLight Table (PPA) installation Has Finished\n\n"
;;

106) # GCC 8 & G++ 8 (PPA)
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt update
sudo apt install gcc-8 g++-8 -y
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-8
sudo update-alternatives --config gcc
printf "\nGCC 8 & G++ 8 (PPA) installation Has Finished\n\n"
;;

107) # Cmake (Python pip)
sudo apt install python-pip -y
sudo python -m pip install --upgrade pip
sudo pip install cmake
printf "\nCmake (Python pip) installation Has Finished\n\n"
;;

108) # Textadept (Editor)
if [ "$cpuarch" = "x86_64" ];then
sudo wget -O /home/$superuser/Downloads/TempDL/textadept-LATEST-x86_64.tgz https://foicica.com/textadept/download/textadept_LATEST.x86_64.tgz
sudo mkdir -p /home/$superuser/Downloads/TempDL/textadept-LATEST
sudo tar xzvf /home/$superuser/Downloads/TempDL/textadept-LATEST-x86_64.tgz -C /home/$superuser/Downloads/TempDL/textadept-LATEST --strip-components 1

elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
sudo wget -O /home/$superuser/Downloads/TempDL/textadept-LATEST-i386.tgz https://foicica.com/textadept/download/textadept_LATEST.i386.tgz
sudo mkdir -p /home/$superuser/Downloads/TempDL/textadept-LATEST
sudo tar xzvf /home/$superuser/Downloads/TempDL/textadept-LATEST-i386.tgz -C /home/$superuser/Downloads/TempDL/textadept-LATEST --strip-components 1
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
textadeptbin=`locate textadept | grep -w "textadept-latest/textadept" | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/textadept-LATEST/textadept
Name=Textadept
Comment=Textadept
Icon=/home/$superuser/textadept-latest/core/images/textadept.png" >> /home/$superuser/Desktop/text-adept.desktop
sudo chmod +x /home/$superuser/Desktop/text-adept.desktop
else
:
fi
printf "\nText Adept installation Has Finished\n\n"
;;

109) # Tixati (P2P Torrent)
sudo apt install lynx -y
sudo apt install gdebi -y
if [ "$cpuarch" = "x86_64" ];then
tixati64=`lynx -dump https://www.tixati.com/download/linux.html | awk '/http/{print $2}' | grep amd64.deb | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/tixati-latest-amd64.deb $tixati64
sudo dpkg -i /home/$superuser/Downloads/TempDL/tixati-latest-amd64.deb
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
tixati32=`lynx -dump https://www.tixati.com/download/linux.html | awk '/http/{print $2}' | grep i686.deb | head -n 1`
sudo wget -O /home/$superuser/Downloads/TempDL/tixati-latest-i686.deb $tixati32
sudo dpkg -i /home/$superuser/Downloads/TempDL/tixati-latest-i686.deb
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/tixati
Name=Tixati
Comment=Tixati
Icon=/usr/share/icons/hicolor/48x48/apps/tixati.png" >> /home/$superuser/Desktop/tixati.desktop
sudo chmod +x /home/$superuser/Desktop/tixati.desktop
else
:
fi
printf "\nTixati (P2P Torrent) installation Has Finished\n\n"
;;

110) # Darktable (PPA)
wget -nv https://download.opensuse.org/repositories/graphics:darktable/xUbuntu_16.04/Release.key -O /home/$superuser/Downloads/TempDL/signing-keys/Release.key
sudo apt-key add - < /home/$superuser/Downloads/TempDL/signing-keys/Release.key
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/graphics:/darktable/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/graphics:darktable.list"
sudo apt update
sudo apt install darktable -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/darktable
Name=Darktable
Comment=Darktable
Icon=/usr/share/icons/hicolor/64x64/apps/darktable.png" >> /home/$superuser/Desktop/darktable.desktop
sudo chmod +x /home/$superuser/Desktop/darktable.desktop
else
:
fi
printf "\nDarktable (PPA) installation Has Finished\n\n"
;;

111) # Liferea (PPA)
sudo add-apt-repository ppa:ubuntuhandbook1/apps -y
sudo apt update
sudo apt install liferea -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/liferea
Name=Liferea
Comment=Liferea
Icon=/usr/share/icons/hicolor/48x48/apps/liferea.png" >> /home/$superuser/Desktop/liferea.desktop
sudo chmod +x /home/$superuser/Desktop/liferea.desktop
else
:
fi
printf "\nLiferea (PPA) installation Has Finished\n\n"
;;

112) # Typecatcher (PPA)
sudo add-apt-repository ppa:andrewsomething/typecatcher -y
sudo apt update
sudo apt install typecatcher -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/typecatcher
Name=Typecatcher
Comment=Typecatcher
Icon=/usr/share/help/C/typecatcher/figures/home.png" >> /home/$superuser/Desktop/typecatcher.desktop
sudo chmod +x /home/$superuser/Desktop/typecatcher.desktop
else
:
fi
printf "\nTypecatcher (PPA) installation Has Finished\n\n"
;;

113) # Caffeine (PPA)
sudo add-apt-repository ppa:caffeine-developers/ppa -y
sudo apt update
sudo apt install caffeine -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/caffeine-indicator
Name=Caffeine
Comment=Caffeine
Icon=/usr/share/icons/hicolor/48x48/apps/caffeine.png" >> /home/$superuser/Desktop/caffeine.desktop
sudo chmod +x /home/$superuser/Desktop/caffeine.desktop
else
:
fi
printf "\nCaffeine (PPA) installation Has Finished\n\n"
;;

114) # XnConvert
if [ "$cpuarch" = "x86_64" ];then
sudo wget -O /home/$superuser/Downloads/TempDL/xnconvert-x64.deb https://download.xnview.com/XnConvert-linux-x64.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/xnconvert-x64.deb
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
sudo wget -O /home/$superuser/Downloads/TempDL/xnconvert-x86.deb https://download.xnview.com/XnConvert-linux.deb
sudo dpkg -i /home/$superuser/Downloads/TempDL/xnconvert-x86.deb
fi
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/xnconvert
Name=XnConvert
Comment=XnConvert
Icon=/opt/XnConvert/xnconvert.png" >> /home/$superuser/Desktop/xnconvert.desktop
sudo chmod +x /home/$superuser/Desktop/xnconvert.desktop
else
:
fi
printf "\nXnConvert installation Has Finished\n\n"
;;

115) # Riot (PPA)
sudo sh -c "echo 'deb https://riot.im/packages/debian/ xenial main' > /etc/apt/sources.list.d/matrix-riot-im.list"
curl -L https://riot.im/packages/debian/repo-key.asc | sudo apt-key add -
sudo apt update
sudo apt install riot-web -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/Riot/riot-web
Name=Riot
Comment=Riot
Icon=/usr/share/icons/hicolor/64x64/apps/riot-web.png" >> /home/$superuser/Desktop/riot.desktop
sudo chmod +x /home/$superuser/Desktop/riot.desktop
else
:
fi
printf "\nRiot (PPA) installation Has Finished\n\n"
;;

116) # Jitsi Meet (PPA)
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -
sudo sh -c "echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list"
sudo apt update
sudo apt install jitsi-meet -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/Riot/riot-web
Name=Riot
Comment=Riot
Icon=/usr/share/icons/hicolor/64x64/apps/riot-web.png" >> /home/$superuser/Desktop/riot.desktop
sudo chmod +x /home/$superuser/Desktop/riot.desktop
else
:
fi
printf "\nRiot (PPA) installation Has Finished\n\n"
;;

117) # Feedreader (PPA)
sudo add-apt-repository ppa:eviltwin1/feedreader-stable -y
sudo apt update
sudo apt install feedreader -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/feedreader
Name=Feedreader
Comment=Feedreader
Icon=/usr/share/icons/hicolor/64x64/apps/feedreader.svg" >> /home/$superuser/Desktop/feedreader.desktop
sudo chmod +x /home/$superuser/Desktop/feedreader.desktop
else
:
fi
printf "\nFeedreader (PPA) installation Has Finished\n\n"
;;

118) # Go For It (PPA)
sudo add-apt-repository ppa:mank319/go-for-it -y
sudo apt update
sudo apt install go-for-it -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/feedreader
Name=Feedreader
Comment=Feedreader
Icon=/usr/share/icons/hicolor/64x64/apps/feedreader.svg" >> /home/$superuser/Desktop/feedreader.desktop
sudo chmod +x /home/$superuser/Desktop/feedreader.desktop
else
:
fi
printf "\nFeedreader (PPA) installation Has Finished\n\n"
;;

119) # Calibre
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/calibre
Name=Calibre
Comment=Calibre
Icon=/usr/share/icons/hicolor/64x64/apps/calibre-gui.png" >> /home/$superuser/Desktop/calibre.desktop
sudo chmod +x /home/$superuser/Desktop/calibre.desktop
else
:
fi
printf "\nCalibre installation Has Finished\n\n"
;;

120) # Rambox Community Edition (Snap)
sudo apt install snapd -y
sudo snap install rambox
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
ramboxlogolocation=`locate /snap/rambox/ | grep /gui/icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/rambox
Name=Rambox
Comment=Rambox
Icon=$ramboxlogolocation" >> /home/$superuser/Desktop/rambox.desktop
sudo chmod +x /home/$superuser/Desktop/rambox.desktop
else
:
fi
printf "\nRambox installation Has Finished\n\n"
;;

121) # Java 8 JDK (PPA)
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt update
sudo apt install oracle-java8-installer -y
printf "\nJava 8 JDK (PPA) installation Has Finished\n\n"
;;

122) # Java 11 JDK (PPA)
sudo add-apt-repository ppa:linuxuprising/java -y
sudo apt update
sudo apt install oracle-java11-installer -y
printf "\nJava 11 JDK (PPA) installation Has Finished\n\n"
;;

123) # Hiri (Snap)
sudo apt install snapd -y
sudo snap install hiri
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
hirilogolocation=`locate /snap/hiri/ | grep /gui/icon.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/hiri
Name=Hiri
Comment=Hiri
Icon=$hirilogolocation" >> /home/$superuser/Desktop/hiri.desktop
sudo chmod +x /home/$superuser/Desktop/hiri.desktop
else
:
fi
printf "\nHiri installation Has Finished\n\n"
;;

124) # Variety (PPA)
sudo add-apt-repository ppa:peterlevi/ppa -y
sudo apt update
sudo apt install variety variety-slideshow -y
printf "\nVariety installation Has Finished\n\n"
;;

125) # Flash Player (Pepper Flash)
sudo apt install pepperflashplugin-nonfree -y
sudo update-pepperflashplugin-nonfree --install
printf "\nFlash Player (Pepper Flash) installation Has Finished\n\n"
;;

126) # Electron Player (Snap)
sudo apt install snapd -y
sudo snap install electronplayer
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
electronplayerlogolocation=`locate /snap/electronplayer/ | grep /gui/icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/electronplayer
Name=Electron Player
Comment=Electron Player
Icon=$electronplayerlogolocation" >> /home/$superuser/Desktop/Electron-Player.desktop
sudo chmod +x /home/$superuser/Desktop/Electron-Player.desktop
else
:
fi
printf "\nElectron Player installation Has Finished\n\n"
;;

127) # Plex Media Server (Snap)
sudo apt install snapd -y
sudo snap install plexmediaserver
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
plexmedialogolocation=`locate /snap/plexmediaserver/ | grep pms-web.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/plexmediaserver
Name=Plex Media Server
Comment=Plex Media Server
Icon=$plexmedialogolocation" >> /home/$superuser/Desktop/plex-media-server.desktop
sudo chmod +x /home/$superuser/Desktop/plex-media-server.desktop
else
:
fi
printf "\nPlex Media Server installation Has Finished\n\n"
;;

128) # E-tools (Snap)
sudo apt install snapd -y
sudo snap install e-tools
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
etoolslogolocation=`locate /snap/e-tools/ | grep /gui/icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/e-tools
Name=E-tools
Comment=E-tools
Icon=$etoolslogolocation" >> /home/$superuser/Desktop/e-tools.desktop
sudo chmod +x /home/$superuser/Desktop/e-tools.desktop
else
:
fi
printf "\nE-tools installation Has Finished\n\n"
;;

129) # Blender (Snap)
sudo apt install snapd -y
sudo snap install blender --classic
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
blenderlogolocation=`locate /snap/blender/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/blender
Name=Blender
Comment=Blender
Icon=$blenderlogolocation" >> /home/$superuser/Desktop/blender.desktop
sudo chmod +x /home/$superuser/Desktop/blender.desktop
else
:
fi
printf "\nBlender installation Has Finished\n\n"
;;

130) # IrfanView (Snap)
sudo apt install snapd -y
sudo snap install irfanview
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
irfanviewlogolocation=`locate /snap/irfanview/ | grep irfanview64.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/irfanview
Name=IrfanView
Comment=IrfanView
Icon=$irfanviewlogolocation" >> /home/$superuser/Desktop/irfanview.desktop
sudo chmod +x /home/$superuser/Desktop/irfanview.desktop
else
:
fi
printf "\nIrfanView installation Has Finished\n\n"
;;

131) # Altus
sudo apt install lynx -y
altusappimage=`lynx -dump https://github.com/ShadyThGod/altus/releases | awk '/http/{print $2}' | grep .AppImage | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/altus-latest-release.AppImage $altusappimage
sudo chmod +x /home/$superuser/Downloads/TempDL/altus-latest-release.AppImage
wget -O /home/$superuser/Downloads/TempDL/altus-logo.png https://cn.opendesktop.org/cache/400x400/img/6/1/5/f/7b47bdb468bef3a766fd21a86d6e1829534a.png
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/altus-latest-release.AppImage
Name=Altus
Comment=Altus
Icon=/home/$superuser/Downloads/TempDL/altus-logo.png" >> /home/$superuser/Desktop/altus.desktop
sudo chmod +x /home/$superuser/Desktop/altus.desktop
else
:
fi
printf "\nAltus installation Has Finished\n\n"
;;

132) # Mumble
sudo add-apt-repository ppa:mumble/release -y
sudo apt update
sudo apt install mumble -y

#To install and configure
#sudo apt install mumble-server -y
#sudo dpkg-reconfigure mumble-server

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/home/$superuser/Downloads/TempDL/altus-latest-release.AppImage
Name=Altus
Comment=Altus
Icon=/home/$superuser/Downloads/TempDL/altus-logo.png" >> /home/$superuser/Desktop/altus.desktop
sudo chmod +x /home/$superuser/Desktop/altus.desktop
else
:
fi
printf "\nAltus installation Has Finished\n\n"
;;

133) # Pale Moon
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/stevenpusser/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/home:stevenpusser.list"
wget -nv https://download.opensuse.org/repositories/home:stevenpusser/xUbuntu_16.04/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt update
sudo apt install palemoon -y

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/palemoon
Name=Pale Moon
Comment=Pale Moon
Icon=/usr/share/pixmaps/palemoon.png" >> /home/$superuser/Desktop/palemoon.desktop
sudo chmod +x /home/$superuser/Desktop/palemoon.desktop
else
:
fi
printf "\nPale Moon installation Has Finished\n\n"
;;

134) # Midori
sudo apt install snapd -y
sudo snap install midori

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
midorilogolocation=`locate /64x64/midori_midori.png`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/midori
Name=Midori
Comment=Midori
Icon=$midorilogolocation" >> /home/$superuser/Desktop/midori.desktop
sudo chmod +x /home/$superuser/Desktop/midori.desktop
else
:
fi
printf "\nMidori installation Has Finished\n\n"
;;

135) # Simplenote (Snap)
sudo apt install snapd -y
sudo snap install simplenote

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
simplenotelogolocation=`locate /snap/simplenote/ | grep simplenote.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/simplenote
Name=Simplenote
Comment=Simplenote
Icon=$simplenotelogolocation" >> /home/$superuser/Desktop/simplenote.desktop
sudo chmod +x /home/$superuser/Desktop/simplenote.desktop
else
:
fi
printf "\nSimplenote installation Has Finished\n\n"
;;

136) # Midnight Commander
sudo apt install mc -y

printf "\nMidnight Commander installation Has Finished\n\n"
;;

137) # Pycharm Community Edition (Snap)
sudo apt install snapd -y
sudo snap install pycharm-community --classic

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
pycharmlogolocation=`locate /snap/pycharm-community/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/pycharm-community
Name=Pycharm Community
Comment=Pycharm Community
Icon=$pycharmlogolocation" >> /home/$superuser/Desktop/pycharm-community.desktop
sudo chmod +x /home/$superuser/Desktop/pycharm-community.desktop
else
:
fi
printf "\nPycharm Community Edition installation Has Finished\n\n"
;;

138) # Postman (PPA)
sudo add-apt-repository ppa:tiagohillebrandt/postman -y
sudo apt update
sudo apt install postman -y 

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/postman
Name=Postman
Comment=Postman
Icon=/usr/share/postman/app/resources/app/assets/icon.png" >> /home/$superuser/Desktop/postman.desktop
sudo chmod +x /home/$superuser/Desktop/postman.desktop
else
:
fi
printf "\nPostman installation Has Finished\n\n"
;;

139) # Notepad-Plus-Plus (Snap)
sudo apt install snapd -y
sudo snap install notepad-plus-plus

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
notepadpluspluslogolocation=`locate /snap/notepad-plus-plus/ | grep notepad-plus-plus.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/notepad-plus-plus
Name=Notepad-Plus-Plus
Comment=Notepad-Plus-Plus
Icon=$notepadpluspluslogolocation" >> /home/$superuser/Desktop/notepad-plus-plus.desktop
sudo chmod +x /home/$superuser/Desktop/notepad-plus-plus.desktop
else
:
fi
printf "\nNotepad-Plus-Plus installation Has Finished\n\n"
;;

140) # PhpStorm (Snap)
sudo apt install snapd -y
sudo snap install phpstorm --classic

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
phpstormlogolocation=`locate /snap/phpstorm/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/phpstorm
Name=PhpStorm
Comment=PhpStorm
Icon=$phpstormlogolocation" >> /home/$superuser/Desktop/phpstorm.desktop
sudo chmod +x /home/$superuser/Desktop/phpstorm.desktop
else
:
fi
printf "\nPhpStorm installation Has Finished\n\n"
;;

141) # Powershell (Snap)
sudo apt install snapd -y
sudo snap install powershell --classic

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
powershelllogolocation=`locate /snap/powershell/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/powershell
Name=Powershell
Comment=Powershell
Icon=$powershelllogolocation" >> /home/$superuser/Desktop/powershell.desktop
sudo chmod +x /home/$superuser/Desktop/powershell.desktop
else
:
fi
printf "\nPowershell installation Has Finished\n\n"
;;

142) # Cacher (Snap)
sudo apt install snapd -y
sudo snap install cacher

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
cacherlogolocation=`locate /snap/cacher/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/cacher
Name=Cacher
Comment=Cacher
Icon=$cacherlogolocation" >> /home/$superuser/Desktop/cacher.desktop
sudo chmod +x /home/$superuser/Desktop/cacher.desktop
else
:
fi
printf "\nCacher installation Has Finished\n\n"
;;

143) # WebStorm (Snap)
sudo apt install snapd -y
sudo snap install webstorm --classic

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
webstormlogolocation=`locate /snap/webstorm | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/webstorm
Name=Webstorm
Comment=Webstorm
Icon=$webstormlogolocation" >> /home/$superuser/Desktop/webstorm.desktop
sudo chmod +x /home/$superuser/Desktop/webstorm.desktop
else
:
fi
printf "\nWebstorm installation Has Finished\n\n"
;;

144) # Insomnia (Snap)
sudo apt install snapd -y
sudo snap install insomnia

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
insomnialogolocation=`locate /snap/insomnia/ | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/insomnia
Name=Insomnia
Comment=Insomnia
Icon=$insomnialogolocation" >> /home/$superuser/Desktop/insomnia.desktop
sudo chmod +x /home/$superuser/Desktop/insomnia.desktop
else
:
fi
printf "\nInsomnia installation Has Finished\n\n"
;;

145) # Opera (Snap)
sudo apt install snapd -y
sudo snap install opera

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
operalogolocation=`locate opera | grep opera.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/opera
Name=Opera
Comment=Opera
Icon=$operalogolocation" >> /home/$superuser/Desktop/opera.desktop
sudo chmod +x /home/$superuser/Desktop/opera.desktop
else
:
fi
printf "\nOpera installation Has Finished\n\n"
;;

146) # Google Chorome (PPA)
sudo wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt update
sudo apt install google-chrome-stable -y

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/google-chrome-stable
Name=Google Chrome
Comment=Google Chrome
Icon=/usr/share/icons/hicolor/128x128/apps/google-chrome.png" >> /home/$superuser/Desktop/google-chrome.desktop
sudo chmod +x /home/$superuser/Desktop/google-chrome.desktop
else
:
fi
printf "\nGoogle Chrome installation Has Finished\n\n"
;;

147) # Chromium (Snap)
sudo apt install snapd -y
sudo snap install chromium

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
chromiumlogolocation=`locate /snap/chromium/ | grep chromium.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/chromium
Name=Chromium
Comment=Chromium
Icon=$chromiumlogolocation" >> /home/$superuser/Desktop/chromium.desktop
sudo chmod +x /home/$superuser/Desktop/chromium.desktop
else
:
fi
printf "\nChromium installation Has Finished\n\n"
;;

148) # DBeaver Community Edition (PPA)
sudo add-apt-repository ppa:serge-rider/dbeaver-ce -y
sudo apt update
sudo apt install dbeaver-ce -y
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/dbeaver
Name=DBeaver Community Edition
Comment=DBeaver Community Edition
Icon=/usr/share/dbeaver/dbeaver.png" >> /home/$superuser/Desktop/dbeaver.desktop
sudo chmod +x /home/$superuser/Desktop/dbeaver.desktop
else
:
fi
printf "\nDBeaver Community Edition installation Has Finished\n\n"
;;

149) # Valentina Studio

if [ "$cpuarch" = "x86_64" ];then
wget -O /home/$superuser/Downloads/TempDL/Valentina-Studio-x64.deb https://www.valentina-db.com/en/all-downloads/vstudio/current/vstudio_x64_lin-deb?format=raw
sudo dpkg -i /home/$superuser/Downloads/TempDL/Valentina-Studio-x64.deb

elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
wget -O /home/$superuser/Downloads/TempDL/Valentina-Studio-x86.deb https://www.valentina-db.com/en/all-downloads/vstudio/current/vstudio_lin_32_debian?format=raw
sudo dpkg -i /home/$superuser/Downloads/TempDL/Valentina-Studio-x86.deb
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/opt/VStudio/vstudio
Name=Valentina Studio
Comment=Valentina Studio
Icon=/opt/VStudio/Resources/vstudio.png" >> /home/$superuser/Desktop/valentina-studio.desktop
sudo chmod +x /home/$superuser/Desktop/valentina-studio.desktop
else
:
fi
printf "\nValentina Studio installation Has Finished\n\n"
;;

150) # SQuirreL SQL
sudo apt install snapd -y
sudo snap install squirrelsql

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
squirrelsqllogolocation=`locate squirrel | grep /gui/icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/squirrelsql
Name=SQuirreL SQL
Comment=SQuirreL SQL
Icon=$squirrelsqllogolocation" >> /home/$superuser/Desktop/squirrelsql.desktop
sudo chmod +x /home/$superuser/Desktop/squirrelsql.desktop
else
:
fi
printf "\nSquirrel SQL installation Has Finished\n\n"
;;

151) # DbVisualizer
sudo apt install lynx -y
sudo add-apt-repository ppa:linuxuprising/java -y
sudo apt update
sudo apt install oracle-java11-installer -y
dbvisualizer=`lynx -dump https://www.dbvis.com/download/ | awk '/http/{print $2}' | grep linux | grep .deb | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/dbvisualizer-latest.deb $dbvisualizer
sudo dpkg -i /home/$superuser/Downloads/TempDL/dbvisualizer-latest.deb
if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
dbvisualizerlocation=`locate /bin/dbvis | head -n 1`
dbvisualizerlogolocation=`locate dbvis | grep dbvis.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/local/bin/dbvis
Name=DbVisualizer
Comment=DbVisualizer
Icon=$dbvisualizerlogolocation" >> /home/$superuser/Desktop/DbVisualizer.desktop
sudo chmod +x /home/$superuser/Desktop/DbVisualizer.desktop
else
:
fi
printf "\nDbVisualizer installation Has Finished\n\n"
;;

152) # DataGrip (Snap)
sudo apt install snapd -y
sudo snap install datagrip --classic

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
datagriplogolocation=`locate datagrip | grep icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/datagrip
Name=DataGrip
Comment=DataGrip
Icon=$datagriplogolocation" >> /home/$superuser/Desktop/datagrip.desktop
sudo chmod +x /home/$superuser/Desktop/datagrip.desktop
else
:
fi
printf "\nDataGrip installation Has Finished\n\n"
;;

153) # PgAdmin
sudo apt install curl ca-certificates -y
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
cat > /etc/apt/sources.list.d/pgdg.list <<EOF
deb http://apt.postgresql.org/pub/repos/apt/ $codename-pgdg main
#deb-src http://apt.postgresql.org/pub/repos/apt/ $codename-pgdg main
EOF
sudo apt update
sudo apt install postgresql-11 pgadmin4 -y

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/pgadmin4
Name=PgAdmin
Comment=PgAdmin
Icon=/usr/share/icons/hicolor/256x256/apps/pgadmin4.png" >> /home/$superuser/Desktop/pgadmin.desktop
sudo chmod +x /home/$superuser/Desktop/pgadmin.desktop
else
:
fi
printf "\nPgAdmin installation Has Finished\n\n"
;;

154) # Remmina (PPA)
sudo apt-add-repository ppa:remmina-ppa-team/remmina-next -y
sudo apt update
sudo apt install remmina remmina-plugin-rdp remmina-plugin-secret remmina-plugin-spice -y

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/remmina
Name=Remmina
Comment=Remmina
Icon=/usr/share/icons/hicolor/128x128/apps/org.remmina.Remmina.png" >> /home/$superuser/Desktop/remmina.desktop
sudo chmod +x /home/$superuser/Desktop/remmina.desktop
else
:
fi
printf "\nRemmina installation Has Finished\n\n"
;;

155) # Anydesk
sudo apt install lynx -y

if [ "$cpuarch" = "x86_64" ];then
anydesk64=`lynx -dump https://anydesk.com/en/downloads/linux | awk '/http/{print $2}' | grep amd64.deb | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/anydesk-latest-x64.deb $anydesk64
sudo dpkg -i /home/$superuser/Downloads/TempDL/anydesk-latest-x64.deb
sudo apt -f install -y
elif [ "$cpuarch" = "x86" ] || [ "$cpuarch" = "i386" ] || [ "$cpuarch" = "i486" ] || [ "$cpuarch" = "i586" ] || [ "$cpuarch" = "i686" ];then
anydesk32=`lynx -dump https://anydesk.com/en/downloads/linux | awk '/http/{print $2}' | grep i386.deb | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/anydesk-latest-x86.deb $anydesk32
sudo dpkg -i /home/$superuser/Downloads/TempDL/anydesk-latest-x86.deb
sudo apt -f install -y
fi

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/usr/bin/anydesk
Name=Anydesk
Comment=Anydesk
Icon=/usr/share/pixmaps/anydesk.png" >> /home/$superuser/Desktop/anydesk.desktop
sudo chmod +x /home/$superuser/Desktop/anydesk.desktop
else
:
fi
printf "\nAnydesk installation Has Finished\n\n"
;;

156) # Vnc4server

sudo apt install vnc4server xfce4 xfce4-goodies -y
sudo vncpasswd
sudo mkdir -v ~/.vnc
sudo echo "#!/bin/bash
startxfce4 &" >> ~/.vnc/xstartup
sudo chmod -v +x ~/.vnc/xstartup
sudo vnc4server
sudo ufw allow from any to any port 5901 proto tcp
sudo ss -ltn
cat <(crontab -l) <(echo "@reboot vnc4server") | crontab -

printf "\nVnc4server installation Has Finished\n\n"
;;

157) # DVBlast
sudo apt install lynx gcc libev-dev -y
dvblastlink=`lynx -dump https://www.videolan.org/projects/dvblast.html | awk '/http/{print $2}' | grep .tar.bz2 | head -n 1`
wget -O /home/$superuser/Downloads/TempDL/dvblast-latest.tar.bz2 $dvblastlink
sudo tar xvf /home/$superuser/Downloads/TempDL/dvblast-latest.tar.bz2 -C /home/$superuser/Downloads/TempDL/dvblast-latest --strip-components 1
cd /home/$superuser/Downloads/TempDL/dvblast-latest
make
make install
dvblast --version

printf "\nDVBlast installation Has Finished\n\n"
;;

158) # ElectronMail (Snap)
sudo apt install snapd lynx -y
sudo snap install electron-mail

if [ "$shortcut" = "Y" ] || [ "$shortcut" = "y" ];then
sudo updatedb
electronmaillogo=`locate meta/gui/icon.png | head -n 1`
echo "#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=/snap/bin/electron-mail
Name=ElectronMail
Comment=ElectronMail
Icon=$electronmaillogo" >> /home/$superuser/Desktop/electronmail.desktop
sudo chmod +x /home/$superuser/Desktop/electronmail.desktop
else
:
fi
printf "\nElectronMail installation Has Finished\n\n"
;;

159) # LXD (Snap)
sudo apt install snapd lynx -y
sudo snap install lxd
printf "\nLXD installation Has Finished\n\n"
;;
        esac
    fi
done