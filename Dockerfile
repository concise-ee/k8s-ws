# docker multi-stage build

# Build-time image - builds application for next stage, everything else in this image is discarded
FROM eclipse-temurin:11-jdk-focal AS build
WORKDIR /app
COPY build.gradle gradlew /app/
COPY gradle /app/gradle
COPY src /app/src
RUN ./gradlew clean build bootJar
RUN ls -l /app/build/libs

# Final image - uses only application jar from previous stage
FROM eclipse-temurin:11-jre-focal
ENV JAVA_OPTS=""
COPY --from=build /app/build/libs/app-0.0.1-SNAPSHOT.jar demo.jar
CMD exec java $JAVA_OPTS -jar demo.jar
EXPOSE 8080