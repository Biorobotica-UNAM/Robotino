#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /home/robotino/Robotino/install/setup.bash ]; then
  source /home/robotino/Robotino/install/setup.bash
fi

exec "$@"
