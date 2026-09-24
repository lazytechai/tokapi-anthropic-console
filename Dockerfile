# syntax=docker/dockerfile:1.7

FROM node:26.9.0-bookworm-slim@sha256:582460f614631b59b824ac6020533b9bf339c7fdf3a6d7db31abb6b4065f0212 AS build

RUN npm install --global --ignore-scripts --no-audit --no-fund pnpm@10.30.3 \
    && npm cache clean --force

WORKDIR /workspace

COPY package.json pnpm-lock.yaml ./

RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile

COPY . .

RUN pnpm check && pnpm build

FROM gcr.io/distroless/nodejs24-debian13:nonroot@sha256:af85d11ce7ef10172855a6e3649e3e8125b1b9e3ca41849ec2918036f05cb212 AS runtime

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

WORKDIR /app

COPY --from=build --chown=65532:65532 /workspace/dist/standalone/ ./
COPY --chown=65532:65532 docker/healthcheck.mjs ./healthcheck.mjs

USER 65532:65532

EXPOSE 3000

STOPSIGNAL SIGTERM

CMD ["server.js"]
