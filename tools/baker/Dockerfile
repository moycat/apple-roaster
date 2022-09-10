FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# install tools
RUN apt update && apt upgrade -y \
    && apt install -y debootstrap dosfstools mount \
    && apt clean && rm -rf /var/lib/apt/lists/*

# copy script
COPY build.sh /
CMD ["/build.sh"]
