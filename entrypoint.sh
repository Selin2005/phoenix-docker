#!/bin/sh

# Copy example to server.toml
cp example_server.toml server.toml || exit 1

# Function to update configuration fields
update_config() {
    local key=$1
    local value=$2
    # Check if key exists (either active or commented) and update
    if grep -q "^#\? *$key =" server.toml; then
        sed -i "s|^#\? *$key =.*|$key = $value|" server.toml
    else
        echo "$key = $value" >> server.toml
    fi
}

# Generate security keys
./phoenix-server -gen-keys > public_key.log 2>&1

# Apply requested configurations
update_config "listen_addr" "\":80\""
update_config "enable_socks5" "true"
update_config "enable_udp" "true"
update_config "enable_shadowsocks" "false"
update_config "enable_ssh" "true"
update_config "private_key" "\"private.key\""

echo "Setup completed successfully."

# Execute the server (commented out by user request)
# exec ./phoenix-server

# Keep-alive for K8s (prevents CrashLoopBackOff)
tail -f /dev/null
