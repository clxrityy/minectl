#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

if ! docker info >/dev/null 2>&1; then
    echo "✗ Docker daemon is not reachable."
    echo "  If you're using Colima, start it with:"
    echo "  colima start --cpu 4 --memory 8 --disk 40 --runtime docker"
    exit 1
fi

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
elif docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
else
    echo "✗ Neither docker-compose nor docker compose is available"
    exit 1
fi

CURRENT_CONTEXT=$(docker context show 2>/dev/null || true)
if [[ "$CURRENT_CONTEXT" != "colima" ]]; then
    echo "⚠ Docker context is '$CURRENT_CONTEXT' (not 'colima')."
    echo "  If you're using Colima, run: docker context use colima"
fi

compose() {
    "${COMPOSE[@]}" "$@"
}

client_exec() {
    compose exec -T client bash -lc "$1"
}

remote_exec() {
    local host="$1"
    local cmd="$2"
    client_exec "sshpass -p minectl ssh $SSH_OPTS root@${host} \"$cmd\""
}

minectl_exec() {
    local cmd="$1"
    client_exec "export SSHPASS=minectl; sshpass -e minectl $cmd"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if grep -Fq -- "$needle" <<<"$haystack"; then
        echo "✓ $message"
    else
        echo "✗ $message"
        echo "Expected to find: $needle"
        echo "Actual output:"
        printf '%s\n' "$haystack"
        exit 1
    fi
}

assert_equals() {
    local left="$1"
    local right="$2"
    local message="$3"

    if [[ "$left" == "$right" ]]; then
        echo "✓ $message"
    else
        echo "✗ $message"
        echo "Expected: $left"
        echo "Actual:   $right"
        exit 1
    fi
}

wait_for_systemd() {
    local service="$1"
    echo "Waiting for systemd in $service..."
    until compose exec -T "$service" bash -lc "state=\$(systemctl is-system-running 2>/dev/null || true); [[ \"\$state\" == \"running\" || \"\$state\" == \"degraded\" ]]"; do
        sleep 2
    done
    compose exec -T "$service" systemctl is-active sshd >/dev/null
    echo "✓ systemd and sshd ready in $service"
}

setup_client_ssh_key() {
    echo "Setting up SSH key in client..."

    client_exec 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
        [[ -f ~/.ssh/id_ed25519 ]] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" >/dev/null'

    client_exec "cat > ~/.ssh/config <<EOF
Host minectl-server1 minectl-server2
    User root
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
chmod 600 ~/.ssh/config"

    for host in minectl-server1 minectl-server2; do
        client_exec "sshpass -p minectl ssh-copy-id -f $SSH_OPTS root@${host} >/dev/null 2>&1"
    done

    echo "✓ Client SSH key installed on test servers"
}

wait_for_service_active() {
    local host="$1"
    local service="$2"
    local timeout="${3:-30}"
    local state=""

    echo "Waiting for service $service on $host..."

    for ((i=1; i<=timeout; i++)); do
        state=$(client_exec "ssh $SSH_OPTS root@${host} 'systemctl is-active ${service} 2>/dev/null || true'")
        case "$state" in
            active)
                echo "✓ Service $service is active on $host"
                return 0
                ;;
            activating|reloading)
                sleep 1
                ;;
            failed|inactive|deactivating)
                echo "✗ Service $service entered state: $state"
                client_exec "ssh $SSH_OPTS root@${host} 'systemctl status ${service} --no-pager || true'"
                client_exec "ssh $SSH_OPTS root@${host} 'journalctl -u ${service} -n 50 --no-pager || true'"
                exit 1
                ;;
            *)
                sleep 1
                ;;
        esac
    done

    echo "✗ Timed out waiting for $service on $host (last state: ${state:-unknown})"
    client_exec "ssh $SSH_OPTS root@${host} 'systemctl status ${service} --no-pager || true'"
    client_exec "ssh $SSH_OPTS root@${host} 'journalctl -u ${service} -n 50 --no-pager || true'"
    exit 1
}

echo "=== Minectl Test Environment ==="
echo ""

if ! command -v docker >/dev/null 2>&1; then
    echo "✗ docker not found"
    exit 1
fi

echo "Cleaning up old containers..."
compose down -v 2>/dev/null || true

echo "Building containers..."
compose build

echo "Starting containers..."
compose up -d

wait_for_systemd server1
wait_for_systemd server2

echo ""
echo "Installing client dependencies..."
compose exec -T client dnf install -y openssh-clients curl sshpass >/dev/null 2>&1
echo "✓ Client dependencies installed"
echo ""
setup_client_ssh_key

echo ""
echo "Configuring minectl client..."
client_exec 'mkdir -p ~/.minectl && cat > ~/.minectl/config <<EOF
CONFIG_DIR=/home/minecraft-servers
SSH_USER=minecraft-servers
EOF'
echo "✓ Client config created"

echo ""
echo "Testing SSH..."
SSH_OUTPUT=$(client_exec "ssh $SSH_OPTS root@minectl-server1 'echo SSH_WORKS'")
assert_contains "$SSH_OUTPUT" "SSH_WORKS" "SSH connectivity verified"

echo ""
echo "Creating base config on test servers..."
for host in minectl-server1 minectl-server2; do
    remote_exec "$host" "mkdir -p /home/minecraft-servers/servers && cat > /home/minecraft-servers/config <<'EOF'
MC_USER=minecraft
MC_BASE_DIR=/opt/minecraft
EOF"
done
echo "✓ Base config created"

echo ""
echo "Preparing import fixture on server1..."
remote_exec "minectl-server1" "mkdir -p /opt/minecraft/earth-1/logs
cp /opt/minectl-fixtures/fake-server.jar /opt/minecraft/earth-1/paper-26.2-87.jar
cat > /opt/minecraft/earth-1/jvm.properties <<'EOF'
server_jar=\"paper-26.2-87.jar\"
jvm_memory_max=\"512M\"
jvm_memory_min=\"512M\"
jvm_flags=\"-XX:+UseG1GC\"
EOF
echo '[fixture] file log line' > /opt/minecraft/earth-1/logs/latest.log
chown -R minecraft:minecraft /opt/minecraft/earth-1"
echo "✓ Import fixture created"

IMPORT_BEFORE=$(client_exec "ssh $SSH_OPTS root@minectl-server1 'sha256sum /opt/minecraft/earth-1/jvm.properties /opt/minecraft/earth-1/paper-26.2-87.jar /opt/minecraft/earth-1/logs/latest.log | sha256sum' | awk '{print \$1}'")

echo ""
echo "=== Running tests ==="
echo ""

echo "1. Validate global config..."
minectl_exec "validate root@minectl-server1"
echo "✓ Global config validates"

echo ""
echo "2. Create managed server on server2..."
minectl_exec "create-server root@minectl-server2 --server-name survival --memory 512M --jar file:///opt/minectl-fixtures/fake-server.jar"
echo "✓ Managed server created"

echo ""
echo "3. Start managed server and verify systemd..."
minectl_exec "start root@minectl-server2 --server-name survival"
wait_for_service_active "minectl-server2" "minecraft-survival"

echo ""
echo "4. Import existing server on server1..."
minectl_exec "import-server root@minectl-server1 --server-name earth-1 --java-bin /usr/bin/java"
echo "✓ Existing server imported"

echo ""
echo "5. Validate imported config..."
minectl_exec "validate root@minectl-server1 --server-name earth-1"
echo "✓ Imported server config validates"

echo ""
echo "6. Verify import was non-destructive..."
IMPORT_AFTER=$(client_exec "ssh $SSH_OPTS root@minectl-server1 'sha256sum /opt/minecraft/earth-1/jvm.properties /opt/minecraft/earth-1/paper-26.2-87.jar /opt/minecraft/earth-1/logs/latest.log | sha256sum' | awk '{print \$1}'")
assert_equals "$IMPORT_BEFORE" "$IMPORT_AFTER" "Import did not overwrite fixture files"

echo ""
echo "7. Check list output..."
LIST_OUTPUT=$(minectl_exec "list root@minectl-server1")
printf '%s\n' "$LIST_OUTPUT"
assert_contains "$LIST_OUTPUT" "earth-1 (imported)" "Imported server is labeled correctly"

echo ""
echo "8. Start imported server..."
minectl_exec "start root@minectl-server1 --server-name earth-1"
wait_for_service_active "minectl-server1" "minecraft-earth-1"

echo ""
echo "9. Verify file-log preference..."
LOG_OUTPUT=$(minectl_exec "logs root@minectl-server1 --server-name earth-1")
printf '%s\n' "$LOG_OUTPUT"
assert_contains "$LOG_OUTPUT" "[fixture] file log line" "File logs are preferred"

echo ""
echo "10. Verify journal fallback..."
sleep 2
remote_exec "minectl-server1" "mv /opt/minecraft/earth-1/logs/latest.log /opt/minecraft/earth-1/logs/latest.log.bak"
FALLBACK_OUTPUT=$(minectl_exec "logs root@minectl-server1 --server-name earth-1")
printf '%s\n' "$FALLBACK_OUTPUT"
assert_contains "$FALLBACK_OUTPUT" "fake-server started" "Journal fallback works"

echo ""
echo "11. Stop services..."
minectl_exec "stop root@minectl-server1 --server-name earth-1"
minectl_exec "stop root@minectl-server2 --server-name survival"
echo "✓ Services stopped"

echo ""
echo "=== All tests passed ==="
echo "This environment now exercises:"
echo "  - base config"
echo "  - managed server creation"
echo "  - existing server import"
echo "  - jvm.properties parsing"
echo "  - file-log preference"
echo "  - journal fallback"
echo "  - real systemd service management"
