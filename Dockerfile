# docker multi-stage build

# Build-time image - builds application for next stage, everything else in this image is discarded
FROM gradle:6.7.1-jdk11 AS build
WORKDIR /app
COPY src /app/src
COPY build.gradle /app
RUN gradle clean build bootJar
RUN ls -l /app/build/libs

# Final image - uses only application jar from previous stage
FROM adoptopenjdk/openjdk11-openj9:jdk-11.0.1.13-alpine-slim
# We add curl just for testing purposes
RUN apk --no-cache add curl
ENV JAVA_OPTS=""
COPY --from=build /app/build/libs/app-0.0.1-SNAPSHOT.jar demo.jar
CMD exec java $JAVA_OPTS -jar demo.jar
EXPOSE 8080
