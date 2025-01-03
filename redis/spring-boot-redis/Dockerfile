FROM eclipse-temurin:17-jdk AS builder
WORKDIR /code
COPY [ "gradlew", "*.gradle", "./" ]
COPY gradle gradle
COPY src src
ARG JAR_FILE=build/libs/*.jar
ARG GRADLE_USER_HOME=/tmp/build_cache/gradle
RUN --mount=type=cache,target=/tmp/build_cache/gradle \
    set -ex \
    && chmod +x gradlew \
    && ./gradlew build -i -x jar -x test \
    && java -Djarmode=layertools -jar $JAR_FILE extract
FROM eclipse-temurin:17-jre
# COPY DigiCertGlobalG2TLSRSASHA2562020CA1.pem DigiCertGlobalG2TLSRSASHA2562020CA1.pem
# RUN keytool -keystore /opt/java/openjdk/lib/security/cacerts \
# -importcert -alias "DigiCertGlobalG2TLSRSASHA2562020CA1" -file DigiCertGlobalG2TLSRSASHA2562020CA1.pem \
# -storepass changeit -noprompt

USER 999:0
WORKDIR /app
COPY --from=builder /code/dependencies/ ./
COPY --from=builder /code/spring-boot-loader/ ./
COPY --from=builder /code/snapshot-dependencies/ ./
COPY --from=builder /code/application/ ./
COPY config config
COPY ca.crt ./
USER root
RUN keytool -cacerts \
-importcert -alias "redis test ca" -file ca.crt \
-storepass changeit -noprompt
USER 999:0
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
#ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

