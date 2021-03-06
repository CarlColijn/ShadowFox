#!/usr/bin/env bash

### ShadowFox updater for Mac
## author: @overdodactyl
## version: 1.4

userChrome="https://raw.githubusercontent.com/overdodactyl/ShadowFox/master/userChrome.css"
userContent="https://raw.githubusercontent.com/overdodactyl/ShadowFox/master/userContent.css"
uuid_finder="https://raw.githubusercontent.com/overdodactyl/ShadowFox/master/scripts/internal_UUID_finder.sh"
updater="https://raw.githubusercontent.com/overdodactyl/ShadowFox/master/scripts/ShadowFox_updater_mac.sh"

profilePath="$HOME/Library/Application Support/Firefox/Profiles"

currdir=$(pwd)

## get the full path of this script (readlink for Linux, greadlink for Mac with coreutils installed)
sfp=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)

## fallback for Macs without coreutils - may cause problems if symbolic links are encountered
if [ -z "$sfp" ]; then sfp=${BASH_SOURCE[0]}; fi

## check to see if file is already in a profile directory
if [[ $sfp == "$profilePath"* ]]; then
  ## change directory to the Firefox profile directory
  cd "$(dirname "${sfp}")"
else
  ## if only one profile exists, go to it
  if [ $(find "$profilePath"/* -maxdepth 0 -type d | wc -l) -eq 1 ]; then
    profileDirectory=$(echo "$profilePath"/*)

    cd "${profileDirectory}"

  ## if there are multiple directories, list them and let user choose
  else
    for d in "$profilePath"/* ; do
      name=$(echo $d |  sed 's/.*\.//')
      echo $name
    done
    read -p "What profile would you like to update ShadowFox in? " -r
    echo ""

    profileName=$REPLY
    profileID=$(ls "$profilePath" | grep $profileName | sed -n 's/\([[:alnum:]]*\).*/\1/p')

    cd "${profilePath}/${profileID}.${profileName}"
  fi
fi

## Check if there's a newer version of the updater script available
online_version="$(curl -s ${updater} | sed -n '5 s/.*[[:blank:]]\([[:digit:]]*\.[[:digit:]]*\)/\1/p')"
echo $online_version
path_to_script="$(dirname "${sfp}")/ShadowFox_updater_mac.sh"
current_version="$(sed -n '5 s/.*[[:blank:]]\([[:digit:]]*\.[[:digit:]]*\)/\1/p' "$path_to_script")"
echo $current_version

if (( $(echo "$online_version > $current_version" | bc -l) )); then
  echo -e "There is a new updater script available online.  It will replace this one and be executed.\n"
  mv ShadowFox_updater_mac.sh old_updater.sh
  curl -O ${updater} && echo -e "\nThe latest updater script has been downloaded\n"
  # make new file executable
  chmod +x ShadowFox_updater_mac.sh

  # execute new updater script
  ./ShadowFox_updater_mac.sh

  # exit script
  exit 1
fi

echo -e "Updating userContent.css and userChrome.css for Firefox profile:\n$(pwd)\n"

if [ -e chrome/userContent.css ]; then
  echo "Your current userContent.css file for this profile will be backed up and the latest ShadowFox version from github will take its place."
else
  echo -e "A userContent.css file does not exist in this profile. If you continue, the latest ShadowFox version from github will be downloaded."
fi

if [ -e chrome/userChrome.css ]; then
  echo -e "Your current userChrome.css file for this profile will be backed up and the latest ShadowFox version from github will take its place.\n"
else
  echo -e "A userChrome.css file does not exist in this profile. If you continue, the latest ShadowFox version from github will be downloaded.\n"
fi

read -p "Continue Y/N? " -n 1 -r
echo -e "\n\n"

if [[ $REPLY =~ ^[Yy]$ ]]; then

  ## Make chrome directory if it doesn't exist
  mkdir -p chrome;

  ## Move to chrome directory
  cd chrome;

  ## Make ShadowFox_customization directory if it doesn't exist
  mkdir -p ShadowFox_customization;

  ## Create all customization files if they don't exist
  touch ./ShadowFox_customization/colorOverrides.css
  touch ./ShadowFox_customization/internal_UUIDs.txt
  touch ./ShadowFox_customization/userContent_customization.css
  touch ./ShadowFox_customization/userChrome_customization.css

  if [ -e userChrome.css ]; then
    # backup current userChrome.css file
    mkdir -p chrome_backups
    bakfile="userChrome.backup.$(date +"%Y-%m-%d_%H%M%S")"
    mv userChrome.css "chrome_backups/${bakfile}" && echo "Your previous userChrome.css file was backed up: ${bakfile}"
  fi
  if [ -e userContent.css ]; then
    # backup current userChrome.css file
    mkdir -p chrome_backups
    bakfile="userContent.backup.$(date +"%Y-%m-%d_%H%M%S")"
    mv userContent.css "chrome_backups/${bakfile}" && echo "Your previous userContent.css file was backed up: ${bakfile}"
  fi

  # download latest ShadowFox userChrome.css
  echo "Downloading latest ShadowFox userChrome.css file..."
  curl -O ${userChrome} && echo -e "\nShadowFox userChrome.css has been downloaded"

  # download latest ShadowFox userContent.css
  echo "Downloading latest ShadowFox userContent.css file..."
  curl -O ${userContent} && echo -e "\nShadowFox userContent.css has been downloaded\n"

  echo "Would you like to auto-generate an internal_UUIDs.txt file based on your downloaded extensions?"
  echo "If you do so, your current file will be backed up."
  echo -e "WARNING: this step requires bash 4 to be installed.\n"

  read -p "Y/N? " -n 1 -r
  echo -e "\n\n"

  if [[ $REPLY =~ ^[Yy]$ ]]; then

    # Check for bash version 4 or higher
    if [ $(bash -c 'echo ${BASH_VERSINFO[0]}') -lt 4 ]; then
        echo "Please install bash version 4 or higher."
        exit 1
    fi

    # backup current internal_UUIDs.txt file
    if [ -s ./ShadowFox_customization/internal_UUIDs.txt ]; then
      bakfile="internal_UUIDs.backup.$(date +"%Y-%m-%d_%H%M%S")"
      mv ./ShadowFox_customization/internal_UUIDs.txt "chrome_backups/${bakfile}" && echo "Your previous internal_UUIDs.txt file was backed up: ${bakfile}"
    fi
    # download latest version of internal_UUID_finder.sh
    echo "Downloading latest internal_UUID_finder.sh file..."
    curl -o ./ShadowFox_customization/internal_UUID_finder.sh ${uuid_finder} && echo -e "\ninternal_UUID_finder.sh has been downloaded"

    # make internal_UUID_finder executable
    chmod +x ShadowFox_customization/internal_UUID_finder.sh

    # execute file
    ShadowFox_customization/internal_UUID_finder.sh
    echo "internal_UUIDs.txt has been generated based on your downloaded extensions."
  fi

  if [ -s ./ShadowFox_customization/internal_UUIDs.txt ]; then
    ## Insert any UUIDs defined in internal_UUIDs.txt into userContent.css
    while IFS='' read -r line || [[ -n "$line" ]]; do
        IFS='=' read -r -a array <<< "$line"
        sed -i '' "s/${array[0]}/${array[1]}/" "userContent.css"
    done < "./ShadowFox_customization/internal_UUIDs.txt"
    echo -e "Your internal UUIDs have been inserted.\n"
  else
    echo "You have not defined any internal UUIDs for webextensions."
    echo "If you choose not to do so, webextensions will not be styled with a dark theme and may have compatibility issues in about:addons."
    echo "For more information, see here:"
    echo -e "https://github.com/overdodactyl/ShadowFox/wiki/Altering-webextensions\n"
  fi

  if [ -s ./ShadowFox_customization/colorOverrides.css ]; then
    ## Delete everything inbetween override markers
    sed -i '' '/--start-indicator-for-updater-scripts: black;/,/--end-indicator-for-updater-scripts: black;/{//!d;}' userContent.css
    sed -i '' '/--start-indicator-for-updater-scripts: black;/,/--end-indicator-for-updater-scripts: black;/{//!d;}' userChrome.css

    ## Insert everything from colorOverrides.css
    sed -i '' '/--start-indicator-for-updater-scripts: black;/ r ./ShadowFox_customization/colorOverrides.css' userContent.css
    sed -i '' '/--start-indicator-for-updater-scripts: black;/ r ./ShadowFox_customization/colorOverrides.css' userChrome.css

    echo -e "Your custom colors have been set.\n"
  else
    echo "You are using the default colors set by ShadowFox."
    echo -e "You can customize the colors used by editing colorOverrides.css.\n"
  fi

  if [ -s ./ShadowFox_customization/userContent_customization.css ]; then
    ## Append tweaks to the end of userContent.css
    cat ./ShadowFox_customization/userContent_customization.css >> userContent.css
    echo -e "Your custom userContent.css tweaks have been applied.\n"
  else
    echo "You do not have any custom userContent.css tweaks."
    echo -e "You can customize userContent.css using userContent_customization.css.\n"
  fi

  if [ -s ./ShadowFox_customization/userChrome_customization.css ]; then
    ## Append tweaks to the end of userContent.css
    cat ./ShadowFox_customization/userChrome_customization.css >> userChrome.css
    echo -e "Your custom userChrome.css tweaks have been applied.\n"
  else
    echo "You do not have any custom userChrome.css tweaks."
    echo -e "You can customize userChrome.css using userChrome_customization.css.\n"
  fi

else
  echo "Process aborted"
fi

## Delete old updater script
[ -e ./../old_updater.sh ] && rm ./../old_updater.sh

## change directory back to the original working directory
cd "${currdir}"
