#!/bin/bash 
#=============================================================================
#          FILE: install-eSim.sh
# 
#         USAGE: ./install-eSim.sh --install 
#                            OR
#                ./install-eSim.sh --uninstall
#                
#   DESCRIPTION: Installation script for eSim EDA Suite
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#       AUTHORS: Fahim Khan, Rahul Paknikar, Saurabh Bansode,
#                Sumanto Kar, Partha Singha Roy, Harsha Narayana P, 
#                Jayanth Tatineni, Anshul Verma
#  ORGANIZATION: eSim Team, FOSSEE, IIT Bombay
#       CREATED: Wednesday 15 July 2015 15:26
#      REVISION: Monday 23 November 2026 (Ubuntu 25.04 / 25.10 / 26.04 fixes)
#=============================================================================

# All variables goes here
config_dir="$HOME/.esim"
config_file="config.ini"
eSim_Home=`pwd`
ngspiceFlag=0

# Retry downloads: Launchpad PPAs often answer "503 Service Unavailable"
apt_opts="-o Acquire::Retries=5"

# Ubuntu release information (e.g. 25.04 / plucky)
ubuntu_version=$(lsb_release -rs)
ubuntu_codename=$(lsb_release -cs)

# Desktop folder can be localised (e.g. "Schreibtisch") or missing
desktop_dir=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")

## All Functions goes here

error_exit()
{

    echo -e "\n\nError! Kindly resolve above error(s) and try again."
    echo -e "\nAborting Installation...\n"

}


function createConfigFile
{

    # Creating config.ini file and adding configuration information
    # Check if config file is present
    if [ -d $config_dir ];then
        rm $config_dir/$config_file && touch $config_dir/$config_file
    else
        mkdir $config_dir && touch $config_dir/$config_file
    fi
    
    echo "[eSim]" >> $config_dir/$config_file
    echo "eSim_HOME = $eSim_Home" >> $config_dir/$config_file
    echo "LICENSE = %(eSim_HOME)s/LICENSE" >> $config_dir/$config_file
    echo "KicadLib = %(eSim_HOME)s/library/kicadLibrary.tar.xz" >> $config_dir/$config_file
    echo "IMAGES = %(eSim_HOME)s/images" >> $config_dir/$config_file
    echo "VERSION = %(eSim_HOME)s/VERSION" >> $config_dir/$config_file
    echo "MODELICA_MAP_JSON = %(eSim_HOME)s/library/ngspicetoModelica/Mapping.json" >> $config_dir/$config_file
   
}


function installNghdl
{

    echo "Installing NGHDL..........................."
    unzip -o nghdl.zip

    # nghdl.zip inside eSim-2.5 still has the old install-nghdl.sh, which
    # fails on Ubuntu 25.04+ (libcanberra-gtk-module, LLVM 20). Use the
    # fixed copy shipped next to this script, if present.
    patched_nghdl="$eSim_Home/install-eSim-scripts/nghdl/install-nghdl.sh"
    if [ -f "$patched_nghdl" ]; then
        echo "Using updated NGHDL installer: $patched_nghdl"
        cp -v "$patched_nghdl" nghdl/install-nghdl.sh
    fi

    cd nghdl/
    chmod +x install-nghdl.sh

    # Do not trap on error of any command. Let NGHDL script handle its own errors.
    trap "" ERR

    ./install-nghdl.sh --install       # Install NGHDL
        
    # Set trap again to error_exit function to exit on errors
    trap error_exit ERR

    ngspiceFlag=1
    cd ../

}


function installSky130Pdk
{

    echo "Installing SKY130 PDK......................"
    
    # Extract SKY130 PDK
    tar -xJf library/sky130_fd_pr.tar.xz

    # Remove any previous sky130-fd-pdr instance, if any
    sudo rm -rf /usr/share/local/sky130_fd_pr

    # Copy SKY130 library
    echo "Copying SKY130 PDK........................."

    sudo mkdir -p /usr/share/local/
    sudo mv sky130_fd_pr /usr/share/local/

    # Change ownership from root to the user
    sudo chown -R $USER:$USER /usr/share/local/sky130_fd_pr/

}


# Return 0 if the KiCad PPA $1 publishes packages for this Ubuntu release.
# Launchpad often answers "503 Service Unavailable", so retry and only treat
# a definite "404 Not Found" as "this release is not published".
function ppaHasRelease
{
    local url="https://ppa.launchpadcontent.net/$1/ubuntu/dists/$ubuntu_codename/Release"
    local attempt code
    for attempt in 1 2 3 4 5; do
        code=$(wget -S --spider -q --tries=1 --timeout=20 "$url" 2>&1 | awk '/HTTP\// {c=$2} END {print c}')
        case "$code" in
            200) return 0 ;;
            404) return 1 ;;
        esac
        sleep 3
    done
    # No definite answer (offline/proxy): do not risk adding a broken source
    echo "WARNING: Could not reach Launchpad to check $1 (last HTTP code: ${code:-none})."
    return 1
}


# Print installed KiCad major version (e.g. "8"), or nothing
function installedKicadMajor
{
    dpkg-query -W -f='${Version}' kicad 2>/dev/null | sed -E 's/^[0-9]+://' | cut -d'.' -f1
}


function installKicad
{
    echo "Installing KiCad..........................."
    echo "Ubuntu $ubuntu_version ($ubuntu_codename) detected."

    kicadppa="kicad/kicad-8.0-releases"
    kicad_major=$(installedKicadMajor)

    if [[ -n "$kicad_major" ]]; then
        if [[ "$kicad_major" == "8" ]]; then
            # Do NOT "exit 0" here: that silently skipped every remaining
            # step (KiCad library, NGHDL, SKY130, desktop shortcut)
            echo "KiCad 8 is already installed. Skipping KiCad installation."
            return 0
        fi
        echo "A different version of KiCad ($kicad_major) is installed."
        read -p "Do you want to remove it and install KiCad 8.0? (yes/no): " response
        if [[ "$response" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
            echo "Removing KiCad $kicad_major..."
            sudo apt-get remove --purge -y kicad kicad-footprints kicad-libraries kicad-symbols kicad-templates
            sudo apt-get autoremove -y
        else
            echo "Keeping KiCad $kicad_major. eSim is tested with KiCad 8, some features may not work."
            return 0
        fi
    fi

    # Which KiCad does the Ubuntu archive itself offer? (25.04: 8.0.8, 25.10+: 9.x)
    archive_major=$(apt-cache policy kicad 2>/dev/null | awk '/Candidate:/ {print $2}' \
                    | sed -E 's/^[0-9]+://' | cut -d'.' -f1)

    if [[ "$archive_major" == "8" ]]; then
        # Ubuntu 25.04 ships KiCad 8.0.8 in universe. Do NOT add the PPA here:
        # its plucky build (8.0.9-0~ubuntu25.04.1) depends on libgit2-1.8,
        # which does not exist in 25.04 (only libgit2-1.9), so apt fails with
        # "kicad : Depends: libgit2-1.8 (>= 1.8.0) but it is not installable".
        echo "Installing KiCad 8 from the Ubuntu archive (no PPA needed)."
        # A PPA left behind by an earlier installer run would win again
        if grep -rqs "kicad-8.0-releases" /etc/apt/sources.list /etc/apt/sources.list.d/; then
            echo "Removing previously added $kicadppa (broken on $ubuntu_codename)."
            sudo add-apt-repository -r -y "ppa:$kicadppa"
            sudo apt-get $apt_opts update
        fi
    elif ppaHasRelease "$kicadppa"; then
        # Add the PPA only if it is not already present
        # (add-apt-repository writes deb822 *.sources files on Ubuntu 24.04+)
        if ! grep -rqs "kicad-8.0-releases" /etc/apt/sources.list /etc/apt/sources.list.d/; then
            echo "Adding KiCad PPA to local apt repository: $kicadppa"
            sudo add-apt-repository -y -n "ppa:$kicadppa"
        else
            echo "KiCad PPA is already present in sources."
        fi
        # If the PPA cannot be used after all, remove it again instead of
        # aborting with "does not have a Release file"
        if ! sudo apt-get $apt_opts update; then
            echo "WARNING: $kicadppa could not be used, removing it again."
            sudo add-apt-repository -r -y -n "ppa:$kicadppa"
            sudo apt-get $apt_opts update
        fi
    else
        # e.g. Ubuntu 25.10 / 26.04: the KiCad 8 PPA has no packages for these
        echo "WARNING: $kicadppa has no packages for Ubuntu $ubuntu_codename."
        echo "WARNING: Installing KiCad $archive_major from the Ubuntu archive instead."
    fi

    # Install KiCad and its libraries together WITHOUT pinning
    # "kicad=8.0.8+dfsg-1": with the PPA added, that pin gave kicad 8.0.8 from
    # the archive but footprints/symbols/templates 8.0.9 from the PPA.
    # apt now picks one consistent version for all five packages.
    sudo apt-get $apt_opts install -y --no-install-recommends \
        kicad kicad-footprints kicad-libraries kicad-symbols kicad-templates

    kicad_major=$(installedKicadMajor)
    if [[ "$kicad_major" != "8" ]]; then
        echo "WARNING: KiCad $kicad_major installed (eSim 2.5 is tested with KiCad 8)."
    fi

    echo "KiCad installation completed successfully!"
}


function installDependency
{

    set +e      # Temporary disable exit on error
    trap "" ERR # Do not trap on error of any command

    # Update apt repository
    echo "Updating apt index files..................."
    sudo apt-get $apt_opts update
    
    set -e      # Re-enable exit on error
    trap error_exit ERR
    
    echo "Instaling virtualenv......................."
    sudo apt install -y python3-virtualenv
   
    echo "Creating virtual environment to isolate packages "
    virtualenv $config_dir/env
    
    echo "Starting the virtual env..................."
    source $config_dir/env/bin/activate

    echo "Upgrading Pip.............................."
    pip install --upgrade pip
    
    echo "Installing Xterm..........................."
    sudo apt-get install -y xterm
    
    echo "Installing Psutil.........................."
    sudo apt-get install -y python3-psutil
    
    echo "Installing PyQt5..........................."
    sudo apt-get install -y python3-pyqt5

    echo "Installing Matplotlib......................"
    sudo apt-get install -y python3-matplotlib

    echo "Installing Setuptools..................."
    sudo apt-get install -y python3-setuptools

    # Install NgVeri Depedencies
    echo "Installing Pip3............................"
    sudo apt install -y python3-pip

    echo "Installing Watchdog........................"
    pip3 install watchdog

    echo "Installing Hdlparse........................"
    pip3 install --upgrade https://github.com/hdl/pyhdlparser/tarball/master

    echo "Installing Makerchip......................."
    pip3 install makerchip-app

    echo "Installing SandPiper Saas.................."
    pip3 install sandpiper-saas

   
    echo "Installing Hdlparse......................"
    pip3 install hdlparse

    echo "Installing matplotlib................"
    pip3 install matplotlib

    echo "Installing PyQt5............."
    pip3 install PyQt5  
}


function copyKicadLibrary
{

    #Extract custom KiCad Library
    tar -xJf library/kicadLibrary.tar.xz

    # KiCad reads its symbol table from ~/.config/kicad/<major>.0
    # (it was hard-coded to 6.0, which KiCad 8 does not read)
    kicad_major=$(installedKicadMajor)
    kicad_major=${kicad_major:-8}
    kicad_config="$HOME/.config/kicad/$kicad_major.0"

    if [ -d "$kicad_config" ];then
        echo "kicad config folder already exists"
    else 
        echo "$kicad_config does not exist, creating it"
        mkdir -p "$kicad_config"
    fi

    # Copy symbol table for eSim custom symbols 
    cp kicadLibrary/template/sym-lib-table "$kicad_config/"
    echo "symbol table copied in the directory $kicad_config"

    # Copy KiCad symbols made for eSim
    sudo mkdir -p /usr/share/kicad/symbols
    sudo cp -r kicadLibrary/eSim-symbols/* /usr/share/kicad/symbols/

    set +e      # Temporary disable exit on error
    trap "" ERR # Do not trap on error of any command
    
    # Remove extracted KiCad Library - not needed anymore
    rm -rf kicadLibrary

    set -e      # Re-enable exit on error
    trap error_exit ERR

    #Change ownership from Root to the User
    sudo chown -R $USER:$USER /usr/share/kicad/symbols/

}


function createDesktopStartScript
{    

    # Generating new esim-start.sh
    echo '#!/bin/bash' > esim-start.sh
    echo "cd $eSim_Home/src/frontEnd" >> esim-start.sh
    echo "source $config_dir/env/bin/activate" >> esim-start.sh
    echo "python3 Application.py" >> esim-start.sh

    # Make it executable
    sudo chmod 755 esim-start.sh
    # Copy esim start script
    sudo cp -vp esim-start.sh /usr/bin/esim
    # Remove local copy of esim start script
    rm esim-start.sh

    # Generating esim.desktop file
    echo "[Desktop Entry]" > esim.desktop
    echo "Version=1.0" >> esim.desktop
    echo "Name=eSim" >> esim.desktop
    echo "Comment=EDA Tool" >> esim.desktop
    echo "GenericName=eSim" >> esim.desktop
    echo "Keywords=eda-tools" >> esim.desktop
    echo "Exec=esim %u" >> esim.desktop
    echo "Terminal=true" >> esim.desktop
    echo "X-MultipleArgs=false" >> esim.desktop
    echo "Type=Application" >> esim.desktop
    getIcon="$config_dir/logo.png"
    echo "Icon=$getIcon" >> esim.desktop
    echo "Categories=Development;" >> esim.desktop
    echo "MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;" >> esim.desktop
    echo "StartupNotify=true" >> esim.desktop

    # Make esim.desktop file executable
    sudo chmod 755 esim.desktop
    # Copy desktop icon file to share applications
    sudo cp -vp esim.desktop /usr/share/applications/
    # Copy desktop icon file to Desktop (folder name may be localised)
    mkdir -p "$desktop_dir"
    cp -vp esim.desktop "$desktop_dir/"

    set +e      # Temporary disable exit on error
    trap "" ERR # Do not trap on error of any command

    # Make esim.desktop file as trusted application
    gio set "$desktop_dir/esim.desktop" "metadata::trusted" true
    # Set Permission and Execution bit
    chmod a+x "$desktop_dir/esim.desktop"

    # Remove local copy of esim.desktop file
    rm esim.desktop

    set -e      # Re-enable exit on error
    trap error_exit ERR

    # Copying logo.png to .esim directory to access as icon
    cp -vp images/logo.png $config_dir

}


####################################################################
#                   MAIN START FROM HERE                           #
####################################################################

### Checking if file is passsed as argument to script

if [ "$#" -eq 1 ];then
    option=$1
else
    echo "USAGE : "
    echo "./install-eSim.sh --install"
    echo "./install-eSim.sh --uninstall"
    exit 1;
fi

## Checking flags

if [ $option == "--install" ];then

    set -e  # Set exit option immediately on error
    set -E  # inherit ERR trap by shell functions

    # Trap on function error_exit before exiting on error
    trap error_exit ERR


    echo "Enter proxy details if you are connected to internet thorugh proxy"
    
    echo -n "Is your internet connection behind proxy? (y/n): "
    read getProxy
    if [ $getProxy == "y" -o $getProxy == "Y" ];then
        echo -n 'Proxy Hostname :'
        read proxyHostname

        echo -n 'Proxy Port :'
        read proxyPort

        echo -n username@$proxyHostname:$proxyPort :
        read username

        echo -n 'Password :'
        read -s passwd

        unset http_proxy
        unset https_proxy
        unset HTTP_PROXY
        unset HTTPS_PROXY
        unset ftp_proxy
        unset FTP_PROXY

        export http_proxy=http://$username:$passwd@$proxyHostname:$proxyPort
        export https_proxy=http://$username:$passwd@$proxyHostname:$proxyPort
        export https_proxy=http://$username:$passwd@$proxyHostname:$proxyPort
        export HTTP_PROXY=http://$username:$passwd@$proxyHostname:$proxyPort
        export HTTPS_PROXY=http://$username:$passwd@$proxyHostname:$proxyPort
        export ftp_proxy=http://$username:$passwd@$proxyHostname:$proxyPort
        export FTP_PROXY=http://$username:$passwd@$proxyHostname:$proxyPort

        echo "Install with proxy"

    elif [ $getProxy == "n" -o $getProxy == "N" ];then
        echo "Install without proxy"
    
    else
        echo "Please select the right option"
        exit 0    
    fi

    # Calling functions
    createConfigFile
    installDependency
    installKicad
    copyKicadLibrary
    installNghdl
    installSky130Pdk
    createDesktopStartScript

    if [ $? -ne 0 ];then
        echo -e "\n\n\nERROR: Unable to install required packages. Please check your internet connection.\n\n"
        exit 0
    fi

    echo "-----------------eSim Installed Successfully-----------------"
    echo "Type \"esim\" in Terminal to launch it"
    echo "or double click on \"eSim\" icon placed on Desktop"


elif [ $option == "--uninstall" ];then
    echo -n "Are you sure? It will remove eSim completely including KiCad, Makerchip, NGHDL and SKY130 PDK along with their models and libraries (y/n):"
    read getConfirmation
    if [ $getConfirmation == "y" -o $getConfirmation == "Y" ];then
        echo "Removing eSim............................"
        sudo rm -rf $HOME/.esim "$desktop_dir/esim.desktop" /usr/bin/esim /usr/share/applications/esim.desktop
        echo "Removing KiCad..........................."
        sudo apt purge -y kicad kicad-footprints kicad-libraries kicad-symbols kicad-templates
        sudo rm -rf /usr/share/kicad
        sudo rm -f /etc/apt/sources.list.d/kicad*
        rm -rf $HOME/.config/kicad/8.0/sym-lib-table $HOME/.config/kicad/6.0

        echo "Removing Virtual env......................."
        sudo rm -r $config_dir/env

        echo "Removing SKY130 PDK......................"
        sudo rm -R /usr/share/local/sky130_fd_pr

        echo "Removing NGHDL..........................."
        rm -rf library/modelParamXML/Nghdl/*
        rm -rf library/modelParamXML/Ngveri/*
        cd nghdl/
        if [ $? -eq 0 ];then
        	chmod +x install-nghdl.sh
    	    ./install-nghdl.sh --uninstall
    	    cd ../
    	    rm -rf nghdl
            if [ $? -eq 0 ];then
                echo -e "----------------eSim Uninstalled Successfully----------------"
            else
                echo -e "\nError while removing some files/directories in \"nghdl\". Please remove it manually"
            fi
        else
            echo -e "\nCannot find \"nghdl\" directory. Please remove it manually"
        fi
    elif [ $getConfirmation == "n" -o $getConfirmation == "N" ];then
        exit 0
    else 
        echo "Please select the right option."
        exit 0
    fi

else 
    echo "Please select the proper operation."
    echo "--install"
    echo "--uninstall"
fi
