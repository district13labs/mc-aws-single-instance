#!/bin/bash
# c4.xlarge high network performance, 7.5 G - ~$0.06/h * TAX = ~$0,078
# t3.large moderate network performance, 3.5 G - ~$0.03/h * 1,33 (TAX) ~= $0.04
# c5d.large up to 10G perfromance 4G RAM, higher computing power

request() {
  config_file=${1:? Path to configuration file required!}
  i_type=${2:-t3.large}

  if [[ $i_type = 't3.large' ]]; then
    echo 'Instance type set to default: t3.large'
  fi

  echo 'Requesting instance...'
  launch_c=$(sed "s/{user_data}/$(cat user-data.sh | base64 -w 0)/g" ${config_file})
  launch_c=$(sed "s/{instance_type}/${i_type}/g" <<< ${launch_c})
  aws ec2 request-spot-instances --spot-price 0.065 --launch-specification "${launch_c}"
}

cancel() {
  aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $(_get-id)
  aws ec2 terminate-instances --instance-ids $(_get-ec2-id)
}

list() {
  aws ec2 describe-spot-instance-requests --filter '[{"Name": "state", "Values": ["active"]}, {"Name": "launch.group-name", "Values": ["minecraft-server"]}]'
}

_get-id() {
    list | jq .SpotInstanceRequests[].SpotInstanceRequestId -r
}

_get-ec2() {
  aws ec2 describe-instances --filter Name=spot-instance-request-id,Values=$(_get-id)
}

_get-ec2-id() {
  _get-ec2 | jq .Reservations[].Instances[].InstanceId -r
}

get-ec2-pub-ip() {
  _get-ec2 | jq .Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp -r
}

load-game() {
  world=${1:? Path to minecraft world is required!}
  publicIp=$(get-ec2-pub-ip)
  scp ${world} ec2-user@${publicIp}:/home/ec2-user/minecraft-server
  ssh-ec2 tar -xzf /home/ec2-user/minecraft-server/world.tar.gz -C /home/ec2-user/minecraft-server
  ssh-ec2 rm -rf /home/ec2-user/minecraft-server/world.tar.gz
}

save-game() {
  world=${1:? Provide a path where the game should be saved!}
  saveName=${2:? Name of the save required!}
  publicIp=$(get-ec2-pub-ip)
  ssh-ec2 tar -czf /home/ec2-user/minecraft-server/${saveName}.tar.gz /home/ec2-user/minecraft-server/world
  scp -o StrictHostKeyChecking=no ec2-user@${publicIp}:/home/ec2-user/minecraft-server/${saveName}.tar.gz ${world}
}

ssh-ec2() {
  ssh -o StrictHostKeyChecking=no ec2-user@$(get-ec2-pub-ip) $@
}

launch-server() {
  ssh-ec2 mc-start
}

shutdown-server() {
  ssh-ec2 pkill -f java8
}

case $1 in
  'request')
  shift
  request $1 $2
  ;;
  'list')
  list
  ;;
  'cancel')
  cancel
  ;;
  'load-game')
  shift
  load-game $1
  ;;
  'save-game')
  shift
  save-game $1 $2
  ;;
  'get-ec2-pub-ip')
  get-ec2-pub-ip
  ;;
  'ssh')
  ssh-ec2
  ;;
  'server')
  shift
  case $1 in
    'launch')
    launch-server
    ;;
    'shutdown')
    shutdown-server
    ;;
    *)
    echo 'Possible values are: ./mc-server server launch|shutdown'
    ;;
  esac
  ;;
  *)
  cat <<HELP
Usage: ./spot.sh <command> <arg>

Commands:
---------

request [INSTANCE_TYPE]            request a spot instance, defaults to t3.large
load-game  PATH_TO_WORLD           speaks itself
save-game  PATH_TO_SAVE_LOCATION   speaks itself
server [launch|shutdown]           launch or shutdown minecraft server
ssh [COMMAND]                      ssh into the instance, or run a command through ssh
get-ec2-pub-ip                     get ip address of requested ec2 instance
cancel                             cancel a spot request, delete ec2 instance
list                               list spot requests
HELP
  ;;
esac

