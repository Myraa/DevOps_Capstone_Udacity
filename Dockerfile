FROM nginx

## Step 1:
RUN rm /usr/share/nginx/html/index.html

## Step 2:
# Copy source code to working directory.Below destination path is the default path for nginx image as per the default nginx config
COPY index.html /usr/share/nginx/html