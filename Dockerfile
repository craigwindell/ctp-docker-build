FROM eclipse-temurin:8-jdk as builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /CTP-Source

RUN git clone https://github.com/johnperry/CTP.git /CTP-Source/ && \
  cd /CTP-Source && \
  git checkout cc77a3032abd9ebeb4af9a55e115ad49f65f626f && \
  VERSION=$(git log -n 1 --date=format:'%Y%m%d' products/CTP-installer.jar | grep Date | cut -d ' ' -f 4); \
  echo $VERSION > ../latest-build

RUN mkdir /JavaPrograms
WORKDIR /JavaPrograms
RUN jar xf /CTP-Source/products/CTP-installer.jar CTP

FROM eclipse-temurin:8-jdk
LABEL org.opencontainers.image.source=https://github.com/australian-imaging-service/ctp-docker-build

USER root

RUN mkdir /JavaPrograms
COPY --from=builder /JavaPrograms /JavaPrograms
COPY --from=builder /latest-build /
COPY Launcher.properties /JavaPrograms/CTP
COPY config-serveronly.xml /JavaPrograms/CTP/config.xml
COPY entrypoint.sh /

WORKDIR /JavaPrograms/CTP

EXPOSE 1080 1443 25055

CMD ["java", "-jar", "/JavaPrograms/CTP/Runner.jar" ]
ENTRYPOINT ["/entrypoint.sh"]

