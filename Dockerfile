# Use ROS 2 Jazzy as the base image
FROM ros:jazzy-ros-base

# Set arguments and environment variables
ARG ROS_DISTRO=jazzy
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

# Install git, pip, and essential build tools
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*

# Install rosdep
RUN pip install -U rosdep
RUN rosdep init || true
RUN rosdep update

# Install user-requested ROS 2 packages that are available as binaries
# (ros2_control, controllers, and teleop_twist_keyboard)
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-teleop-twist-keyboard \
    && rm -rf /var/lib/apt/lists/*

# Create a ROS 2 workspace
WORKDIR /ros2_ws
RUN mkdir src

# Clone the specified repositories into the workspace
# (The VESC package is not available as a Jazzy binary, so we build it from source)
RUN git clone https://github.com/Neuromancer2701/vesc_ros2_control_diff.git src/vesc_ros2_control_diff
RUN git clone https://github.com/ros-drivers/vesc.git -b ros2 src/vesc

# Source the ROS 2 setup and install all dependencies for the cloned repos
RUN . /opt/ros/${ROS_DISTRO}/setup.bash && \
    rosdep install --from-paths src --ignore-src -r -y

# Build the workspace
RUN . /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build --symlink-install

# Set up the entrypoint to source the workspace automatically
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && \
    echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

# Set the default command to keep the container running
CMD ["bash"]
