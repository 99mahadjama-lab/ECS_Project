#Build Stage
FROM node:18-alpine AS build
#Set Working Directory
WORKDIR /app
#Copy only the manifest files (not ".") so the pnpm install layer stays cached
COPY ./app/package.json ./app/pnpm-lock.yaml ./
#Enable pnpm commands
RUN corepack enable
#Install dependancies required
RUN pnpm install
#Copy application code
COPY ./app ./
#Complile application code to one folder
RUN pnpm build

#Production Stage
FROM nginx:stable-alpine AS production
#Remove unnecessary packages scanned with vulnerability checker
RUN apk del nginx-module-image-filter
#Copy dist folder from build stage to html file
COPY --from=build app/dist /usr/share/nginx/html
#Copy nginx.conf file to direct unknown urls to index.html
COPY --from=build app/nginx.conf /etc/nginx/conf.d/
#Create non-root user
RUN addgroup -g 1000 -S nonroot \
&& adduser -S nonroot -u 1000 -g nonroot
#remove default.conf file
RUN rm -f /etc/nginx/conf.d/default.conf
#assign ownership for required files
RUN chown nonroot:nonroot /etc/nginx/conf.d /usr/share/nginx/html \ 
/var/cache/nginx /var/log/nginx /run/
#Switch User to nonroot
USER nonroot
#Expose port
EXPOSE 3000
