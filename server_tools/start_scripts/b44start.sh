#!/usr/bin/env bash
# Example:
# ./b44start.sh --ip 123.123.123.123 --playmode Arcade --port 27035 --password password --map Coastal --gamemode TDM --max-clients 12 --steamid "<steam64_id>" --hostname "hostname" --starttype "ReadyUp"
#
# Check the url 'http://35.189.104.46/Community_Servers' for more details about maps, gametypes, playmodes, etc.

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

declare -A ARGS;

# Collect and set the arguments in the ARGS declaration / array (in a key => value format).
function argsparser() {

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

argsparser "${@}"

if [ ! -z "${ARGS['config']}" ] && [ ! -f "${CUR_DIR}/${ARGS['config']}" ]; then
  
  echo "The config file '${CUR_DIR}/${ARGS['config']}' could not be found.";

  exit;

fi

mkdir -p "${CUR_DIR}/configs/${ARGS['port']}/logs";

cp "${CUR_DIR}/${ARGS['config']:=DefaultGame.ini}" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['hostname']}" ] && sed -i -r "s/^(ServerName)=.*/\1=${ARGS['hostname']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['password']}" ] && sed -i -r "s/^(Password)=.*/\1=${ARGS['password']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['starttype']}" ] && sed -i -r "s/^(StartType)=.*/\1=${ARGS['starttype']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['maxclients']}" ] && sed -i -r "s/^(MaxPlayersPerTeam)=.*/\1=${ARGS['maxclients']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['maprotation']}" ] && sed -i -r "s/^(RandomMapRotationEnabled)=.*/\1=${ARGS['maprotation']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['requiredplayers']}" ] && sed -i -r "s/^(RequiredPlayers)=.*/\1=${ARGS['requiredplayers']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

[ ! -z "${ARGS['gamemode']}" ] && sed -i -r -e 's/^(\+ModeRotation=\/Script\/ShooterGame\..+GameMode)/\/\/\1/gI' -e "s/^\/\/(\+ModeRotation=\/Script\/ShooterGame\.${ARGS['gamemode']}GameMode)/\1/gI" -e '/\/\/(\+ModeRotation=\/Script\/ShooterGame\..+GameMode)/d' "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

if [ ! -z "${ARGS['playmode']}" ]; then

  sed -i -r "s/^(PlayMode)=.*/\1=${ARGS['playmode']}/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

  if [ "${ARGS['gamemode']^^}" = "BOMB" ] && [ "${ARGS['gamemode']}" = "Comp" ]; then

    sed -i -r "s/^(Deckname)=(UnrankedBOMB|INF)Deck0.*/\1=${ARGS['gamemode']^^}Deck0/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

  else

    sed -i -r "s/^(Deckname)=INFDeck0.*/\1=${ARGS['gamemode']^^}Deck0/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";

  fi

fi

if [ ! -z "${ARGS['steamid']}" ] ; then

  for steamid in ${ARGS['steamid']}; do
  
    if [ "${steamid// /}" = "${ARGS[steamid]/ *}" ]; then
    
      sed -i -r "s/^(\+AdminSteamIDs)=.*/\1=\"${steamid// /}\"/g" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";
    
    else
    
      sed -i "/+AdminSteamIDs=/a +AdminSteamIDs=\"${steamid// /}\"" "${CUR_DIR}/configs/${ARGS['port']}/Game.ini";
    
    fi

  done

fi

cd "${CUR_DIR}";

./Battalion/Binaries/Linux/BattalionServer /Game/Maps/Final_Maps/${ARGS['map']}?Game=/Script/ShooterGame.${ARGS['gamemode']}GameMode?listen -broadcastip="${ARGS['ip']}" -PORT=${ARGS['port']} -QueryPort=${ARGS['queryport']:=$(( ${ARGS['port']} - 1000 ))} -log -logfilesloc="${CUR_DIR}/logs/configs/${ARGS['port']}" -userdir="${CUR_DIR}" -defgameini="${CUR_DIR}/configs/${ARGS['port']}/Game.ini"