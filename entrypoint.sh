#!/bin/sh

# Copy example to server.toml
cp example_server.toml server.toml

# Function to update configuration fields
update_config() {
    local key=$1
    local value=$2
    # Check if key exists and update, or append if it doesn't
    if grep -q "^$key =" server.toml; then
        sed -i "s|^$key =.*|$key = $value|" server.toml
    else
        echo "$key = $value" >> server.toml
    fi
}

# Apply requested configurations
update_config "listen_addr" "\":80\""
update_config "enable_socks5" "true"
update_config "enable_udp" "true"
update_config "enable_shadowsocks" "false"
update_config "enable_ssh" "true"

# Execute the server
exec ./phoenix-server
