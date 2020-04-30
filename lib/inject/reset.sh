#!/usr/bin/env sh
#
# Stops and resets k3s
#
# TODO(jaredallard): remove docker volumes

echo "cleaning k3s"
rm -rf /var/lib/rancher
umount /etc/rancher

# sometimes files can show up after the bind mount is removed. It's cool, I know.
rm -rf /var/lib/rancher

docker stop k3s && docker rm k3s

containerIds="$(docker ps -a | grep k8s_ | awk '{ print $1 }')"
if test -n "$containerIds"; then
    echo "$containerIds" | xargs -n1 docker stop
    echo "$containerIds" | xargs -n1 docker rm
fi

echo "done"
