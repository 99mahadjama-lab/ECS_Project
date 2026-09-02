#Build Stage
FROM node:18-alpine AS build
WORKDIR /app
COPY ./app/package.json ./app/pnpm-lock.yaml ./
RUN corepack enable
RUN pnpm install
COPY ./app ./
RUN pnpm build

#Production Stage
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
