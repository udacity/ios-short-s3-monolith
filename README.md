# Monolith Service

This repository contains the monolith service from Udacity's server-side Swift curriculum. The monolith is a simple Swift server that exposes three endpoints:

- /
  - returns a basic message
- /login
  - when provided a valid username/password, returns an auth token
- /secure
  - when provided a valid auth token, returns a "secure" message

To experiment with the endpoints, see the [Lesson 1: Monolith Docs on Apiary](http://docs.l1monolith.apiary.io/#).

Also, the monolith uses the Swift Package Manager to manage dependencies.

## Swift Dependencies

- Kitura
- HeliumLogger
- Kitura-Credentials
- Kitura-CredentialsHTTP
- Perfect-Crypto

## How to Use

The monolith service can technically be built to run on macOS or Ubuntu Linux. However, we recommend building for Ubuntu Linux since that will likely be the environment used if you were to deploy the monolith into the cloud. Furthermore, to assure consistency between development and possible deployment environments, Docker is used. Take the following steps to build and run the monolith:

**1] Build the Docker Image**

```bash
docker build -t s3-monolith:1.0.0 .
```

**2] Run the Docker Image (start Bash shell)**

```bash
docker run --privileged --rm -it -v $(pwd):/app -p 8080:8080 s3-monolith:1.0.0 /bin/bash
```

**3] Build the Monolith**

```bash
# assuming you are located at /app
swift build
```

**4] Run the Monolith**

```bash
# assuming you are located at /app
.build/debug/monolith
```

**5] Test an Endpoint!**

```bash
curl localhost:8080
```
