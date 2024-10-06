FROM node:20-bullseye-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apt-get update && \
    apt-get install -y python3 build-essential

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS frontend
WORKDIR /app/web
COPY web /app/web

RUN pnpm install --frozen-lockfile
RUN pnpm run build

FROM base AS api
WORKDIR /app

COPY --from=build /prod/api /app
COPY --from=build /app/.git /app/.git
COPY --from=frontend /app/web/build /app/public

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
