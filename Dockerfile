# Use the Nixpacks base
FROM ghcr.io/railwayapp/nixpacks:ubuntu-1741046653

# Set working directory
WORKDIR /app/

# Copy the nixpacks configuration
COPY .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix

# Install system dependencies
RUN nix-env -if .nixpacks/nixpkgs-ffeebf0acf3ae8b29f8c7049cd911b9636efd7e7.nix && nix-collect-garbage -d

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies) explicitly
RUN --mount=type=cache,id=ggkpaDyXWK4-/root/npm,target=/root/.npm npm install --include=dev --no-optional

# Copy the rest of the application
COPY . /app/.

# Generate SvelteKit files and build
RUN npx svelte-kit sync
RUN --mount=type=cache,id=ggkpaDyXWK4-node_modules/cache,target=/app/node_modules/.cache npx vite build

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "build"] 