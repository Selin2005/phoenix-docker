#!/bin/sh

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

# Generate security keys and save log to /app
# We try to write to /app, but handle potential read-only errors
/usr/local/bin/phoenix-server -gen-keys > /app/public_key.log 2>&1
if [ $? -ne 0 ]; then
    echo "Warning: Could not write public_key.log to /app (might be a read-only mount)."
fi

# Check if server.toml exists in /app (could be mounted by user)
if [ -f "/app/server.toml" ]; then
    echo "Custom server.toml detected. Skipping automatic configuration overrides."
else
    echo "No server.toml found. Constructing from system template..."
    cp /usr/local/share/phoenix/example_server.toml /app/server.toml || exit 1
    
    # Apply requested configurations ONLY to the auto-generated file
    cd /app
    update_config "listen_addr" "\":80\""
    update_config "enable_socks5" "true"
    update_config "enable_udp" "true"
    update_config "enable_shadowsocks" "false"
    update_config "enable_ssh" "true"
    update_config "private_key" "\"private.key\""
fi

echo "Setup completed successfully."

# Keep-alive for K8s (prevents CrashLoopBackOff)
tail -f /dev/null
