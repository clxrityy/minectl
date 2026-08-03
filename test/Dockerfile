FROM rockylinux:8.6

ENV container=docker

RUN dnf install -y \
    bash \
    systemd \
    dbus \
    openssh-server \
    openssh-clients \
    curl \
    sudo \
    vim \
    net-tools \
    procps-ng \
    java-17-openjdk-headless \
    java-17-openjdk-devel \
    && dnf clean all

# Create minecraft user
RUN useradd -m -s /bin/bash minecraft

# Create a tiny runnable Java jar for deterministic tests
RUN mkdir -p /opt/minectl-fixtures/src && \
    cat > /opt/minectl-fixtures/src/FakeServer.java <<'EOF'
public class FakeServer {
    public static void main(String[] args) throws Exception {
        System.out.println("fake-server started");
        Thread.sleep(Long.MAX_VALUE);
    }
}
EOF
RUN javac /opt/minectl-fixtures/src/FakeServer.java && \
    printf 'Main-Class: FakeServer\n' > /opt/minectl-fixtures/manifest.txt && \
    jar cfm /opt/minectl-fixtures/fake-server.jar \
    /opt/minectl-fixtures/manifest.txt \
    -C /opt/minectl-fixtures/src FakeServer.class

# SSH setup
RUN mkdir -p /run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keygen -A && \
    echo "root:minectl" | chpasswd && \
    sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -ri 's/^#?UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config

# Allow minecraft user to manage services
RUN echo "minecraft ALL=(ALL) NOPASSWD: /usr/bin/systemctl" > /etc/sudoers.d/minecraft && \
    chmod 440 /etc/sudoers.d/minecraft

# Create config root
RUN mkdir -p /home/minecraft-servers/servers && \
    chown -R minecraft:minecraft /home/minecraft-servers

# Enable sshd under systemd
RUN systemctl enable sshd

STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
