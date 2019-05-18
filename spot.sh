#!/bin/bash
# c4.xlarge high network performance, 7.5 G - ~$0.06/h * TAX = ~$0,078
# t3.large moderate network performance, 3.5 G - ~$0.03/h * $1,33 (TAX) ~= $0.04
request() {
  config_file='launch-config-frankfurt.json'

  i_type=${1:-t3.large}
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

load-game() {
  world=${1:? Path to minecraft world is required!}
  $publicIp=$(_get-ec2 | jq .Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp -r)
  scp ${world} ec2-user@${publicIp}:/home/ec2-user/minecraft-1.14
  ssh ec2-user@${publicIp} tar -xzf /home/ec2-user/minecraft-1.14/world.tar.gz
}

case $1 in
  'request')
  shift
  request $1
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
  *)
  cat <<HELP
Usage: ./spot.sh <command> <arg>

Commands:
---------

request [INSTANCE_TYPE]   request a spot instance
load-game                 speaks itself
cancel                    cancel a spot request, delete ec2 instance
list                      list spot instances
HELP
  ;;
esac

