#!/bin/bash

# Check for root permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to detect the operating system and environment
detect_os_env() {
    os=$(uname -s)
    case $os in
        Linux)
            if grep -q Microsoft /proc/version; then
                env="Kali WSL"
            elif grep -q Kali /etc/os-release; then
                env="Kali"
            else
                env="Linux"
            fi
            ;;
        Darwin)
            env="macOS"
            ;;
        *)
            echo "Unsupported OS: $os"
            exit 1
            ;;
    esac
    echo "Detected environment: $env"
}

# Function to download Kali Linux ISO
download_kali_iso() {
    echo "Select the architecture for the Kali Linux ISO:"
    echo "1. ARM64"
    echo "2. AMD64"
    echo "3. Apple M2 Silicon Chipset"
    read -p "Enter the number corresponding to your choice: " arch_choice

    case $arch_choice in
        1)
            arch="arm64"
            ;;
        2)
            arch="amd64"
            ;;
        3)
            arch="apple-silicon"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    echo "Do you want to download the full setup with meta packages or a barebones setup?"
    echo "1. Full setup with meta packages"
    echo "2. Barebones setup"
    read -p "Enter the number corresponding to your choice: " setup_choice

    case $setup_choice in
        1)
            setup="everything-live"
            ;;
        2)
            setup="barebones"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    echo "Downloading Kali Linux $setup for $arch..."
    wget -O kali-linux-$setup-$arch.iso https://cdimage.kali.org/kali-2023.2/kali-linux-2023.2-$setup-$arch.iso
}

# Function to detect the SD card drive
detect_sd_card() {
    echo "Detecting SD card drive..."
    # List all removable drives
    drives=$(lsblk -o NAME,MODEL,SIZE,TYPE | grep -E 'disk|part' | grep -v 'loop' | grep -E 'sd|mmcblk')

    if [ -z "$drives" ]; then
        echo "No removable drives detected. Please insert the SD card and try again."
        exit 1
    fi

    echo "Available drives:"
    echo "$drives"
    echo
    echo "Please enter the device name of the SD card (e.g., sdb, mmcblk0):"
    read sd_card

    if [ -z "$sd_card" ]; then
        echo "No device name entered. Exiting."
        exit 1
    fi

    sd_card_path="/dev/$sd_card"
    echo "Selected SD card: $sd_card_path"
}

# Function to format the SD card
format_sd_card() {
    echo "Formatting SD card..."

    # Unmount the SD card if it's mounted
    sudo umount ${sd_card_path}* || true

    # Create a new partition table
    echo -e "o\nn\np\n1\n\n+4G\nn\np\n2\n\n\nw" | sudo fdisk $sd_card_path

    # Format the first partition as FAT32
    sudo mkfs.vfat -F 32 ${sd_card_path}1

    # Format the second partition as ext4
    sudo mkfs.ext4 ${sd_card_path}2

    echo "SD card formatted successfully."
}

# Function to write ISO to SD card
write_iso_to_sd() {
    echo "Writing ISO to SD card..."

    # Confirm the device path
    read -p "This will overwrite all data on $sd_card_path. Are you sure? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Operation cancelled."
        exit 1
    fi

    # Write the ISO to the microSD card
    sudo dd if=kali-linux-$setup-$arch.iso of=${sd_card_path}1 bs=4M status=progress conv=fsync

    echo "ISO successfully written to $sd_card_path."
}

# Function to add encrypted persistence
add_encrypted_persistence() {
    echo "Adding encrypted persistence..."

    # Create a new partition for persistence
    echo -e "n\np\n\n\n\nw" | sudo fdisk $sd_card_path

    # Format the new partition with LUKS encryption
    sudo cryptsetup --verbose --verify-passphrase luksFormat ${sd_card_path}3

    # Open the encrypted partition
    sudo cryptsetup luksOpen ${sd_card_path}3 my_usb

    # Create an ext4 filesystem and label it
    sudo mkfs.ext4 -L persistence /dev/mapper/my_usb
    sudo e2label /dev/mapper/my_usb persistence

    # Mount the partition and create the persistence.conf file
    sudo mkdir -p /mnt/my_usb
    sudo mount /dev/mapper/my_usb /mnt/my_usb
    echo "/ union" | sudo tee /mnt/my_usb/persistence.conf

    # Unmount and close the encrypted partition
    sudo umount /mnt/my_usb
    sudo cryptsetup luksClose /dev/mapper/my_usb

    echo "Encrypted persistence added successfully."
}

# Function to set up the custom Kali Linux install menu
setup_custom_install_menu() {
    echo "Setting up custom Kali Linux install menu..."

    # Download and extract Kali Linux ISO
    mkdir kali-custom
    cd kali-custom
    wget https://cdimage.kali.org/kali-2023.2/kali-linux-2023.2-live-amd64.iso
    7z x kali-linux-2023.2-live-amd64.iso

    # Add custom 8K Kali purple background
    mkdir -p iso/boot/grub
    wget -O iso/boot/grub/background.png https://images7.alphacoders.com/137/1370159.png

    # Create custom GRUB menu
    cat <<EOF > iso/boot/grub/grub.cfg
    set default=0
    set timeout=5
    set gfxmode=auto
    set gfxpayload=keep
    insmod gfxterm
    insmod png
    background_image /boot/grub/background.png
    menuentry "Kali Linux Live" {
        linux /live/vmlinuz boot=live findiso=/live/filesystem.squashfs
        initrd /live/initrd.img
    }
    menuentry "Kali Linux Install" {
        linux /install/vmlinuz boot=install findiso=/install/filesystem.squashfs
        initrd /install/initrd.img
    }
    menuentry "Reset Password" {
        linux /tools/reset-password/vmlinuz
        initrd /tools/reset-password/initrd.img
    }
    menuentry "Recover Deleted Files" {
        linux /tools/recover-files/vmlinuz
        initrd /tools/recover-files/initrd.img
    }
    menuentry "Fix Boot Issues" {
        linux /tools/fix-boot/vmlinuz
        initrd /tools/fix-boot/initrd.img
    }
    menuentry "Run Diagnostics" {
        linux /tools/diagnostics/vmlinuz
        initrd /tools/diagnostics/initrd.img
    }
    menuentry "Partition Tool" {
        linux /tools/partition-tool/vmlinuz
        initrd /tools/partition-tool/initrd.img
    }
    menuentry "Change GRUB Wallpaper" {
        linux /tools/change-wallpaper/vmlinuz
        initrd /tools/change-wallpaper/initrd.img
    }
    menuentry "Change Installation Menu Background" {
        linux /tools/change-install-bg/vmlinuz
        initrd /tools/change-install-bg/initrd.img
    }
    menuentry "Install Proxmox (Ethernet only)" {
        linux /install/proxmox/vmlinuz
        initrd /install/proxmox/initrd.img
    }
    EOF

    # Add tools and descriptions
    mkdir -p iso/tools/{reset-password,recover-files,fix-boot,diagnostics,partition-tool,change-wallpaper,change-install-bg,proxmox}
    # Add your tool binaries and initrd images to the respective directories

    # Modify preseed file for automated installation
    cat <<EOF > iso/preseed.cfg
    d-i debian-installer/locale string en_US
    d-i console-setup/ask_detect boolean false
    d-i console-setup/layoutcode string us
    d-i keyboard-configuration/xkb-keymap select us
    d-i netcfg/get_hostname string kali
    d-i netcfg/get_domain string unassigned-domain
    d-i passwd/root-password password yourpassword
    d-i passwd/root-password-again password yourpassword
    d-i clock-setup/utc boolean true
    d-i time/zone string UTC
    d-i partman-auto/method string regular
    d-i partman-auto/choose_recipe select atomic
    d-i partman/confirm boolean true
    d-i partman/confirm_nooverwrite boolean true
    d-i partman/confirm_write_new_label boolean true
    d-i pkgsel/include string openssh-server build-essential
    d-i pkgsel/upgrade select none
    d-i finish-install/reboot_in_progress note
    EOF

    # Add custom scripts for post-installation configurations
    cat <<EOF > iso/scripts/post-install.sh
    #!/bin/bash
    # Custom configurations
    cp /cdrom/wallpaper.jpg /usr/share/backgrounds/
    cp /cdrom/.bashrc /root/.bashrc
    echo "window manager settings" > /root/.config/window-manager/settings.conf
    echo "wifi settings" > /etc/wpa_supplicant/wpa_supplicant.conf
    echo "aliases" >> /root/.bash_aliases
    echo "custom options" >> /root/.custom_options

    # Install additional tools
    apt update
    apt install -y git gh realvnc-vnc-server teamviewer rdesktop anydesk vsftpd apache2 telnetd ssh2 autossh gemini-cli ms-copilot-cli chatgpt-cli

    # GitHub authentication
    echo "your_pat_token" | gh auth login --with-token

    # Enable and configure services
    systemctl enable ssh
    systemctl start ssh
    systemctl enable vsftpd apache2 telnetd
    systemctl start vsftpd apache2 telnetd

    # Allow password login and remote connections
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh

    # Save API keys
    echo "your_api_keys" > /root/.api_keys
    EOF
    chmod +x iso/scripts/post-install.sh

    # Modify boot menu to include preseed file
    sed -i 's/append initrd=initrd.gz/append initrd=initrd.gz preseed/file=\/cdrom\/preseed\/preseed.cfg/' iso/isolinux/txt.cfg

    # Rebuild the ISO
    mkisofs -o kali-linux-custom.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "Kali Linux Custom" iso/

    # Convert ISO to IMG
    dd if=kali-linux-custom.iso of=kali-linux-custom.img bs=4M

    echo "Custom Kali Linux ISO and IMG created successfully."
}

# Function to add aliases for WiFi reconnection
add_wifi_aliases() {
    echo "Adding WiFi reconnection aliases..."
    cat <<EOF >> /root/.bash_aliases
    alias wlanmon='ifconfig wlan0 down && iwconfig wlan0 mode monitor && ifconfig wlan0 up'
    alias wlan='ifconfig wlan0 down && iwconfig wlan0 mode managed && ifconfig wlan0 up'
    EOF
}

# Function to configure cloud settings
configure_cloud_settings() {
    echo "Configuring cloud settings..."
    cat <<EOF > iso/preseed/cloud.cfg
    # Cloud provider configurations
    datasource_list: [ NoCloud, ConfigDrive, DigitalOcean, AWS, Azure, GCE ]
    EOF
}

# Function to diagnose and fix Armitage and Metasploit issues
fix_armitage_metasploit_issues() {
    echo "Diagnosing and fixing Armitage and Metasploit issues..."
    cat <<EOF > iso/scripts/fix-armitage-metasploit.sh
    #!/bin/bash
    # Fix common Armitage and Metasploit issues
    systemctl start postgresql
    msfdb init
    export MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml
    msfconsole -x 'db_connect -y /usr/share/metasploit-framework/config/database.yml'
    EOF
    chmod +x iso/scripts/fix-armitage-metasploit.sh
}

# Function to set up shared database for Nmap, Zenmap, Armitage, and Metasploit
setup_shared_database() {
    echo "Setting up shared database for Nmap, Zenmap, Armitage, and Metasploit..."
    cat <<EOF > iso/scripts/setup-shared-db.sh
    #!/bin/bash
    # Initialize and configure shared database
    systemctl start postgresql
    msfdb init
    export MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml
    msfconsole -x 'db_connect -y /usr/share/metasploit-framework/config/database.yml'
    EOF
    chmod +x iso/scripts/setup-shared-db.sh
}

# Function to automate WiFi cracking and scanning
automate_wifi_cracking() {
    echo "Automating WiFi cracking and scanning..."
    cat <<EOF > iso/scripts/automate-wifi-cracking.sh
    #!/bin/bash
    # Run Wifite for 30 seconds and save results to Metasploit database
    timeout 30s wifite -i wlan0 --power 80
    msfconsole -x 'db_import /path/to/wifite/results'
    # Run Wireshark to capture packets
    timeout 1h wireshark -i wlan0 -k -w /path/to/wireshark/capture.pcap
    msfconsole -x 'db_import /path/to/wireshark/capture.pcap'
    # Run Nmap scan and save results to shared database
    nmap -sS -sU -O -oX /path/to/nmap/results.xml
    msfconsole -x 'db_import /path/to/nmap/results.xml'
    EOF
    chmod +x iso/scripts/automate-wifi-cracking.sh
}

# Function to change GRUB wallpaper
change_grub_wallpaper() {
    echo "Changing GRUB wallpaper..."
    mkdir -p /boot/grub/wallpapers
    echo "Place your wallpapers in /boot/grub/wallpapers"
    echo "Available wallpapers:"
    ls /boot/grub/wallpapers
    echo "Please enter the name of the wallpaper you want to set (e.g., wallpaper.png):"
    read wallpaper
    if [ -f /boot/grub/wallpapers/$wallpaper ]; then
        cp /boot/grub/wallpapers/$wallpaper /boot/grub/background.png
        echo "GRUB wallpaper changed to $wallpaper"
    else
        echo "Wallpaper not found."
    fi
}

# Function to change installation menu background
change_install_bg() {
    echo "Changing installation menu background..."
    mkdir -p /boot/grub/install-bg
    echo "Place your installation backgrounds in /boot/grub/install-bg"
    echo "Available backgrounds:"
    ls /boot/grub/install-bg
    echo "Please enter the name of the background you want to set (e.g., install-bg.png):"
    read install_bg
    if [ -f /boot/grub/install-bg/$install_bg ]; then
        cp /boot/grub/install-bg/$install_bg /boot/grub/install-background.png
        echo "Installation menu background changed to $install_bg"
    else
        echo "Background not found."
    fi
}

# Function to install VMware, VirtualBox, and HyperVisor
install_virtualization_tools() {
    echo "Installing VMware, VirtualBox, and HyperVisor..."
    apt update
    apt install -y open-vm-tools virtualbox virtualbox-ext-pack qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
}

# Function to install Proxmox
install_proxmox() {
    echo "Installing Proxmox (Ethernet only)..."
    echo "This installation requires an Ethernet connection."
    read -p "Do you want to proceed with Proxmox installation? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Proxmox installation cancelled."
        return
    fi

    # Add Proxmox repository and install Proxmox
    echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget -qO - http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg | apt-key add -
    apt update
    apt install -y proxmox-ve postfix open-iscsi

    # Configure Proxmox
    systemctl enable pve-cluster
    systemctl enable pvedaemon
    systemctl enable pveproxy
    systemctl enable pvestatd
    systemctl enable pve-firewall
    systemctl enable pve-ha-lrm
    systemctl enable pve-ha-crm
    systemctl enable pve-manager

    # Install GRUB and Kali Linux as VM under Proxmox
    echo "Installing GRUB and Kali Linux as VM under Proxmox..."
    apt install -y grub-pc
    grub-install /dev/sda
    update-grub

    # Create VM for Kali Linux
    qm create 100 --name kali-linux --memory 2048 --net0 virtio,bridge=vmbr0
    qm set 100 --ide2 local-lvm:cloudinit
    qm set 100 --boot c --bootdisk virtio0
    qm set 100 --serial0 socket --vga serial0
    qm set 100 --ide0 local-lvm:vm-100-disk-0,format=qcow2
    qm set 100 --scsihw virtio-scsi-pci
    qm set 100 --agent enabled=1
    qm set 100 --ciuser root --cipassword yourpassword
    qm set 100 --ipconfig0 ip=dhcp
    qm set 100 --sshkey /root/.ssh/id_rsa.pub
    qm set 100 --nameserver 8.8.8.8
    qm set 100 --searchdomain local
    qm set 100 --ostype l26
    qm set 100 --ide0 local-lvm:vm-100-disk-0,format=qcow2,size=32G
    qm set 100 --scsi0 local-lvm:vm-100-disk-1,format=qcow2,size=32G
    qm set 100 --boot c --bootdisk scsi0
    qm set 100 --serial0 socket --vga serial0
    qm set 100 --ide2 local-lvm:cloudinit
    qm set 100 --agent enabled=1
    qm set 100 --ciuser root --cipassword yourpassword
    qm set 100 --ipconfig0 ip=dhcp
    qm set 100 --sshkey /root/.ssh/id_rsa.pub
    qm set 100 --nameserver 8.8.8.8
    qm set 100 --searchdomain local
    qm set 100 --ostype l26

    echo "Proxmox and Kali Linux VM setup completed."
}

# Function to set up Ventoy on the microSD card
setup_ventoy() {
    echo "Setting up Ventoy on the microSD card..."
    wget https://github.com/ventoy/Ventoy/releases/download/v1.0.62/ventoy-1.0.62-linux.tar.gz
    tar -xzf ventoy-1.0.62-linux.tar.gz
    cd ventoy-1.0.62
    sudo sh Ventoy2Disk.sh -i ${sd_card_path}
    cd ..
    echo "Ventoy setup completed."
}

# Function to create an IMG file
create_img_file() {
    echo "Creating an IMG file..."
    dd if=kali-linux-custom.iso of=kali-linux-custom.img bs=4M
    echo "IMG file created successfully."
}

# Function to update all package managers
update_all() {
    echo "Updating all package managers..."
    bpkg update
    clib update
    gem update
    pip install --upgrade pip
    pip3 install --upgrade pip
    brew update
    brew upgrade
    pwsh -Command "Update-Module -Name PowerShellGet -Force"
    cmake --version
    lua5.3 -v
    gcc --version
    g++ --version
    perl -MCPAN -e 'install CPAN'
    npm update -g
    nvm install node --reinstall-packages-from=node
    yarn global upgrade
    apt update
    apt-get update
    debi update
    snap refresh
    snap-store refresh
    pipe update
    venv update
    ruby update
    synapse update
    aptitude update
}

# Function to upgrade all package managers
upgrade_all() {
    echo "Upgrading all package managers..."
    bpkg upgrade
    clib upgrade
    gem update --system
    pip install --upgrade pip setuptools
    pip3 install --upgrade pip setuptools
    brew upgrade
    pwsh -Command "Update-Module -Name PowerShellGet -Force"
    cmake --version
    lua5.3 -v
    gcc --version
    g++ --version
    perl -MCPAN -e 'install CPAN'
    npm update -g
    nvm install node --reinstall-packages-from=node
    yarn global upgrade
    apt upgrade -y
    apt-get upgrade -y
    debi upgrade
    snap refresh
    snap-store refresh
    pipe upgrade
    venv upgrade
    ruby upgrade
    synapse upgrade
    aptitude upgrade
}

# Function to perform a full upgrade
full_upgrade() {
    upgrade_all
    sudo apt-get -y upgrade && sudo apt-get -y full-upgrade
}

# Function to perform a dist-upgrade
dist_upgrade() {
    full_upgrade
    sudo apt-get -y dist-upgrade
}

# Function to check for breaking changes
check_for_breaking_changes() {
    echo "Checking for potential breaking changes..."
    # Add logic to check if upgrades will break Wifite3, Zenmap, NMAP, Armitage, or Metasploit
    # Placeholder for actual checks
    return 0
}

# Aliases
alias Update='update_all'
alias Upgrade='upgrade_all'
alias Full-Upgrade='full_upgrade'
alias Dist-Upgrade='dist_upgrade'

# Installation options
install_tools() {
    echo "Installing selected tools..."
    apt install -y django flask tabler apache2
    apt install -y wifite3 armitage metasploit-framework nmap ncat john hydra
    apt install -y hashcat burpsuite
    # Additional installation commands for other tools
}

# Metasploit post-exploitation process
metasploit_post_exploitation() {
    echo "Setting up Metasploit post-exploitation process..."
    # Add logic to pass hashes and salts to Hashcat using auto_helper.py
    # Placeholder for actual implementation
}

# Main script execution
main() {
    detect_os_env

    echo "Do you want to download the Kali Linux ISO?"
    read -p "Enter y/n: " download_iso
    if [ "$download_iso" == "y" ]; then
        download_kali_iso
    fi

    echo "Do you want to format the SD card?"
    read -p "Enter y/n: " format_sd
    if [ "$format_sd" == "y" ]; then
        detect_sd_card
        format_sd_card
    fi

    echo "Do you want to write the ISO to the SD card?"
    read -p "Enter y/n: " write_iso
    if [ "$write_iso" == "y" ]; then
        write_iso_to_sd
    fi

    echo "Do you want to add encrypted persistence?"
    read -p "Enter y/n: " encrypted_persistence
    if [ "$encrypted_persistence" == "y" ]; then
        add_encrypted_persistence
    fi

    echo "Do you want to set up the custom Kali Linux install menu?"
    read -p "Enter y/n: " custom_install_menu
    if [ "$custom_install_menu" == "y" ]; then
        setup_custom_install_menu
    fi

    echo "Do you want to install VMware, VirtualBox, and HyperVisor?"
    read -p "Enter y/n: " install_virtualization
    if [ "$install_virtualization" == "y" ]; then
        install_virtualization_tools
    fi

    echo "Do you want to install Proxmox?"
    read -p "Enter y/n: " install_proxmox
    if [ "$install_proxmox" == "y" ]; then
        install_proxmox
    fi

    echo "Do you want to set up Ventoy on the microSD card?"
    read -p "Enter y/n: " setup_ventoy
    if [ "$setup_ventoy" == "y" ]; then
        setup_ventoy
    fi

    echo "Do you want to create an IMG file?"
    read -p "Enter y/n: " create_img
    if [ "$create_img" == "y" ]; then
        create_img_file
    fi

    echo "Do you want to install additional tools?"
    read -p "Enter y/n: " install_additional_tools
    if [ "$install_additional_tools" == "y" ]; then
        install_tools
    fi

    echo "Do you want to perform updates?"
    read -p "Enter y/n: " perform_updates
    if [ "$perform_updates" == "y" ]; then
        Update
    fi

    echo "Do you want to perform upgrades?"
    read -p "Enter y/n: " perform_upgrades
    if [ "$perform_upgrades" == "y" ]; then
        Upgrade
    fi

    echo "Do you want to perform a full upgrade?"
    read -p "Enter y/n: " perform_full_upgrade
    if [ "$perform_full_upgrade" == "y" ]; then
        Full-Upgrade
    fi

    echo "Do you want to perform a dist-upgrade?"
    read -p "Enter y/n: " perform_dist_upgrade
    if [ "$perform_dist_upgrade" == "y" ]; then
        Dist-Upgrade
    fi
}

# Execute the main function
main
