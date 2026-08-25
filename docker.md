# Containerising IT Tools — Multi-Stage Docker Build

## Goal

Multi-stage Docker build for the IT Tools Vue/TypeScript SPA. Build stage compiles static assets; production stage serves them via nginx as a non-root user on a non-privileged port, with no build tooling in the final image.

## Dockerfile

```dockerfile
# Build Stage
FROM node:18-alpine AS build
WORKDIR /app
COPY ./app/package.json ./app/pnpm-lock.yaml ./
RUN corepack enable
RUN pnpm install
COPY ./app ./
RUN pnpm build

# Production Stage
FROM nginx:stable-alpine AS production
RUN apk del nginx-module-image-filter
COPY --from=build app/dist /usr/share/nginx/html
COPY --from=build app/nginx.conf /etc/nginx/conf.d/
RUN addgroup -g 1000 -S nonroot \
    && adduser -S nonroot -u 1000 -g nonroot
RUN rm -f /etc/nginx/conf.d/default.conf
RUN chown nonroot:nonroot /etc/nginx/conf.d /usr/share/nginx/html \
    /var/cache/nginx /var/log/nginx /run/
USER nonroot
EXPOSE 3000
```

## Key decisions

- **Manifest-first COPY**: `package.json`/`pnpm-lock.yaml` copied before source so `pnpm install` stays cached across rebuilds where only app code changed.
- **Non-root user**: nginx runs as `nonroot` for a better container security posture. This forces port 3000 instead of 80, since binding <1024 requires root — this didn't surface locally (Docker Desktop relaxes the restriction) but broke on ECS Fargate, which doesn't.
- **`chown` on nginx dirs**: required once non-root, since nginx needs explicit write permission on conf, cache, log, and runtime dirs it could access freely as root.
- **`rm -f default.conf`**: the stock config also listens on port 80 and loads alongside the custom config (`conf.d/*.conf` includes both), so it's removed to stop it winning as the default server.
- **`apk del nginx-module-image-filter`**: removes a package flagged by a Grype vulnerability scan (`tiff` CVE) in CI — not used by the app, so dropped from the production image.
- **`COPY --from` paths**: resolve from the source stage's filesystem root, not its `WORKDIR` — hence `app/dist`, not `./dist`.

## nginx config

SPA fallback (`try_files ... /index.html`) so client-side routes don't 404 on direct load/refresh, plus a `/health` endpoint for ECS/ALB health checks.

## Verification

```bash
docker build --no-cache -t it_tools_app .
docker run -d --name it-tools-mahad --restart unless-stopped -p 8080:3000 it_tools_app:latest
curl -i http://localhost:8080/health
```