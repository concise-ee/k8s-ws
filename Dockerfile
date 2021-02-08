# Build-time image that is discarded
FROM gradle:6.7.1-jdk11 AS build
WORKDIR /app
COPY src /app/src
COPY build.gradle /app
RUN gradle clean build bootJar
RUN ls -l /app/build/libs

FROM adoptopenjdk/openjdk11-openj9:jdk-11.0.1.13-alpine-slim
COPY --from=build /app/build/libs/app-0.0.1-SNAPSHOT.jar demo.jar
# We add curl just for testing purposes
RUN apk --no-cache add curl
ENV JAVA_OPTS=""
CMD exec java $JAVA_OPTS -jar demo.jar
EXPOSE 8080
