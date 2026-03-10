---
description: Build and push the Phoenix image to registry.hamdocker.ir
---

This workflow automates the process of building the Docker image locally and pushing it to the Hamdocker registry.

### Prerequisites
- Docker must be installed and running.
- You must have credentials for `registry.hamdocker.ir`.

### 1. Build the Docker Image
// turbo
```bash
docker build -t registry.hamdocker.ir/batman/kok:main .
```

### 2. Login to the Registry
> [!NOTE]
> This step requires your username and password/token.
```bash
docker login registry.hamdocker.ir
```

### 3. Push the Image
// turbo
```bash
docker push registry.hamdocker.ir/batman/kok:main
```
