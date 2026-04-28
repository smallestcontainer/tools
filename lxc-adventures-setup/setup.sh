#!/bin/bash

INSTANCE_BASE_NAME="$(basename $(pwd))"
INSTANCE_COUNT=3
INSTANCE_DISTRO="ubuntu:24.04"
SSH_KEY_PATH="/home/scont/.ssh/id_ed25519.pub"
INVETORY_FILE_NAME="inventory.yaml"

while getopts ":n:c:r" opt; do
    case $opt in
        n) echo "Name ?" ;;
        c) INSTANCE_COUNT=$OPTARG;  ;;
        \?) echo "Bad arg" ;;
    esac
done

for (( id=0 ; id < INSTANCE_COUNT; id++ )); do
    INSTANCES[id]="$INSTANCE_BASE_NAME$id"
done

for INSTANCE in "${INSTANCES[@]}"; do
    if [[ "$(lxc list $INSTANCE -c=n --format=csv)" ]]; then
        echo "$INSTANCE is running. Stopping the container."
        lxc delete "$INSTANCE" --force
    fi
done

cat <<EOF > $INVETORY_FILE_NAME
all:
  children:
    containers:
      hosts:
EOF

for INSTANCE in "${INSTANCES[@]}"; do
    lxc launch "$INSTANCE_DISTRO" "$INSTANCE"
    echo "Waiting for ip"
    sleep 2
    INSTANCE_IP="$(lxc list $INSTANCE --columns=4 --format=csv | cut -d' ' -f1)"
    echo >> "$INVETORY_FILE_NAME" "        $INSTANCE_IP:"
    echo "Copying ssh key to the container"
    cat "$SSH_KEY_PATH" | lxc exec "$INSTANCE" -- sh -c \
                                            "mkdir -p /root/.ssh && \
                                            chmod 700 /root/.ssh && \
                                            cat >> /root/.ssh/authorized_keys&& \
                                            chmod 600 /root/.ssh/authorized_keys"
done


