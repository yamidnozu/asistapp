FROM node:18

WORKDIR /app

RUN apt-get update && apt-get install -y libssl1.1 || apt-get install -y openssl

COPY package*.json ./
RUN npm install

COPY . .

RUN ls -la src/
RUN npx prisma generate
RUN ls -la

EXPOSE 3000

# CMD ["npm", "run", "dev"]  # Dev mode
CMD ["npx", "ts-node", "src/index.ts"]