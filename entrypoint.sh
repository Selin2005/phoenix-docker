#!/bin/sh
set -x  # Enable debug tracing

echo "--- Starting Phoenix Server Setup ---"

# Copy example to server.toml
echo "1. Copying example_server.toml to server.toml..."
cp example_server.toml server.toml || { echo "ERROR: Failed to copy example_server.toml"; exit 1; }

# Function to update configuration fields (handles commented keys as well)
update_config() {
    local key=$1
    local value=$2
    echo "Updating config: $key -> $value"
    # Check if key exists (either active or commented) and update
    if grep -q "^#\? *$key =" server.toml; then
        sed -i "s|^#\? *$key =.*|$key = $value|" server.toml
    else
        echo "$key = $value" >> server.toml
    fi
}

# Generate keys and log the output
echo "2. Generating security keys..."
./phoenix-server -gen-keys > public_key.log 2>&1
echo "Key generation output captured in public_key.log"

# Apply requested configurations
echo "3. Applying custom configurations..."
update_config "listen_addr" "\":80\""
update_config "enable_socks5" "true"
update_config "enable_udp" "true"
update_config "enable_shadowsocks" "false"
update_config "enable_ssh" "true"
update_config "private_key" "\"private.key\""

echo "--- Setup Verification ---"
echo "Public Key Log Content:"
cat public_key.log

echo "Final server.toml Content:"
cat server.toml

echo "--- Setup Complete ---"
echo "Container will stay alive for inspection. Use 'docker exec' or 'kubectl exec' to explore."
# Execute the server (commented out by user request)
# exec ./phoenix-server

# Keep-alive for K8s (prevents CrashLoopBackOff)
tail -f /dev/null
