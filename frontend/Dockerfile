# Stage 1: Build the React application
# Use a Node.js image as the build environment for the frontend application.
# This stage is responsible for installing project dependencies and creating the optimized production build.
FROM node:20-alpine AS build

# Set the working directory inside the container for the build process.
WORKDIR /app

# Copy `package.json` and `package-lock.json` (or `yarn.lock`) first.
# This crucial step allows Docker to cache the dependency installation.
# If these files don't change, `npm ci` will be skipped on subsequent builds,
# significantly speeding up the build process.
COPY package*.json ./

# Install project dependencies.
# This now correctly installs all dependencies, including devDependencies like 'vite'.
RUN npm ci

# Copy the rest of the application source code into the container.
COPY . .

# Build the React application for production.
# Vite typically outputs to a 'dist' directory by default.
RUN npm run build

# Stage 2: Serve the application with Nginx
# Use a lightweight Nginx image to serve the static files.
# This stage is much smaller than the build stage, as it only includes Nginx
# and the built static assets, leading to a smaller final Docker image.
FROM nginx:alpine

# Copy the custom Nginx configuration file into the Nginx configuration directory.
# This file (`nginx.conf`) is essential for telling Nginx how to serve your
# Single-Page Application (SPA), especially regarding client-side routing.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built React application files from the 'build' stage.
# *** IMPORTANT FIX: Changed /app/build to /app/dist ***
# This matches Vite's default output directory.
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80.
# This informs Docker that the container listens on port 80 at runtime.
# When running the container, you will map a host port to this exposed port (e.g., `-p 80:80`).
EXPOSE 80

# Define the command to run when the container starts.
# This starts the Nginx server in the foreground, making it the main process of the container.
CMD ["nginx", "-g", "daemon off;"]
