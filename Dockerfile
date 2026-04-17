FROM osrf/ros:noetic-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=noetic
SHELL ["/bin/bash", "-c"]

# ============================================
# 1. Базовые пакеты и инструменты
# ============================================
RUN apt-get update && apt-get install -y \
    git cmake build-essential \
    python3-catkin-tools python3-pip python3-rosdep \
    ros-noetic-mavros ros-noetic-mavros-extras \
    ros-noetic-gazebo-ros ros-noetic-gazebo-plugins \
    ros-noetic-gazebo-ros-pkgs ros-noetic-gazebo-ros-control \
    ros-noetic-cv-bridge ros-noetic-image-transport \
    ros-noetic-pcl-ros ros-noetic-pcl-conversions \
    ros-noetic-tf2-ros ros-noetic-tf2-eigen \
    ros-noetic-velodyne-gazebo-plugins \
    libpcl-dev libeigen3-dev libopencv-dev \
    libgoogle-glog-dev libgflags-dev \
    mesa-utils wget curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Установить GeographicLib данные для MAVROS
RUN wget -q https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
    && bash install_geographiclib_datasets.sh && rm install_geographiclib_datasets.sh

# ============================================
# 2. Sophus (нужен FAST-LIVO2)
# ============================================
RUN cd /opt && git clone https://github.com/strasdat/Sophus.git \
    && cd Sophus && git checkout a621ff \
    && sed -i 's/unit_complex_.real() = 1.;/unit_complex_ = std::complex<double>(1., 0.);/' sophus/so2.cpp \
    && sed -i 's/unit_complex_.imag() = 0.;//' sophus/so2.cpp \
    && sed -i 's/unit_complex_.real() = std::cos(theta);/unit_complex_ = std::complex<double>(std::cos(theta), std::sin(theta));/' sophus/so2.cpp \
    && sed -i 's/unit_complex_.imag() = std::sin(theta);//' sophus/so2.cpp \
    && mkdir build && cd build && cmake .. && make -j$(nproc) \
    && make install

# ============================================
# 3. Catkin workspace + Vikit + FAST-LIVO2
# ============================================
RUN mkdir -p /root/catkin_ws/src

RUN cd /root/catkin_ws/src \
    && git clone https://github.com/xuankuzcr/rpg_vikit.git \
    && git clone https://github.com/hku-mars/FAST-LIVO2.git

RUN source /opt/ros/noetic/setup.bash \
    && cd /root/catkin_ws \
    && catkin_make -j$(nproc) \
    || { echo "First build may have warnings, retrying..."; catkin_make -j$(nproc); }

# ============================================
# 4. PX4 Autopilot
# ============================================
RUN apt-get update && apt-get install -y \
    libgazebo11-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    libprotobuf-dev protobuf-compiler libeigen3-dev libxml2-utils \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN cd /root && git clone --recursive --depth 1 -b v1.14.3 \
    https://github.com/PX4/PX4-Autopilot.git \
    && cd PX4-Autopilot && bash Tools/setup/ubuntu.sh --no-sim-tools

RUN cd /root/PX4-Autopilot \
    && DONT_RUN=1 make px4_sitl gazebo
# ============================================
# 5. Entrypoint
# ============================================
COPY ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
