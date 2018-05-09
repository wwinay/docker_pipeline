#!/bin/bash
#JOB_NAME=Dev/src
image_tag=$(echo "$JOB_NAME" | awk -F "/" '{print $1}')
proj_name=$(echo "$JOB_NAME" | awk -F "/" '{print $2}')
echo "$ip_address" > /opt/tmp/jen_ip

container_stop () {
echo "Stop container started"
cont_id="$(sudo docker ps --all --quiet --filter=name="${proj_name}")"
sudo docker stop ${cont_id} && sudo docker rm $cont_id
}

container_stop

img_pull () {
sudo docker pull centos
}

img_pull

img_del () {
sudo docker rmi ldap:${image_tag}
}

img_del

img_build () {
cd /opt/tmp/ldap_rst
sudo docker build -t ldap:${image_tag} .
}

img_build

cont_run () {
sudo docker run -d --name ${proj_name} ldap:${image_tag}
new_container_id="$(sudo docker ps --all --quiet --filter=name="${proj_name}")"
echo $new_container_id
echo "$new_container_id" > /opt/tmp/new_cont

}
cont_run
