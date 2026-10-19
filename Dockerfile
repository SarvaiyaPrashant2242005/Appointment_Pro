# AppointmentPro API (Node.js + PostgreSQL)

FROM node:22-slim

ENV NODE_ENV=production
WORKDIR /app/Server

COPY Server/package.json Server/package-lock.json ./
RUN npm ci --omit=dev

COPY Server/ ./
COPY index.html /app/index.html

RUN mkdir -p /app/Server/uploads && chown -R node:node /app

USER node
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||5000)+'/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
