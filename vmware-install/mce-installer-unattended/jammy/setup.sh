#!/bin/bash

# Ubuntu 22.04 (Jammy) specific setup script for LinuxMCE

# Source common installer functions
. /tmp/mce_wizard_data.sh
. ../mce-installer-common.sh

# Ubuntu 22.04 specific packages and configurations
function setup_jammy_specific() {
    echo "Setting up Ubuntu 22.04 (Jammy) specific configurations..."
    
    # Update package lists
    apt-get update
    
    # Install necessary packages for Ubuntu 22.04
    apt-get install -y \
        network-manager \
        python3 \
        python3-minimal \
        python3-apt \
        systemd-resolved \
        systemd-timesyncd \
        network-manager-openvpn \
        network-manager-vpnc \
        network-manager-l2tp
    
    # Set up systemd-resolved if needed
    if [ -f /etc/systemd/resolved.conf ]; then
        # Backup original config
        cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup
        
        # Configure DNS settings for LinuxMCE
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=127.0.0.1
FallbackDNS=8.8.8.8 8.8.4.4
Domains=
DNSSEC=no
DNSOverTLS=no
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
EOF
    fi
    
    # Set up systemd-networkd if needed
    systemctl enable systemd-networkd.service
    systemctl enable systemd-resolved.service
    
    # Configure apparmor for LinuxMCE requirements
    if [ -d /etc/apparmor.d ]; then
        for profile in /etc/apparmor.d/usr.bin.*; do
            if [ -f "$profile" ]; then
                echo "$profile { }" > "$profile.linuxmce"
                ln -sf "$profile.linuxmce" "$profile"
            fi
        done
    fi
    
    # Any other Ubuntu 22.04 specific configurations
    echo "Jammy setup completed"
}

# Run the Ubuntu 22.04 specific setup
setup_jammy_specific

# Return to the main installer
exit 0