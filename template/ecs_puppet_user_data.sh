#!/bin/bash

###
# ECS Cluster setup
###
echo ECS_CLUSTER=${ecs_cluster} >> /etc/ecs/ecs.config

###
# Rclone setup
###
sudo yum install -y unzip fuse
sudo curl https://rclone.org/install.sh | sudo bash
sudo ln -s /usr/bin/rclone /sbin/mount.rclone
sudo mkdir /etc/rclone
sudo mkdir /var/rclone/mount
sudo mkdir /var/cache/rclone

sudo cat <<EOF > /etc/rclone/rclone.conf
[s3]
type = s3
provider = AWS
env_auth = true
region = ap-northeast-1
location_constraint = ap-northeast-1
acl = private
storage_class = STANDARD
EOF

sudo cat <<EOF > /etc/systemd/system/etc-rclone-mount.mount
[Unit]
After=network-online.target
[Mount]
Type=rclone
What=s3:${s3_bucket}
Where=/etc/rclone/mount
Options=rw,allow_other,args2env,vfs-cache-mode=writes,config=/etc/rclone/rclone.conf,cache-dir=/var/cache/rclone
EOF
sudo systemctl start etc-rclone-mount.mount
