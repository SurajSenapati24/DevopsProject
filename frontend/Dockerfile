FROM node:18-slim

WORKDIR /usr/src/app
COPY package.json ./
RUN npm install
COPY app.js ./
COPY index.html ./
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "app.js"]
