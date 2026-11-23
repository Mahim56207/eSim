#!/bin/bash
#=============================================================================
#          FILE: install-eSim.sh
#
#         USAGE: ./install-eSim.sh --install
#                            OR
#                ./install-eSim.sh --uninstall
#
#   DESCRIPTION: Installation script for eSim EDA Suite.
#                Detects the Ubuntu release and runs the matching script
#                from install-eSim-scripts/.
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: The previous revision of this file was a broken merge of the
#                version-dispatcher and the old monolithic installer
#                ("syntax error near unexpected token `}'" at line 70).
#       AUTHORS: Fahim Khan, Rahul Paknikar, Saurabh Bansode,
#                Sumanto Kar, Partha Singha Roy, Jayanth Tatineni,
#                Anshul Verma, Shiva Krishna Sangati, Harsha Narayana P
#  ORGANIZATION: eSim Team, FOSSEE, IIT Bombay
#       CREATED: Wednesday 15 July 2015 15:26
#      REVISION: Monday 23 November 2026 (Ubuntu 25.04 / 25.10 / 26.04)
#=============================================================================

# Directory that contains this script (the eSim-<version> folder)
ESIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$ESIM_DIR/install-eSim-scripts"

# Newest Ubuntu release this installer has been tested on
LATEST_TESTED="26.04"

# Function to detect Ubuntu version and full version string
get_ubuntu_version() {
    if [[ ! -r /etc/os-release ]]; then
        echo "Cannot read /etc/os-release. Is this Ubuntu?"
        exit 1
    fi

    VERSION_ID=$(. /etc/os-release && echo "$VERSION_ID")
    DISTRO_ID=$(. /etc/os-release && echo "$ID")

    # Point releases (22.04.4) carry 3 numbers, non-LTS releases (25.04) only 2.
    # The old pattern '\d+\.\d+\.\d+' printed an empty version on 25.04.
    FULL_VERSION=$(lsb_release -ds 2>/dev/null | grep -oP '\d+\.\d+(\.\d+)?' | head -n 1)
    FULL_VERSION=${FULL_VERSION:-$VERSION_ID}

    echo "Detected Ubuntu Version: $FULL_VERSION"

    if [[ "$DISTRO_ID" != "ubuntu" ]]; then
        echo "WARNING: This installer is written for Ubuntu (detected: $DISTRO_ID)."
    fi
}

# Return 0 if version $1 >= version $2 (e.g. 25.10 >= 25.04)
version_ge() {
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2" ]]
}

# Function to choose and run the appropriate script
run_version_script() {

    # Decide script based on full version
    case $VERSION_ID in
        "22.04")
            if [[ "$FULL_VERSION" == "22.04.4" ]]; then
                SCRIPT="$SCRIPT_DIR/install-eSim-22.04.sh"
            else
                SCRIPT="$SCRIPT_DIR/install-eSim-23.04.sh"
            fi
            ;;
        "23.04")
            SCRIPT="$SCRIPT_DIR/install-eSim-23.04.sh"
            ;;
        "24.04")
            SCRIPT="$SCRIPT_DIR/install-eSim-24.04.sh"
            ;;
        "25.04"|"25.10"|"26.04")
            # 25.10 and 26.04 use the same package set as 25.04
            # (GCC 14/15, LLVM >= 20, Python 3.13+)
            SCRIPT="$SCRIPT_DIR/install-eSim-25.04.sh"
            ;;
        *)
            if version_ge "$VERSION_ID" "25.04"; then
                echo "WARNING: Ubuntu $VERSION_ID is newer than the newest tested release ($LATEST_TESTED)."
                echo "WARNING: Trying the Ubuntu 25.04+ installer."
                SCRIPT="$SCRIPT_DIR/install-eSim-25.04.sh"
            else
                echo "Unsupported Ubuntu version: $VERSION_ID ($FULL_VERSION)"
                exit 1
            fi
            ;;
    esac

    # Run the script if found
    if [[ -f "$SCRIPT" ]]; then
        echo "Running script: $SCRIPT $ARGUMENT"
        # Version scripts use $(pwd) as eSim home, so run them from here
        cd "$ESIM_DIR" || exit 1
        bash "$SCRIPT" "$ARGUMENT"
        exit $?
    else
        echo "Installation script not found: $SCRIPT"
        exit 1
    fi
}

# --- Main Execution Starts Here ---

# Validate argument
if [[ $# -ne 1 ]]; then
    echo "USAGE : "
    echo "./install-eSim.sh --install"
    echo "./install-eSim.sh --uninstall"
    exit 1
fi

ARGUMENT=$1
if [[ "$ARGUMENT" != "--install" && "$ARGUMENT" != "--uninstall" ]]; then
    echo "Invalid argument: $ARGUMENT"
    echo "Usage: $0 --install | --uninstall"
    exit 1
fi

get_ubuntu_version
run_version_script
