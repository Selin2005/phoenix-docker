# Use a lightweight Alpine Linux base image
FROM alpine:latest

# Set version as an environment variable (optional but good practice)
ENV PHOENIX_VERSION=1.0.1
ENV PHOENIX_URL=https://github.com/Fox-Fig/phoenix/releases/download/v${PHOENIX_VERSION}/phoenix-server-linux-amd64.zip

# Install necessary runtime dependencies
# curl for downloading, unzip for extraction, ca-certificates for HTTPS
RUN apk add --no-cache curl unzip ca-certificates libgcc libstdc++

# Set the working directory
WORKDIR /app

# Download and extract the Phoenix server
RUN curl -L ${PHOENIX_URL} -o phoenix.zip && \
    unzip phoenix.zip && \
    rm phoenix.zip && \
    mv phoenix-server /usr/local/bin/phoenix-server && \
    mkdir -p /usr/local/share/phoenix && \
    mv example_server.toml /usr/local/share/phoenix/example_server.toml && \
    chmod +x /usr/local/bin/phoenix-server

# Copy our entrypoint script to a system directory
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the service port
EXPOSE 80

# Start the application via the entrypoint script
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]
