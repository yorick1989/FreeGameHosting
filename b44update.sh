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
# - The start.sh file will be installed in the location where the Battalion 1944 gameserver will be installed. The next command is an example how to use this start script:
#   ./start.sh --ip 123.123.123.123 --playmode Arcade --port 27035 --password password --map Coastal --gamemode TDM --max-clients 12 --steamid "<steam64_id>" --hostname "hostname" --starttype "ReadyUp"
#
# Example how to execute this update script:
# B44_ROOT=/home/b44user/b44_server /usr/local/bin/b44update.sh

CUR_FILE=${0/*\//};

CUR_DIR=$( cd $( dirname "${0}" ) && pwd );

[ -z "${B44_ROOT}" ] && B44_ROOT="${CUR_DIR}/../b44";

# Get the content of this script from github, to check if the script has some changes.
URL_CONTENT=$(wget --no-check-certificate -4qO- 'https://raw.githubusercontent.com/yorick1989/FreeGameHosting/master/b44update.sh');

# Execute previoust action, if there has no / empty content been found by wget (a.e.: during a network outage).
while [ -z "${URL_CONTENT}" ]; do

  URL_CONTENT=$(wget --no-check-certificate -4qO- 'https://raw.githubusercontent.com/yorick1989/FreeGameHosting/master/b44update.sh');

  sleep 2;

done

# Check for dependencies.
if ! type -p unzip &>/dev/null || ! type -p wget &>/dev/null; then

  echo "Dependencies: unzip wget";

  exit 2;

fi

# Update the currect update-file with the new content, if there are some diffs / changes been found. If so, the new version will be executed and the old one will exit.
if [ -n "$(diff "${CUR_DIR}/${CUR_FILE}" <(echo "${URL_CONTENT}"))" ] ;then

  echo "${URL_CONTENT}" > "${CUR_DIR}/${CUR_FILE}" ;

  chmod +x "${CUR_DIR}/${CUR_FILE}" ;

  echo "This '${CUR_FILE}' file has been updated. I'll now restart this script automatically." ;

  "${CUR_DIR}/${CUR_FILE}" $@

  exit 1;

fi

# If the current version file been found, and the Battalion 1944 (B44) gameserver root does exist; the battalion version will be set in the CUR_SVER variable.
[ -f "${CUR_DIR}/.b44server_version" ] && [ -d "${B44_ROOT}" ] && CUR_SVER=$( cat "${CUR_DIR}/.b44server_version" );

# The content of the official Community Servers page will be downloaded, and will be set in the web_content variable.
web_content=$(wget -4 -qO- "http://35.189.104.46/Community_Servers");

# Download the new B44 server files, and set the new server version in the server version file.
if [ -z "${CUR_SVER}" ] || ! grep -q "Current Version: ${CUR_SVER}" <<< "${web_content}"; then
  CUR_SVER=$( grep -P ".*(http.*LinuxServer_(.*).zip).*" <<< "${web_content}" | sed -r "s/.*(http.*LinuxServer.*_(.*).zip).*/\2/" )
  FILE_URL=$( grep -P ".*(http.*LinuxServer_(.*).zip).*" <<< "${web_content}" | sed -r "s/.*(http.*LinuxServer.*_(.*).zip).*/\1/" );
  mkdir -p "${CUR_DIR}/temp/b44";
  [ ! -f "${CUR_DIR}/temp/b44/server_${CUR_SVER}.zip" ] && wget -4O "${CUR_DIR}/temp/b44/server_${CUR_SVER}.zip" "${FILE_URL}"
  echo ${CUR_SVER} > "${CUR_DIR}/.b44server_version";
fi

# If the server files ZIP-file has been found, execute the gameserver update.
if [ -f "${CUR_DIR}/temp/b44/server_${CUR_SVER}.zip" ]; then

  cd "${CUR_DIR}/temp/b44";

  # Unzip the server files.
  unzip -o "server_${CUR_SVER}.zip";

  # Move the server files to a temp directory.
  mv "${CUR_DIR}"/temp/b44/LinuxServer "${CUR_DIR}"/temp/b44_tmp;

  # Remove the B44 directory where all the downloading and unzipping happened (not needed anymore).
  rm -rf "${CUR_DIR}"/temp/b44;

  # Move the config from the root B44 directory to the temp B44 directory.
  [ -d "${B44_ROOT}/configs" ] && mv "${B44_ROOT}/configs" "${CUR_DIR}/temp/b44_tmp/configs"

  # Remove the old B44 root directory.
  [ -d "${B44_ROOT}" ] && rm -rf "${B44_ROOT}";

  # Move the temp B44 directory to the B44 root directory.
  mv "${CUR_DIR}/temp/b44_tmp" "${B44_ROOT}";

  cat <<- 'EOF' > "${B44_ROOT}/start.sh"
#!/usr/bin/env bash
# Example:
# ./start.sh --ip 123.123.123.123 --playmode Arcade --port 27035 --password password --map Coastal --gamemode TDM --max-clients 12 --steamid "<steam64_id>" --hostname "hostname" --starttype "ReadyUp"
#
# See 'http://35.189.104.46/Community_Servers' for more details about maps, gametypes, playmodes and more.

CUR_DIR=$(cd $(dirname "${0}") && pwd);

CUR_FILE=${0/*\//};

GAME_LOC=${CUR_DIR};

# Set the arguments to search for.
declare -A ARG=(
  ['-i']="ip"
  ['--ip']="ip"
  ['-l']="playmode"
  ['--playmode']="playmode"
  ['-p']="port"
  ['--port']="port"
  ['-P']="password"
  ['--password']="password"
  ['-m']="map"
  ['--map']="map"
  ['-M']="gamemode"
  ['--gamemode']="gamemode"
  ['-c']="maxclients"
  ['--max-clients']="maxclients"
  ['-C']="config"
  ['--config']="config"
  ['-S']="steamid"
  ['--steamid']="steamid"
  ['-s']="starttype"
  ['--starttype']="starttype"
  ['-h']="hostname"
  ['--hostname']="hostname"
  ['-r']="maprotation"
  ['--maprotation']="maprotation"
  ['-R']="requiredplayers"
  ['--requiredplayers']="requiredplayers"
  ['-q']="queryport"
  ['--queryport']="queryport"
);

# Collect and set the arguments.
declare -A ARGS;

function parser() {

  set -- "$@";

  for arg in "${@}"; do

    if [ -n "${ARG[${arg}]}" ]; then

      ARG="${ARG[${arg}]}";

      if [ -n "${ARGS[${ARG}]}" ]; then

        unset ARGS[${ARG}];

      fi

    elif [ -n "${ARG}" ]; then

      if [ -z "${ARGS[${ARG}]}" ]; then

        ARGS["${ARG}"]="${arg}";

      else

        ARGS["${ARG}"]+=" ${arg}";

      fi

    fi

  done

}

parser "${@}"

if [ ! -z "${ARGS['config']}" ] && [ ! -f "${CUR_DIR}/${ARGS['config']}" ]; then
  
  echo "The config file '${CUR_DIR}/${ARGS['config']}' could not be found.";

  exit;

fi

mkdir -p "${CUR_DIR}/configs/${ARGS['port']}/logs";

cp "${CUR_DIR}/${ARGS['config']:=DefaultGame.ini}" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['hostname']}" ] && sed -i -r "s/^(ServerName)=.*/\1=${ARGS['hostname']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['password']}" ] && sed -i -r "s/^(Password)=.*/\1=${ARGS['password']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['playmode']}" ] && sed -i -r "s/^(PlayMode)=.*/\1=${ARGS['playmode']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['starttype']}" ] && sed -i -r "s/^(StartType)=.*/\1=${ARGS['starttype']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['maxclients']}" ] && sed -i -r "s/^(MaxPlayersPerTeam)=.*/\1=${ARGS['maxclients']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['maprotation']}" ] && sed -i -r "s/^(RandomMapRotationEnabled)=.*/\1=${ARGS['maprotation']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['requiredplayers']}" ] && sed -i -r "s/^(RequiredPlayers)=.*/\1=${ARGS['requiredplayers']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

if [ ! -z "${ARGS['steamid']}" ] ; then

  for steamid in ${ARGS['steamid']}; do
  
    if [ "${steamid}" = "${ARGS[steamid]/ *}" ]; then
    
      sed -i -r "s/^(\+AdminSteamIDs)=.*/\1=\"${steamid// /}\"/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";
    
    else
    
      sed -i "/+AdminSteamIDs=/a +AdminSteamIDs=\"${steamid// /}\"" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";
    
    fi

  done

fi

cd "${CUR_DIR}";

./Battalion/Binaries/Linux/BattalionServer /Game/Maps/Final_Maps/${ARGS['map']}?Game=/Script/ShooterGame.${ARGS['gamemode']}GameMode?listen -broadcastip="${ARGS['ip']}" -PORT=${ARGS['port']} -QueryPort=${ARGS['queryport']:=$(( ${ARGS['port']} - 1000 ))} -log -logfilesloc="${CUR_DIR}/logs" -userdir="${CUR_DIR}" -defgameini="${CUR_DIR}/configs/${ARGS['port']}/Game.ini"
EOF

  chmod u+x "${B44_ROOT}"/start.sh "${B44_ROOT}"/Battalion/Binaries/Linux/BattalionServer

  # Set a trigger file (if the TRIGGER_FILE variable has been set); so (CRON) scripts can run a specific action after an update of the B44 gameserver (the trigger file can be deleted, after this cronjob has been done).
  [ ! -z "${TRIGGER_FILE}" ] && echo "${CUR_SVER}" > "${CUR_DIR}/.b44server_update_completed";

  echo "Battalion 1944 server has been updated.";

fi