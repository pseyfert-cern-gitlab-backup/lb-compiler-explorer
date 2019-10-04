# FROM cern/cc7-base:latest
FROM gitlab-registry.cern.ch/lhcb-docker/os-base/centos7-devel:latest

RUN yum install -y gcc-c++ make git which
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -
RUN yum install -y nodejs

RUN wget https://github.com/andreasfertig/cppinsights/releases/download/continuous/insights-ubuntu-14.04.tar.gz \
    && tar -xzf insights-ubuntu-14.04.tar.gz \
    && mv insights /usr/bin/ \
    && rm insights-ubuntu-14.04.tar.gz

# FIXME change pseyfert->compilerexplorer
RUN useradd compilerexplorer \
    && mkdir -p /home/compilerexplorer \
    && mkdir -p /home/pseyfert/.local/bin \
    && chown -R compilerexplorer:compilerexplorer /home/pseyfert
ADD --chown=compilerexplorer:compilerexplorer insights /home/pseyfert/.local/bin/

# get clang headers for cppinsights
RUN mkdir -p /usr/lib/clang \
    && ln -s /cvmfs/lhcb.cern.ch/lib/lcg/releases/clang/8.0.0-ed577/x86_64-centos7/lib/clang/8.0.0 /usr/lib/clang/8.0.1

# will be needed by npm at runtime
RUN mkdir -p /tmp
ENV HOME /tmp

EXPOSE 10240

# force re-pull https://stackoverflow.com/a/36996107
ARG CACHEBUST=1

RUN git clone https://:@gitlab.cern.ch:8443/pseyfert/compiler-explorer.git --depth=1 -b production2 \
    && rm -rf compiler-explorer/.git \
    && mv /compiler-explorer /home/compilerexplorer/compiler-explorer \
    && chown -R compilerexplorer:compilerexplorer /home/compilerexplorer \
    && chmod -R 777 /home/compilerexplorer

# for picking up the c++.pseyfert-ce.properties file
ENV EXTRA_ARGS -env=pseyfert-ce

USER compilerexplorer

WORKDIR /home/compilerexplorer/compiler-explorer

CMD ["make", "-C", "/home/compilerexplorer/compiler-explorer"]
