FROM ubuntu:22.04 as base
WORKDIR /workdir

ARG sdk_version=v2.3.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install wget unzip

# Install toolchain
# Make nrfutil install in a shared location, because when used with GitHub
# Actions, the image will be launched with the home dir mounted from the local
# checkout.
ENV NRFUTIL_HOME=/usr/local/share/nrfutil
RUN wget -q https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil && \
    mv nrfutil /usr/local/bin && \
    chmod +x /usr/local/bin/nrfutil && \
    nrfutil install toolchain-manager && \
    nrfutil install toolchain-manager search && \
    nrfutil toolchain-manager install --ncs-version ${sdk_version} && \
    nrfutil toolchain-manager list 

#
# ClangFormat
#
RUN apt-get -y install clang-format && \
    wget -qO- https://raw.githubusercontent.com/nrfconnect/sdk-nrf/${sdk_version}/.clang-format > /workdir/.clang-format



# Prepare image with a ready to use build environment
SHELL ["nrfutil","toolchain-manager","launch","/bin/bash","--","-c"]
RUN west init -m https://github.com/nrfconnect/sdk-nrf --mr ${sdk_version} . && \
    west update --narrow -o=--depth=1

# Launch into build environment with the passed arguments
# Currently this is not supported in GitHub Actions
# See https://github.com/actions/runner/issues/1964
ENTRYPOINT [ "nrfutil", "toolchain-manager", "launch", "/bin/bash", "--", "/root/entrypoint.sh" ]
COPY ./entrypoint.sh /root/entrypoint.sh
