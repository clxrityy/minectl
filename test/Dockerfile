FROM rockylinux:8.6

RUN dnf install -y \
    bash \
    openssh-server \
    openssh-clients \
    curl \
    java-17-openjdk-headless \
    sudo \
    vim \
    net-tools

# Create minecraft user
RUN useradd -m -s /bin/bash minecraft

# Setup SSH
RUN mkdir -p /run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Allow passwordless sudo for systemctl
RUN echo "minecraft ALL=(ALL) NOPASSWD: /usr/bin/systemctl" >> /etc/sudoers.d/minecraft

# Create config directory
RUN mkdir -p /home/minecraft-servers/servers && \
    chown minecraft:minecraft /home/minecraft-servers

# Setup SSH with key-based auth
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "root:minectl" | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
