#!/bin/bash 
#==========================================================
#          FILE: install-nghdl.sh
# 
#         USAGE: ./install-nghdl.sh --install
#                 			OR
#                ./install-nghdl.sh --uninstall
# 
#   DESCRIPTION: Installation script for Ngspice, GHDL 
#                and Verilator simulators (NGHDL)
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Fahim Khan, Rahul Paknikar, Sumanto Kar
#       MENTORS: Sumanto Kar, Varad Patil, Shanti Priya K, Aditya M
#       INTERNS: Akshay Rukade, Haripriyan R
#  ORGANIZATION: eSim, FOSSEE group at IIT Bombay
#       CREATED: Tuesday 02 December 2014 17:01
#      REVISION: Monday 23 November 2026 (Ubuntu 25.04+ fixes: LLVM <= 18, canberra)
#==========================================================

nghdl="nghdl-simulator"
ghdl="ghdl-4.1.0"
verilator="verilator-4.210"
config_dir="$HOME/.nghdl"
config_file="config.ini"
src_dir=`pwd`

# GHDL 4.1.0's configure script only accepts LLVM up to 18.1
# (newer Ubuntu releases ship LLVM 20/21/22 as the default "llvm" package)
ghdl_max_llvm=18
llvm_version=""

# Will be used to take backup of any file
sysdate="$(date)"
timestamp=`echo $sysdate|awk '{print $3"_"$2"_"$6"_"$4 }'`


# All functions goes here

error_exit() {
    echo -e "\n\nError! Kindly resolve above error(s) and try again."
    echo -e "\nAborting Installation...\n"
}


# Return 0 if apt has an installation candidate for package $1
function aptHasCandidate
{
    local candidate
    candidate=$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')
    [[ -n "$candidate" && "$candidate" != "(none)" ]]
}


# Pick the newest LLVM version (<= ghdl_max_llvm) available from apt
function selectLLVMVersion
{
    local v
    for (( v=ghdl_max_llvm; v>=10; v-- )); do
        if aptHasCandidate "llvm-$v-dev"; then
            llvm_version=$v
            return 0
        fi
    done
    return 1
}


function installDependency
{

    # Refresh package index first, so that version checks below are correct
    sudo apt-get update

    echo "Installing dependencies for $ghdl LLVM................"

    echo "Installing Make..........................................."
    sudo apt install -y make
    
    echo "Installing GNAT..........................................."
    sudo apt install -y gnat
    
    # Ubuntu 25.04+ ships LLVM 20 (or newer) as the default "llvm" package,
    # which GHDL 4.1.0 refuses ("Unhandled version llvm 20.1.2").
    # Install a versioned LLVM that GHDL supports instead.
    if ! selectLLVMVersion; then
        echo "ERROR: No LLVM version <= $ghdl_max_llvm is available from apt."
        echo "GHDL 4.1.0 cannot be built with the LLVM backend on this system."
        return 1
    fi
    echo "Installing LLVM $llvm_version (newest version supported by $ghdl)..."
    sudo apt install -y llvm-$llvm_version llvm-$llvm_version-dev

    echo "Installing Clang $llvm_version.........................................."
    sudo apt install -y clang-$llvm_version

    echo "Installing Zlib1g-dev....................................."
    sudo apt install -y zlib1g-dev
  
    # Specific dependency for canberra-gtk modules
    # libcanberra-gtk-module (GTK2) was dropped in Ubuntu 25.04;
    # install it only where it still exists
    echo "Installing Gtk Canberra modules..........................."
    sudo apt install -y libcanberra-gtk3-module
    if aptHasCandidate libcanberra-gtk-module; then
        sudo apt install -y libcanberra-gtk-module
    fi

    # Specific dependency for nvidia graphic cards
    echo "Installing graphics dependency for Ngspice source build"
    echo "Installing libxaw7........................................"
    sudo apt install -y libxaw7

    echo "Installing libxaw7-dev...................................."
    sudo apt install -y libxaw7-dev


    echo "Installing dependencies for $verilator...................."
    if [[ -n "$(which apt 2> /dev/null)" ]]
    then
    # Ubuntu
        sudo apt install -y make autoconf g++ flex bison
    elif [[ -n "$(which yum 2> /dev/null)" ]]; then
    # Ubuntu
        sudo yum install make autoconf flex bison which -y
        sudo yum groupinstall 'Development Tools'  -y
    fi

    echo "Installing dependencies for ngspice (with OSDI)..........."

    sudo apt update
    sudo apt install -y \
        build-essential \
        autoconf \
        automake \
        libtool \
        flex \
        bison \
        libreadline-dev \
        libncurses-dev \
        libxaw7 \
        libxaw7-dev \
        libx11-dev

}



function installGHDL
{   

    echo "Installing $ghdl LLVM................................."
    tar xvf $ghdl.tar.gz
    echo "$ghdl successfully extracted"
    echo "Changing directory to $ghdl installation"
    cd $ghdl/
    echo "Configuring $ghdl build as per requirements"
    chmod +x configure
    # Other configure flags can be found at - https://github.com/ghdl/ghdl/blob/master/configure
    # Use the versioned clang++ that matches the selected LLVM
    # (plain "clang++" is not installed with clang-$llvm_version)
    ./configure --with-llvm-config=/usr/bin/llvm-config-$llvm_version \
        CXX=clang++-$llvm_version
    echo "Building the install file for $ghdl LLVM"
    make -j$(nproc)
    sudo make install

    # set +e 		# Temporary disable exit on error
    # trap "" ERR # Do not trap on error of any command
    
    # echo "Removing unused part of $ghdl LLVM"
    # sudo rm -rf ../$ghdl
    
    # set -e 		# Re-enable exit on error
    # trap error_exit ERR

    echo "GHDL installed successfully"
    cd ../
    
}


function installVerilator
{   
    
    echo "Installing $verilator......................."
    tar -xvf $verilator.tar.xz
    echo "$verilator successfully extracted"
    echo "Changing directory to $verilator installation"
    cd $verilator
    echo "Configuring $verilator build as per requirements"
    chmod +x configure
    ./configure
    make -j$(nproc)
    sudo make install
    echo "Removing the unessential verilator files........"
    rm -r docs
    rm -r examples
    rm -r include
    rm -r test_regress
    rm -r bin
    ls -1 | grep -E -v 'config.status|configure.ac|Makefile.in|verilator.1|configure|Makefile|src|verilator.pc' | xargs rm -f
    #sudo rm -v -r'!("config.status"|"configure.ac"|"Makefile.in"|"verilator.1"|"configure"|"Makefile"|"src"|"verilator.pc")'

    echo "Verilator installed successfully"
    cd ../

}


function installNGHDL
{

    echo "Installing NGHDL........................................"

    # Extracting NGHDL to Home Directory
    cd $src_dir
    tar -xJf $nghdl-source.tar.xz -C $HOME
    mv $HOME/$nghdl-source $HOME/$nghdl

    echo "NGHDL extracted sucessfully to $HOME"
    # Change to nghdl directory
    cd $HOME/$nghdl
    # Make local install directory
    mkdir -p install_dir
    # Make release directory for build
    mkdir -p release
    # Change to release directory
    cd release
    echo "Configuring NGHDL..........."
    sleep 2
    
    chmod +x ../configure
    # GCC 15 (Ubuntu 25.10+) defaults to C23, where "bool" is a keyword:
    #   bool.h: error: 'bool' cannot be defined via 'typedef'
    # Build ngspice as GNU C17 (the GCC 14 default) on every release.
    ../configure CC="gcc -std=gnu17" \
        --enable-osdi \
        --enable-xspice \
        --enable-openmp \
        --disable-debug \
        --prefix=$HOME/$nghdl/install_dir \
        --exec-prefix=$HOME/$nghdl/install_dir
            
    # Adding patch to Ngspice base code
    # cp $src_dir/src/outitf.c $HOME/$nghdl/src/frontend

    make -j$(nproc)
    make install

    # Make it executable
    sudo chmod 755 $HOME/$nghdl/install_dir/bin/ngspice
    
    set +e 		# Temporary disable exit on error
    trap "" ERR # Do not trap on error of any command

    echo "Removing previously installed Ngspice (if any)"    
    sudo apt-get purge -y ngspice

    echo "NGHDL installed sucessfully"
    echo "Adding softlink for the installed Ngspice"

    # Add symlink to the path
    sudo rm /usr/bin/ngspice

    set -e 		# Re-enable exit on error
    trap error_exit ERR

    sudo ln -sf $HOME/$nghdl/install_dir/bin/ngspice /usr/bin/ngspice
    echo "Added softlink for Ngspice....."

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

    echo "[NGHDL]" >> $config_dir/$config_file
    echo "NGHDL_HOME = $HOME/$nghdl" >> $config_dir/$config_file
    echo "DIGITAL_MODEL = %(NGHDL_HOME)s/src/xspice/icm" >> $config_dir/$config_file
    echo "RELEASE = %(NGHDL_HOME)s/release" >> $config_dir/$config_file
    echo "[SRC]" >> $config_dir/$config_file
    echo "SRC_HOME = $src_dir" >> $config_dir/$config_file
    echo "LICENSE = %(SRC_HOME)s/LICENSE" >> $config_dir/$config_file
    echo "[BUILD]" >> $config_dir/$config_file
    echo "LLVM_VERSION = $llvm_version" >> $config_dir/$config_file

}


function createSoftLink
{
    # Make it executable
    sudo chmod 755 $src_dir/src/ngspice_ghdl.py

    # Creating softlink
    cd /usr/local/bin
    if [[ -L nghdl ]];then
        echo "Symlink was already present"
        sudo unlink nghdl
    fi
    
    sudo ln -sf $src_dir/src/ngspice_ghdl.py nghdl
    echo "Added softlink for NGHDL....."

    cd $pwd

}


#####################################################################
#       Script start from here                                     #
#####################################################################

### Checking if file is passsed as argument to script

if [ "$#" -eq 1 ];then
    option=$1
else
    echo "USAGE : "
    echo "./install-nghdl.sh --install"
    exit 1;
fi

## Checking flags
if [ $option == "--install" ];then
    
    set -e  # Set exit option immediately on error
    set -E  # inherit ERR trap by shell functions

    # Trap on function error_exit before exiting on error
    trap error_exit ERR
    
    #Calling functions
    installDependency
    if [ $? -ne 0 ];then
        echo -e "\n\n\nERROR: Unable to install required packages. Please check your internet connection.\n\n"
        exit 0
    fi
   
    installGHDL
    installVerilator
    installNGHDL
    createConfigFile
    createSoftLink

elif [ $option == "--uninstall" ];then
    # Read the LLVM version used at install time (needed for purge below)
    if [ -f $config_dir/$config_file ]; then
        llvm_version=$(awk -F' = ' '/^LLVM_VERSION/ {print $2}' $config_dir/$config_file)
    fi

    sudo rm -rf $HOME/$nghdl $HOME/.nghdl /usr/share/kicad/library/eSim_Nghdl.lib /usr/local/bin/nghdl /usr/bin/ngspice

    echo "Removing GHDL......................"
    cd $ghdl/
    sudo make uninstall
    cd ../
    sudo rm -rf $ghdl/
    # sudo rm -rf /usr/local/bin/ghdl /usr/local/bin/ghdl1-llvm /usr/local/lib/ghdl /usr/local/lib/libghdlvpi.so /usr/local/include/vpi_user.h

    echo "Removing Verilator................."
    cd $verilator/
    sudo make uninstall
    cd ../
    sudo rm -rf $verilator/

    echo "Removing libxaw7-dev..............."
    sudo apt purge -y libxaw7-dev
    if [ -n "$llvm_version" ]; then
        echo "Removing LLVM $llvm_version......................"
        sudo apt-get purge -y llvm-${llvm_version} llvm-${llvm_version}-dev clang-${llvm_version}
    fi
    echo "Removing GNAT......................"
    sudo apt purge -y gnat
else 
    echo "Please select the proper operation."
    echo "--install"
    echo "--uninstall"
fi
