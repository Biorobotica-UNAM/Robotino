#!/bin/bash
set -e

IMAGE_NAME="robotino:jazzy"

docker run --rm -it \
  --name robotino_jazzy \
  --network host \
  --ipc host \
  --pid host \
  --privileged \
  -e RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
  -e ROS_DOMAIN_ID=0 \
  -e DISPLAY=${DISPLAY} \
  -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /dev:/dev \
  -v /run/udev:/run/udev:ro \
  "${IMAGE_NAME}" \
  bash
