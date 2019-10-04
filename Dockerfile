# FROM cern/cc7-base:latest
FROM gitlab-registry.cern.ch/lhcb-docker/os-base/centos7-devel:latest

RUN yum install -y gcc-c++ make git which
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -
RUN yum install -y nodejs
RUN useradd compilerexplorer \
    && mkdir -p /home/compilerexplorer \
    && git clone https://:@gitlab.cern.ch:8443/pseyfert/compiler-explorer.git -b production2 \
    && mv /compiler-explorer /home/compilerexplorer/compiler-explorer \
    && chown -R compilerexplorer:compilerexplorer /home/compilerexplorer \
    && chmod -R 777 /home/compilerexplorer

RUN wget https://github.com/andreasfertig/cppinsights/releases/download/continuous/insights-ubuntu-14.04.tar.gz \
    && tar -xzf insights-ubuntu-14.04.tar.gz \
    && mv insights /usr/bin/ \
    && rm insights-ubuntu-14.04.tar.gz

# FIXME change pseyfert->compilerexplorer
RUN mkdir -p /home/pseyfert/.local/bin \
    && chown -R compilerexplorer:compilerexplorer /home/pseyfert
ADD --chown=compilerexplorer:compilerexplorer insights /home/pseyfert/.local/bin/

USER compilerexplorer

CMD ["make", "-C", "/home/compilerexplorer/compiler-explorer"]
