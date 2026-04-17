#!/bin/bash
xhost +local:docker

docker run -it --rm \
    --name fast-livo2 \
    --env DISPLAY=$DISPLAY \
    --env QT_X11_NO_MITSHM=1 \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --volume ~/fast-livo2-project/results:/root/results \
    --volume ~/fast-livo2-project/fast_livo2_sim:/root/catkin_ws/src/fast_livo2_sim \
    --device /dev/dri:/dev/dri \
    --net=host \
    --privileged \
    fast-livo2-img
