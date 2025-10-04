# Use official Node.js LTS image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy application code
COPY index.js ./

# Expose the port
EXPOSE 3000

# Set node environment to production
ENV NODE_ENV=production

# Run as non-root user for security
USER node

# Start the application
CMD ["node", "index.js"]