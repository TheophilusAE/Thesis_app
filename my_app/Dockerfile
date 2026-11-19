# Reproducible build/test environment for the GPdI Persadamas app.
#
# The mobile app itself never runs in a container. This image pins the exact
# Flutter + Android SDK toolchain so tests and release builds are identical
# on any machine (see docs/docker.md).
#
#   docker build -t gpdi-app .
#   docker run --rm gpdi-app                      # analyze + tests
#   docker run --rm -v "%cd%/build:/app/build" \
#     -v "%cd%/android/key.properties:/app/android/key.properties:ro" \
#     -v "<folder keystore>:/keys:ro" \
#     -v "%cd%/android/app/google-services.json:/app/android/app/google-services.json:ro" \
#     gpdi-app flutter build appbundle --release
#
# Secrets (google-services.json, key.properties, the keystore) are mounted at
# run time and never copied into the image (.dockerignore excludes them).

FROM ghcr.io/cirruslabs/flutter:3.41.6

WORKDIR /app

# Dependencies first so they are cached between builds.
COPY pubspec.yaml pubspec.lock ./
COPY packages ./packages
RUN flutter pub get

COPY . .
RUN flutter pub get

CMD ["sh", "-c", "flutter analyze && flutter test"]
