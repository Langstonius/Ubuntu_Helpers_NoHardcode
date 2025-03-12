#!/bin/bash

set -e


Distro="$(lsb_release -c -s | tr -d '\n')"
Release="$(lsb_release -s -r | tr -d '\n')"
Arch="$(apt-config dump | grep '^APT::Architecture' | sed 's/.* "\(.*\)";$/\1/g' | head -1 | tr -d '\n')"

# Install default config files
echo "Installing Default Configs For $Distro-$Arch"
if [ -L "/etc/lmce-build" ]; then
    echo "Found symlink at /etc/lmce-build, unlinking..."
    unlink "/etc/lmce-build"
else
    echo "No symlink found at /etc/lmce-build, checking if it exists..."
    if [ -e "/etc/lmce-build" ]; then
        echo "File or directory exists at /etc/lmce-build, removing..."       
    fi
fi

ln -s "$(pwd)/conf-files/${Distro}-${Arch}" "/etc/lmce-build"

echo "Creating symlink in /usr/local/lmce-build"
if [ -L "/usr/local/lmce-build" ]; then
    echo "Found symlink at /usr/local/lmce-build, unlinking..."
    unlink "/usr/local/lmce-build"
else
    echo "No symlink found at /usr/local/lmce-build, checking if it exists..."
    if [ -e "/usr/local/lmce-build" ]; then
        echo "File or directory exists at /usr/local/lmce-build, removing..."
        rm -rf "/usr/local/lmce-build"
    fi
fi
ln -s "$(pwd)" "/usr/local/lmce-build"

#echo "Configure APT preferences"
#echo '
#Package: *
#Pin: origin
#Pin-Priority: 9999
#
#Package: *
#Pin: release v='${Release}',o=Ubuntu,a='${Distro}',l=Ubuntu
#Pin-Priority: 9998
#' > /etc/apt/preferences

# Generate ssh key for builder if !exist
if [[ ! -f /etc/lmce-build/builder.key ]] ;then
	echo "Generating SSH Key for this host : /etc/lmce-build/builder.key"
	ssh-keygen -N '' -C "LinuxMCE Builder $Distro $Arch" -f /etc/lmce-build/builder.key
else
	echo "SSH Key found on this host : /etc/lmce-build/builder.key"
fi

