#!/bin/bash

yum update -y
yum install java-1.8.0-openjdk* -y

ln -s /usr/lib/jvm/java-1.8.0/bin/java /usr/bin/java8

mkdir -p /home/ec2-user/minecraft-server && cd $_

aws s3 cp --recursive s3://saxum-vermes/minecraft-server/mc-server-components ./
curl -LSs -O https://launcher.mojang.com/v1/objects/ed76d597a44c5266be2a7fcd77a8270f1f0bc118/server.jar

chown -R ec2-user:ec2-user /home/ec2-user

touch /usr/local/bin/mc-start
echo -e '#!/bin/sh\ncd ${1:-/home/ec2-user/minecraft-server}\njava8 -server -Xmx3G -Xms1G -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=2 -XX:+AggressiveOpts -jar server.jar nogui' >> /usr/local/bin/mc-start
chmod +x /usr/local/bin/mc-start
