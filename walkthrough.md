# Final Walkthrough: GitHub Migration & GHCR Automation

The project has been successfully migrated to GitHub with a fully automated CI/CD pipeline.

## GitHub Migration
- **Repository**: [Selin2005/phoenix-docker](https://github.com/Selin2005/phoenix-docker)
- **Primary Remote**: `origin` (SSH: `git@github.com:Selin2005/phoenix-docker.git`)
- **Secondary Remote**: `hamgit` (for reference)

## Automation: GitHub Actions & GHCR
The project now uses GitHub Actions to automatically build and push Docker images.

- **Workflow**: `.github/workflows/docker-publish.yml`
- **Registry**: GitHub Container Registry (GHCR)
- **Image URL**: `ghcr.io/selin2005/phoenix-docker:latest`

### How It Works
Every time you push to the `main` branch:
1. GitHub Actions starts a build.
2. It logs in to GHCR automatically.
3. It builds the Docker image and tags it as `latest`.
4. It pushes the image to the registry.

## How to Use the New Image
To pull and run the image from anywhere:
```bash
docker pull ghcr.io/selin2005/phoenix-docker:latest
docker run -d -p 80:80 --name phoenix-app ghcr.io/selin2005/phoenix-docker:latest
```

> [!TIP]
> You can check the progress of your builds in the **Actions** tab of your GitHub repository.
> To make the image public, go to your repository's **Packages** settings on GitHub.

## Key Generation & Secure Config
The Docker image now automatically handles security setup:
1. **Key Generation**: Runs `./phoenix-server -gen-keys` on startup.
2. **Public Key Log**: Saves the generation output to `public_key.log`.
3. **Private Key Configuration**: Automatically uncommented and set `private_key = "private.key"` in `server.toml`.
4. **No Auto-Start**: The server setup runs, but the server itself is not started automatically (as requested), allowing you to review the keys first.

### How to Retrieve Your Public Key
After running the container, you can see your public key by reading the log:
```bash
docker run --name phoenix-setup ghcr.io/selin2005/phoenix-docker:latest
docker cp phoenix-setup:/app/public_key.log .
cat public_key.log
```

## How to Run the Server Manually
Once you have reviewed the keys, you can run the server inside the k8s/docker environment by executing:
```bash
./phoenix-server
```

## K8s Volume Mount Compatibility
If you mount a **ConfigMap** or **Volume** to `/app`, the original files in that directory will be hidden. To fix this:
1. **Relocated Binaries**: `phoenix-server` and `entrypoint.sh` are now located in `/usr/local/bin/`.
2. **System Templates**: `example_server.toml` is stored in `/usr/local/share/phoenix/`.
3. **Safe Setup**: The script now detects if `server.toml` is missing in `/app` and automatically restores it from the system template before applying your configurations.

This ensures that your `ConfigMap` and our automatic setup work perfectly together.

## Verification
- Relocated executables to `/usr/local/bin` for K8s mount compatibility.
- Fixed K8s `CrashLoopBackOff` by adding `tail -f /dev/null` (Keep-Alive).
- Fixed `entrypoint.sh` execution error by using explicit `sh` call.
- Automated security setup (Key Generation & Config override).
- Cleaned up all verbose debug logs for a professional setup process.
- All changes pushed and verified on GitHub Actions.
