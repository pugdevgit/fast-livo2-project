#!/bin/bash
source /opt/ros/noetic/setup.bash
source /root/catkin_ws/devel/setup.bash
source /root/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash /root/PX4-Autopilot /root/PX4-Autopilot/build/px4_sitl_default
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/root/PX4-Autopilot:/root/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic
exec "$@"
