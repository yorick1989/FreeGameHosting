#!/usr/bin/env bash
#
# Script made by Yorick Gruijthuijzen
# 
# Date created: 1-2-2018
#
# NOTE: THERE IS NO GUARANTEE THAT THIS SCRIPT WILL WORK FOR THE FULL 100%.
# Change requests will be appreciated. 
#
# Tested on:
# Debian Stretch
#
# How to use:
# - Don't place this file in the same directory (or child directory) as the directory where the Battalion 1944 gameserver has been installed in.
# - Run this script as the same user as where you'd run the Battalion 1944 gameserver with.
# - You could use this script in a cronjob (advisable: a minimum of once in 5 minutes; because of the time UNZIP will take to unpacked all the server files).
#
# Example how to execute this update script:
# B44_ROOT=/home/b44user/b44_server /usr/local/bin/b44update.sh

CUR_FILE=${0/*\//};

CUR_DIR=$( cd $( dirname "${0}" ) && pwd );

URL_B44UPDATE='https://raw.githubusercontent.com/yorick1989/FreeGameHosting/master/server_tools/update/b44update.sh';

URL_B44START='https://raw.githubusercontent.com/yorick1989/FreeGameHosting/master/server_tools/start_scripts/b44start.sh';

[ -z "${B44_ROOT}" ] && B44_ROOT="${CUR_DIR}/../b44";

# Check for dependencies.
if ! type -p unzip wget > /dev/null; then

  echo "Dependencies: unzip wget";

  exit 2;

fi

# Get the content of this script from github, to check if the script has some changes.
URL_CONTENT=$(wget --no-check-certificate -4qO- "${URL_B44UPDATE}");

# Execute previoust action, if there has no / empty content been found by wget (a.e.: during a network outage).
while [ -z "${URL_CONTENT}" ]; do

  URL_CONTENT=$(wget --no-check-certificate -4qO- "${URL_B44UPDATE}");

  sleep 2;

done

# Update the currect update-file with the new content, if there are some diffs / changes been found. If so, the new version will be executed and the old one will exit.
if [ -n "$(diff "${CUR_DIR}/${CUR_FILE}" <(echo "${URL_CONTENT}"))" ] ;then

  echo "${URL_CONTENT}" > "${CUR_DIR}/${CUR_FILE}" ;

  chmod +x "${CUR_DIR}/${CUR_FILE}" ;

  echo "This '${CUR_FILE}' file has been updated. I'll now restart this script automatically." ;

  "${CUR_DIR}/${CUR_FILE}" $@

  exit 1;

fi

# If the current version file been found, and the Battalion 1944 (B44) gameserver root does exist; the battalion version will be set in the CUR_SVER variable.
[ -f "${B44_ROOT}/.b44server_version" ] && [ -d "${B44_ROOT}" ] && CUR_SVER=$( cat "${B44_ROOT}/.b44server_version" );

# The content of the official Community Servers page will be downloaded, and will be set in the web_content variable.
web_content=$(wget -4 -qO- "http://35.189.104.46/Community_Servers");

# Download the new B44 server files, and set the new server version in the server version file.
if [ -z "${CUR_SVER}" ] || ! grep -q "Current Version: ${CUR_SVER}" <<< "${web_content}"; then

  CUR_SVER=$( grep -P ".*(http.*LinuxServer_(.*).zip).*" <<< "${web_content}" | sed -r "s/.*(http.*LinuxServer.*_(.*).zip).*/\2/" )

  FILE_URL=$( grep -P ".*(http.*LinuxServer_(.*).zip).*" <<< "${web_content}" | sed -r "s/.*(http.*LinuxServer.*_(.*).zip).*/\1/" )

  # Unzip the server files to the document root of the b44 gameserver (overwrite existing files).
  unzip -o -d "${B44_ROOT}" "/tmp/server_${CUR_SVER}.zip";

  [ "$?" = 0 ] && rm -f "/tmp/server_${CUR_SVER}.zip";

  echo ${CUR_SVER} > "${B44_ROOT}/.b44server_version";

  # Set a trigger file (if the TRIGGER_FILE variable has been set); so (CRON) scripts can run a specific action after an update of the B44 gameserver (the trigger file can be deleted, after this cronjob has been done).
  [ ! -z "${TRIGGER_FILE}" ] && echo "${CUR_SVER}" > "${B44_ROOT}/.b44server_new_version";

  echo "Battalion 1944 server has been updated.";

fi

# Get the content of the startup script for b44 from github, to check if the script has some changes.
URL_CONTENT=$(wget --no-check-certificate -4qO- "${URL_B44START}");

# Execute previoust action, if there has no / empty content been found by wget (a.e.: during a network outage).
while [ -z "${URL_CONTENT}" ]; do

  URL_CONTENT=$(wget --no-check-certificate -4qO- "${URL_B44START}");

  sleep 2;

done

# Update the currect update-file with the new content, if there are some diffs / changes been found. If so, the new version will be executed and the old one will exit.
if [ -n "$(diff "${B44_ROOT}/${URL_B44START/*\//}" <(echo "${URL_CONTENT}"))" ] ;then

  echo "${URL_CONTENT}" > "${B44_ROOT}/${URL_B44START/*\//}";

  echo "Battalion 1944 startup script has been updated.";

fi
