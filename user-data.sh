#!/bin/bash

yum update -y
yum install java-1.8.0-openjdk* -y

ln -s /usr/lib/jvm/java-1.8.0/bin/java /usr/bin/java8

mkdir -p /home/ec2-user/minecraft-server && cd $_

curl -LSs -O https://raw.githubusercontent.com/district13labs/mc-aws-single-instance/master/mc-server-components/eula.txt
curl -LSs -O https://raw.githubusercontent.com/district13labs/mc-aws-single-instance/master/mc-server-components/server.properties
curl -LSs -O https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar

chown -R ec2-user:ec2-user /home/ec2-user

touch /usr/local/bin/mc-start
echo -e '#!/bin/sh\ncd ${1:-/home/ec2-user/minecraft-server}\njava8 -server -Xmx3G -Xms1G -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=2 -XX:+AggressiveOpts -jar server.jar nogui' >> /usr/local/bin/mc-start
chmod +x /usr/local/bin/mc-start
