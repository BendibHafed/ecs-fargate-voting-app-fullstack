# Build stage
FROM node:22-alpine AS builder

WORKDIR /app
COPY . .

RUN npm ci
RUN npx vite build --mode production

# Serve stage
FROM nginx:stable-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
