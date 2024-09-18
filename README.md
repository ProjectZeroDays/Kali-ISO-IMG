
This scripts acts as a custom solution to impliment & automate the process of generating custom Kali Live ISO/IMG with additional options to automatically add, install, and/or configure advanced, automated, & customizable features, tools & Options that dont exist in any other Kali Linux Live/Installation ISO.

### This script also offers options to:

    • Create a custom Kali ISO
    • Select Between RootFS, Weekly,             Everything
    • Select Arch ARM/AMD64/M2 For ISO           Build  
    • Change Wallpaper of Grub Menu
    • Change Wallpaper of Kali Installer         Menu
    • Use Tools To Diagnose & Fix Boot           Issues
    • Use Partitioning Tools/Functions
    • Utilize File Recovery Tools 
    • Install ProxMox As a Stage 1 VM 
    • Generate A Custom Kali Live Iso
    • Create a .IMG To Upload to the Cloud
    • Works on MacOS/Kali/Kali WSL
    • ISO/IMG advanced features such as:       • Includes Opt To Setup encryped             persist
    • Custom Grub Menu Tools 
    • Customized Theme Opts For The Grub
    • Customized Theme Opts For Kali             Installer
    • Auto Updates 
    • Auto Upgrades 
         * All Packages 
         * All Package Managers 
         * System Apps
    • Automated Installation of Tools
    • Automated Configurations of Tools 
    • Wont Update Apps If They'll Break
    • Wont upgrade System If It'll Break
    • Options To Choose What To Install
         * Remote Desktop
         * Any Desk
         * Teamviewer
         * RealVNC 
         * RealVNC Server                           * Chrome Remote Desktop 
         * OpenSSH
         * SSH2     
         * AutoSSH
         * Django Framework
         * Flask Framework
         * Tabler Admin Panel
         * Apache Web Server
         * Simplenote
         * Snap
         * Snap-Store
         * Brave Nightly
         * Chrome Nightly
         * Edge Nightly
         * Tor Browser
         * Onion
         * sn1per 
         * Wifite3 
         * Armitage
         * Metasploit-Framework
         * Nmap
         * Ncat
         * VLC
         * WinRAR
         * 7z
         * John-The-Ripper
         * Hydra Brute Force 
         * Hashcat Hash/Salt/NTL Cracker            * Burp Suite Community Edition
         * BPKG       
         * GDEBI
         * Aptitude
         * Homebrew
         * CLIB 
         * Ruby-GEM 
         * Ruby  
         * Pearl
         * Python3
         * Pip3
         * CMAKE  
         * GCC
         * LUA5 
         * PHP
         * Apache
         * NodeJS 
         * NPM
         * NVM
         * AutoMake
         * AutoConfigure
         * C++
         * Nano
         * Git
         * GH
         * GH CoPilot
         * Chat GBT CLI
         * Advanced Gemini CLI
         * Microsoft CoPilot Pro (Bing)
         * Visual Studio Code
         * Ducky Script IDE
         * Ducky Script Encoder & Decoder
         * Shared DB Between These Apps:
              • Metasploit-Framework
              • Armitage
              • Nmap
              • Zenmap
              • Wireshark
              • Wifite3
              • Hashcat
              • John-The-Ripper
              • Hydra 
              • NCat
              • Sn1per
         * And Custom Scripts For:
              • Automated Deployement 
              • Squential Deployment 
              • Database Creation
              • Auto Scanning
              • Auto DNS Enumeration 
              • Auto Cloud Enumeration
              • Auto Proxy Detection 
              • Auto OS Fingerprinting 
              • Auto Vuln Scanning
              • Auto Exploit Scanning
              • Auto Exploit Generation 
              • Auto Exploit Checking
              • Auto Payload Handling 
              • Auto Payload Encoding
              • Auto Payload Deployment 
              • Auto Brute Force Attacks
              • Auto Scanning for Hash/Salt
              • Auto Hash/Salt Cracking  
              • Auto Pass The Hash 
              • Auto Exploitation
              • Auto Credential Harvesting
              • Auto Post Exploitation 
              • Auto Install C2 Server 
              • Auto Impliment Persistence

### Purpose 

  * The script is designed to Offer:
         - Extensive Customization
         - A Wide Range of Options
         - A Completely Automated Solution 
         - A Flexible Approach 
         - Cross-Platform Usage 
         - User-Friendly Setup & Usage

### Features

- **Generate a Custom Kali Linux ISO**:
    • Supports ARM64, AMD64, and Apple M2        Silicon Chipset architectures with         options for full setup or barebones        setup

- **Format & Prepare SD Card**:
    • detects and formats the SD card,           creating necessary partitions 
  
- **Write ISO to SD Card**:
    • Writes the downloaded ISO to the SD        card
  
- **Add Encrypted Persistence**:
    • Adds an encrypted persistence              partition to the SD card
  
- **Custom Installation Menu**:
    • Sets up a custom installation menu         with various tools and options

- **WiFi Reconnection Aliases**:
    • Adds aliases for easy switching            between monitor and managed modes          for WiFi
  
- **Cloud Settings Configuration**:
    • Configures cloud provider settings         for various platforms
  
- **Fix Armitage and Metasploit Issues**:
    • Diagnoses and fixes common issues          with Armitage and Metasploit

- **Shares Database Setup**:
    • Sets up a shared database for Nmap,        Zenmap, Armitage, and Metasploit
  
- **Automated WiFi Cracking and Scanning**:
    • Automates WiFi cracking and scanning       using tools like Wifite, Wireshark,        and Nmap

- **Change GRUB Wallpaper**:
    • Allows changing the GRUB bootloader        wallpaper
  
- **Change Installation Menu Background**:     • Allows changing the background of          the installation menu

- **Install Virtualization Tools**:            • Installs VMware, VirtualBox, &             HyperVisor

- **Install Proxmox**:
    • Installs Proxmox and sets up a Kali        Linux virtual machine
  
- **Set Up Ventoy**:
    • Sets up Ventoy on the microSD card
  
- **Create IMG File**:
    • Creates an IMG from custom Kali ISO
  
- **Update and Upgrade Package Managers**:     • Provides aliases for                       updating/upgrading various package         managers
  
- **Install Additional Tools**:
    • Offers options to install various          tools and frameworks

### Prerequisites

• A system with root permissions.
• An SD card or USB drive.
• Internet connection for downloading        necessary files.

### Usage

1. **Clone the Repository**:
    ```bash
    git clone     https://github.com/projectzerodays/kali-ISO-IMG.git
    cd Kali-ISO-IMG
    ```
    
2. **Run the Script**:
    ```bash
    sudo ./install.sh
    ```

3. **Follow the Prompts**:
      * This Script Will Guide You With:              • Downloading The Kali Linux ISO
           • Formatting a SD Card
           • Formatting a USB Device
           • Writing The ISO to an SD Card            • Adding Encrypted Persistence             • Set Up The Custom Grub Menu
           • Set Up The Custom Install Menu
      * You Will Also Have The Opt To:                • Install Additional Tools                 • Perform Additional Updates
           • Perform Additional Upgraded              • Set Additional Configurations            • Modify Various Extra Settings

### Aliases

The script adds aliases for convenience:
     * `Update`:
          • Updates All Pkg Mgrs
     * `Upgrade`:
          • Upgrades All Pkgs/Pkg Mgrs.
     * `Full-Upgrade`:
          • Runs Full-Upgrade including:
              - `sudo apt-get -y upgrade`                - `sudo apt-get -y full-                      upgrade`.
     * `Dist-Upgrade`:
          • Runs dist-upgrade including:
              - `sudo apt-get -y dist-                     upgrade`

### Metasploit Post-Exploitation Process

The script includes a process to pass hashes and salts to Hashcat using `auto_helper.py`, which utilizes the free Amazon cloud instance for cracking and emails the results.

### Customization

Feel free to customize the script further based on your specific requirements. The script is designed to be flexible and easily modifiable.

### Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

### License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Ez'ra @ Project Zero

- [Kali Linux](https://www.kali.org/)
- [Ventoy](https://www.ventoy.net/)
- [Proxmox](https://www.proxmox.com/)
- [Hashcat](https://hashcat.net/hashcat/)
- [Metasploit](https://www.metasploit.com/)
