#!bin/bash
#Array of config folders
CONFIGS=('bash' 'vim')
CONFIG_COUNT=${#CONFIGS[@]}

for((i=0;i<$CONFIG_COUNT;i++)); do

  echo '>Running '+CONFIGS[${i}]+'cleanup'
  bash ${CONFIGS[${i}]}/cleanup.sh
done
