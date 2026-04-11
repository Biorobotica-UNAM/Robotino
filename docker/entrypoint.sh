#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /home/robotino/justina_hardware/install/setup.bash ]; then
  source /home/robotino/justina_hardware/install/setup.bash
fi

exec "$@"
