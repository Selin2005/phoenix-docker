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

# --- 1. Phoenix Server Setup ---
cd /tmp
echo "--- Phoenix Server: Generating Security Keys ---"
/usr/local/bin/phoenix-server -gen-keys > /tmp/server_publicKey.log 2>&1
echo "Public Key for Phoenix Server:"
cat /tmp/server_publicKey.log

if [ -f "/app/server.toml" ]; then
    echo "Custom server.toml detected in /app. Using it directly (skipping overrides)."
    SERVER_CONFIG="/app/server.toml"
else
    echo "No server.toml found in /app. Creating a managed config in /tmp..."
    cp /usr/local/share/phoenix/example_server.toml /tmp/server.toml || exit 1
    update_config "listen_addr" "\":80\"" "/tmp/server.toml"
    update_config "enable_socks5" "true" "/tmp/server.toml"
    update_config "enable_udp" "true" "/tmp/server.toml"
    update_config "enable_shadowsocks" "false" "/tmp/server.toml"
    update_config "enable_ssh" "true" "/tmp/server.toml"
    update_config "private_key" "\"private.key\"" "/tmp/server.toml"
    SERVER_CONFIG="/tmp/server.toml"
fi

# --- 2. Phoenix Client Setup ---
echo "--- Phoenix Client: Generating Security Keys ---"
# phoenix-client -gen-keys creates 'private.key' in CWD.
# We'll run it in a separate directory to avoid conflict with server's key, then rename it.
mkdir -p /tmp/client_setup
cd /tmp/client_setup
/usr/local/bin/phoenix-client -gen-keys > /tmp/client_publicKey.log 2>&1
echo "Public Key for Phoenix Client:"
cat /tmp/client_publicKey.log
[ -f "private.key" ] && mv private.key /tmp/client_private.key
cd /tmp

if [ -f "/app/client.toml" ]; then
    echo "Custom client.toml detected in /app. Using it directly (skipping overrides)."
    CLIENT_CONFIG="/app/client.toml"
else
    echo "No client.toml found in /app. Creating a managed config in /tmp..."
    cp /usr/local/share/phoenix/example_client.toml /tmp/client.toml || exit 1
    update_config "remote_addr" "\"foxfig.lol:80\"" "/tmp/client.toml"
    update_config "tls_mode" "\"insecure\"" "/tmp/client.toml"
    update_config "private_key" "\"client_private.key\"" "/tmp/client.toml"
    
    # Comment out all inbounds except protocol = "socks5"
    echo "Disabling non-socks5 inbounds in client.toml..."
    sed -i 's/^protocol = "http"/#protocol = "http"/' /tmp/client.toml
    sed -i 's/^protocol = "shadowsocks"/#protocol = "shadowsocks"/' /tmp/client.toml
    sed -i 's/^protocol = "ssh"/#protocol = "ssh"/' /tmp/client.toml
    
    CLIENT_CONFIG="/tmp/client.toml"
fi

# --- 3. sing-box Setup ---
echo "--- Creating sing-box Configuration ---"
cat > /tmp/sing-box.json <<EOF
{
  "log": {
    "level": "error"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true
    }
  ],
  "outbounds": [
    {
      "type": "socks",
      "tag": "socks-out",
      "server": "127.0.0.1",
      "server_port": 1080
    },
    {
      "type": "direct",
      "tag": "direct-out"
    }
  ],
  "route": {
    "rules": [
      {
        "process_name": ["phoenix-server"],
        "outbound": "socks-out"
      }
    ],
    "auto_detect_interface": true,
    "final": "direct-out"
  }
}
EOF

# --- 4. Process Launch ---
echo "Setup completed successfully. Starting processes..."

# Start Phoenix Client in background
echo "Starting Phoenix Client..."
/usr/local/bin/phoenix-client -config "$CLIENT_CONFIG" &

# Start sing-box in background (requires NET_ADMIN)
echo "Starting sing-box (Tunnel mode)..."
/usr/local/bin/sing-box run -c /tmp/sing-box.json &

# Start Phoenix Server in foreground
echo "Starting Phoenix Server as primary process..."
cd /tmp
exec /usr/local/bin/phoenix-server -config "$SERVER_CONFIG"
