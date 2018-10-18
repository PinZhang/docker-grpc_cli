FROM buildpack-deps:jessie-scm as builder

RUN apt-get update
RUN apt-get install -y \
      g++ gcc libc6-dev make unzip build-essential autoconf automake libtool libgflags-dev \
      --no-install-recommends

WORKDIR /root

RUN git clone https://github.com/grpc/grpc.git && \
      cd /root/grpc && \
      git checkout v1.3.0 && \
      git submodule update --init

ENV LDFLAGS=-static
RUN cd /root/grpc && make -j4 grpc_cli && cp ./bins/opt/grpc_cli /usr/bin/

FROM znly/upx as packer
COPY --from=builder /root/grpc/bins/opt/grpc_cli /grpc_cli
RUN upx --lzma /grpc_cli

FROM ubuntu
COPY --from=packer /grpc_cli /grpc_cli
COPY --from=builder /root/grpc/etc/roots.pem /usr/local/share/grpc/roots.pem
ENTRYPOINT ["/grpc_cli"]
