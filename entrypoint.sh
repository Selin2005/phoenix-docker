#!/bin/sh

# Function to update configuration fields
update_config() {
    local key=$1
    local value=$2
    local target=$3
    # Check if key exists (either active or commented) and update
    if grep -q "^#\? *$key =" "$target"; then
        sed -i "s|^#\? *$key =.*|$key = $value|" "$target"
    else
        echo "$key = $value" >> "$target"
    fi
}

# Generate security keys
# We use /tmp for the log because /app might be read-only.
# Note: phoenix-server creates 'private.key' in the CURRENT directory.
cd /tmp
/usr/local/bin/phoenix-server -gen-keys > /tmp/public_key.log 2>&1
echo "--- Security Key Generation Log ---"
cat /tmp/public_key.log
echo "-----------------------------------"

# Determine which config file to use
if [ -f "/app/server.toml" ]; then
    echo "Custom server.toml detected in /app. Using it directly (skipping overrides)."
    CONFIG_PATH="/app/server.toml"
else
    echo "No server.toml found in /app. Creating a managed config in /tmp..."
    cp /usr/local/share/phoenix/example_server.toml /tmp/server.toml || exit 1
    
    # Apply requested configurations to the writable /tmp/server.toml
    update_config "listen_addr" "\":80\"" "/tmp/server.toml"
    update_config "enable_socks5" "true" "/tmp/server.toml"
    update_config "enable_udp" "true" "/tmp/server.toml"
    update_config "enable_shadowsocks" "false" "/tmp/server.toml"
    update_config "enable_ssh" "true" "/tmp/server.toml"
    # Note: private.key was generated in /tmp
    update_config "private_key" "\"private.key\"" "/tmp/server.toml"
    
    CONFIG_PATH="/tmp/server.toml"
fi

echo "Setup completed successfully. Starting Phoenix Server..."

# Execute the server from /tmp so it finds private.key if needed
cd /tmp
exec /usr/local/bin/phoenix-server -config "$CONFIG_PATH"
