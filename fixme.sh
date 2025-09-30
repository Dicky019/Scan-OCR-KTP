#!/bin/bash

#set -Eeo pipefail #set -Eeox pipefail

# This script should be run regularly to keep development environment in sync for all team members
# Run this after cloning the project or when dependencies change

# Get directory paths
scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
git_root="$(cd "${scripts_dir}" && pwd)"

echo "--- ---  --- ---  --- --- --- ---  --- ---  --- ---"
echo "scripts_dir: ${scripts_dir}"
echo "git_root: ${git_root}"
echo "--- ---  --- ---  --- --- --- ---  --- ---  --- ---"

# Update fixme stats
cksum "${git_root}/fixme.sh" | awk -F" " '{print $1}' > ~/.fixme.cksum

# --- ---  --- ---  --- ---  XCODE TOOLS INSTALL --- ---  --- ---  --- ---  --- ---

function enable_better_simulator_settings {
    echo "Enabling 'show single touches' for simulator"
    defaults write com.apple.iphonesimulator ShowSingleTouches 1
}

function cleanup_xcode_tools_install {
    echo "*** Failed to install xcode tools ***"
    echo "You have to install xcode command line tools first"
    echo "Please re-run the script once xcode tools installation is done"
    exit -1
}

function install_xcode_tools {
    trap cleanup_xcode_tools_install EXIT

    echo "* install xcode command line tool"
    xcode-select --install
    if [ $? -ne 0 ]; then
        exit -1
    fi
    echo "    ready to use xcode tools"
}

# --- ---  --- ---  --- ---  BREW INSTALL --- ---  --- ---  --- ---  --- ---

function cleanup_brew_install {
    echo "*** Failed to install brew ***"
    echo "Please re-run the script once brew installation is done"
    exit -1
}

function install_brew {
    trap cleanup_brew_install EXIT

    echo "fixing brew..."
    echo "    install brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew doctor
    if [ $? -ne 0 ]; then
        exit -1
    fi
    echo "    ready to Brew"
}

# --- ---  --- ---  --- ---  VALIDATE XCODE TOOLS --- ---  --- ---  --- ---  --- ---

echo "* checking xcode tools..."
xcode-select -v >> /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_xcode_tools
else
   echo "    Xcode tools already installed"
fi

if [[ $DISABLE_BETTER_SIMULATOR_SETTINGS != "true" ]]
then
    enable_better_simulator_settings
fi

echo "* set concurrent jobs for Xcode"
if [[ -z "${FL_CONCURRENT_JOBS}" ]]; then
  defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks `sysctl -n hw.physicalcpu`
else
  defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks $FL_CONCURRENT_JOBS
fi

# --- ---  --- ---  --- ---  VALIDATE BREW --- ---  --- ---  --- ---  --- ---

# Fix brew if required
echo "* checking brew..."
brew --version >> /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_brew
else
   echo "    Brew already installed"
fi

# --- ---  --- ---  --- ---  XCODEGEN INSTALL --- ---  --- ---  --- ---  --- ---

function cleanup_xcodegen_install {
    echo "*** Failed to install xcodegen ***"
    echo "Please re-run the script once xcodegen installation is done"
    exit -1
}

function install_xcodegen {
    trap cleanup_xcodegen_install EXIT

    echo "fixing xcodegen..."
    echo "    install xcodegen"
    brew install xcodegen
    if [ $? -ne 0 ]; then
        exit -1
    fi
    echo "    ready to use xcodegen"
}

# --- ---  --- ---  --- ---  VALIDATE XCODEGEN --- ---  --- ---  --- ---  --- ---

# Check xcodegen installation
echo "* checking xcodegen..."
xcodegen --version >> /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_xcodegen
else
   echo "    XCodegen already installed"
fi

# --- ---  --- ---  --- ---  COCOAPODS INSTALL --- ---  --- ---  --- ---  --- ---

function cleanup_cocoapods_install {
    echo "*** Failed to install cocoapods ***"
    echo "Please re-run the script once cocoapods installation is done"
    exit -1
}

function install_cocoapods {
    trap cleanup_cocoapods_install EXIT

    echo "fixing cocoapods..."
    echo "    install cocoapods"
    sudo gem install cocoapods
    if [ $? -ne 0 ]; then
        exit -1
    fi
    echo "    ready to use cocoapods"
}

# --- ---  --- ---  --- ---  VALIDATE COCOAPODS --- ---  --- ---  --- ---  --- ---

# Check cocoapods installation
echo "* checking cocoapods..."
pod --version >> /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_cocoapods
else
   echo "    CocoaPods already installed"
fi

# --- ---  --- ---  --- ---  UPDATE BREW --- ---  --- ---  --- ---  --- ---

# Update Homebrew to check for updates
echo "* updating brew..."
brew update

# --- ---  --- ---  --- ---  GENERATE PROJECT --- ---  --- ---  --- ---  --- ---

echo ""
echo "=========================================="
echo "Generating Xcode project from project.yml"
echo "=========================================="
cd "$git_root"
xcodegen generate

if [ $? -ne 0 ]; then
    echo "*** Failed to generate Xcode project ***"
    echo "Check project.yml for errors"
    exit -1
fi

echo "    Xcode project generated successfully"

# --- ---  --- ---  --- ---  INSTALL PODS --- ---  --- ---  --- ---  --- ---

echo ""
echo "========================================"
echo "Installing CocoaPods dependencies"
echo "========================================"
pod install --no-repo-update --verbose

if [ $? -ne 0 ]; then
    echo "*** Failed to install pods ***"
    echo "Check Podfile for errors"
    exit -1
fi

echo ""
echo "=========================================="
echo "Done! All set."
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Open 'Scan OCR KTP.xcworkspace' (not .xcodeproj)"
echo "2. Select your target device/simulator"
echo "3. Build and run (⌘R)"
echo ""
echo "Note: MLKit doesn't support iOS Simulator."
echo "      Build for physical device to test dual OCR."
echo ""