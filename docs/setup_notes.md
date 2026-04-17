# Setup Notes — Issues and Solutions

## Environment

- **Host:** Ubuntu 24.04 LTS, Intel i5-10500, 32 GB RAM, Intel UHD 630
- **Docker:** Ubuntu 20.04 + ROS Noetic + Gazebo 11 + PX4 v1.14.3
- **FAST-LIVO2:** built from source (GitHub, latest)

## Why Docker?

FAST-LIVO2 is written for ROS 1 (Noetic), which is officially supported only on Ubuntu 20.04. On Ubuntu 22.04/24.04, a native ROS Noetic installation is extremely problematic — many repositories and dependencies are unsupported.

A Docker container with Ubuntu 20.04 solves this:
- All ROS Noetic packages are available from `packages.ros.org`
- GUI applications (Gazebo, RViz) are forwarded via X11
- Result files are accessible through shared volumes

## Timeline of Issues

### 1. Base image `ros:noetic-desktop-full` not found on Docker Hub

**Symptom:** `docker.io/library/ros:noetic-desktop-full: not found`
**Cause:** The image was removed from Docker Hub
**Solution:** Use `osrf/ros:noetic-desktop-full` from the Open Source Robotics Foundation

### 2. Sophus a621ff fails to compile

**Symptom:**
```
sophus/so2.cpp:32:26: error: lvalue required as left operand of assignment
   unit_complex_.real() = 1.;
```
**Cause:** GCC 9+ does not allow assignment through `.real()` / `.imag()`
**Solution:** Patch via `sed`:
```bash
sed -i 's/unit_complex_.real() = 1.;/unit_complex_ = std::complex<double>(1., 0.);/' sophus/so2.cpp
```

### 3. PX4 sitl_gazebo-classic fails to configure

**Symptom:** `sitl_gazebo-classic-configure` failed
**Cause:** Missing dev packages for Gazebo and GStreamer
**Solution:** Add to the Dockerfile:
```dockerfile
RUN apt-get install -y libgazebo11-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev protobuf-compiler ninja-build
```

### 4. IMU sensor SDF error

**Symptom:** `Required attribute[type] in element[noise] is not specified in SDF`
**Cause:** Inline noise definition inside the `<imu>` section is incompatible with the SDF 1.6 parser in Gazebo 11
**Solution:** Remove the inline noise from the SDF and use the `gaussianNoise` parameter of the `libgazebo_ros_imu_sensor.so` plugin instead

### 5. Velodyne LiDAR plugin missing

**Symptom:** `Failed to load plugin libgazebo_ros_velodyne_laser.so`
**Cause:** The package is not in the base ROS image
**Solution:** `apt install ros-noetic-velodyne-gazebo-plugins` (added to the Dockerfile)

### 6. PX4 EKF2 does not converge — rover cannot be armed

**Symptom:**
```
WARN [health_and_arming_checks] Preflight Fail: High Accelerometer Bias
WARN [health_and_arming_checks] Preflight Fail: Attitude failure (roll)
```
**Cause:** Time desynchronization between Gazebo and PX4 (time jumps), especially on heavy maps (RTF < 1.0). Known issues: #18658, #21229.
**Partial solution:**
- Force arming: `commander arm -f` in the PX4 console
- Disable preflight checks via MAVROS params
- Use lightweight maps (RTF ≈ 1.0)

**Outcome:** Arming works, but the failsafe takes over control. The Gazebo `diff_drive` plugin is used instead for stable motion.

### 7. Teleporting the rover breaks SLAM

**Symptom:** The point cloud stretches into a line instead of forming a volumetric map
**Cause:** `set_model_state` teleports the rover without realistic IMU data. The FAST-LIVO2 EKF cannot align the scans.
**Solution:** Use physical control via the `diff_drive` plugin and the `/cmd_vel` topic.

## Takeaways

Key lessons:
1. Docker is a necessity for ROS 1 projects on modern Ubuntu versions
2. PX4 SITL rover support is less mature than drone support
3. FAST-LIVO2 requires realistic IMU data — teleportation does not work
4. Lightweight maps (RTF ≈ 1.0) are critical for EKF stability
