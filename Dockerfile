# FROM cern/cc7-base:latest
FROM gitlab-registry.cern.ch/lhcb-docker/os-base/centos7-devel:latest

RUN yum install -y gcc-c++ make git which
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -
RUN yum install -y nodejs
RUN useradd compilerexplorer \
    && mkdir /home/compilerexplorer \
    && chown -R compilerexplorer:compilerexplorer /home/compilerexplorer
RUN git clone https://:@gitlab.cern.ch:8443/pseyfert/compiler-explorer.git -b production2
RUN mv /compiler-explorer /home/compilerexplorer/compiler-explorer

USER compilerexplorer

CMD ["make", "-C", "/home/compilerexplorer/compiler-explorer"]
