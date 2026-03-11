# Use a lightweight Alpine Linux base image
FROM alpine:latest

# Set versions and URLs
ENV PHOENIX_VERSION=1.0.1
ENV SINGBOX_VERSION=1.14.0-alpha.1
ENV PHOENIX_SERVER_URL=https://github.com/Fox-Fig/phoenix/releases/download/v${PHOENIX_VERSION}/phoenix-server-linux-amd64.zip
ENV PHOENIX_CLIENT_URL=https://github.com/Fox-Fig/phoenix/releases/download/v${PHOENIX_VERSION}/phoenix-client-linux-amd64.zip
ENV SINGBOX_URL=https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64-glibc.tar.gz

# Install necessary runtime dependencies
RUN apk add --no-cache curl unzip tar ca-certificates libgcc libstdc++

# Set the working directory
WORKDIR /app

# Download and extract the Phoenix server
RUN curl -L ${PHOENIX_SERVER_URL} -o server.zip && \
    unzip server.zip && \
    rm server.zip && \
    mv phoenix-server /usr/local/bin/phoenix-server && \
    mkdir -p /usr/local/share/phoenix && \
    mv example_server.toml /usr/local/share/phoenix/example_server.toml && \
    chmod +x /usr/local/bin/phoenix-server

# Download and extract the Phoenix client
RUN curl -L ${PHOENIX_CLIENT_URL} -o client.zip && \
    unzip client.zip && \
    rm client.zip && \
    mv phoenix-client /usr/local/bin/phoenix-client && \
    mv example_client.toml /usr/local/share/phoenix/example_client.toml && \
    chmod +x /usr/local/bin/phoenix-client

# Download and extract sing-box
RUN curl -L ${SINGBOX_URL} -o singbox.tar.gz && \
    tar -xzf singbox.tar.gz && \
    rm singbox.tar.gz && \
    mv sing-box-*/sing-box /usr/local/bin/sing-box && \
    rm -rf sing-box-* && \
    chmod +x /usr/local/bin/sing-box

# Copy our entrypoint script to a system directory
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the service port
EXPOSE 80

# Start the application via the entrypoint script
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]
