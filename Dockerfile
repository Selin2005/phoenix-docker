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
    chmod +x phoenix-server

# The user mentioned having these files locally for reference, 
# but for a self-contained Dockerfile, we ensure they exist.
# However, if the user wants to build from local files, we could COPY them.
# Based on the request "Docker image comes and downloads...", we download it.
# We will create the example_server.toml if it doesn't exist after unzip, 
# or use the one that comes with the zip.

# Copy our entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose the service port
EXPOSE 80

# Start the application via the entrypoint script
ENTRYPOINT ["sh", "/app/entrypoint.sh"]
