FROM node:16 as builder
WORKDIR /app
COPY package.json .
RUN yarn install

FROM node:16
WORKDIR /app
COPY --from=builder /app/ /app/
COPY . .
EXPOSE 8545
ENTRYPOINT ["yarn"]