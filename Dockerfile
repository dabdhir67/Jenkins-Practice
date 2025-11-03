# Tiny Nginx image
FROM nginx:alpine

# Remove default page and add ours
RUN rm -rf /usr/share/nginx/html/*
COPY site/ /usr/share/nginx/html/

# Expose port from container
EXPOSE 80

# Default command (from base image)