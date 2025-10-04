FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY index.js ./

# Expose port
EXPOSE 3000

# Run as non-root user
USER node

CMD ["node", "index.js"]