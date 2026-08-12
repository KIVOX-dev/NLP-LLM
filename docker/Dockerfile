# Build context MUST be the repository root (not docker/), because
# server/dart_frog_api depends on ../../packages/shared_models via a path
# dependency. See docker-compose.yml, which sets `context: ..`.
#
# Usage from repo root:
#   docker build -f docker/Dockerfile -t sanskrit-ai-api .

FROM dart:stable AS build
WORKDIR /workspace

COPY packages/shared_models packages/shared_models
COPY server/dart_frog_api server/dart_frog_api

WORKDIR /workspace/server/dart_frog_api
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

WORKDIR /workspace/server/dart_frog_api/build
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /workspace/server/dart_frog_api/build/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
