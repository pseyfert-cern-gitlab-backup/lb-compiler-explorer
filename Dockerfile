# FROM cern/cc7-base:latest
FROM gitlab-registry.cern.ch/lhcb-docker/os-base/centos7-devel:latest

RUN yum install -y gcc-c++ make git which zlib-devel ncurses-devel
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

# automatically unpacks
ADD --chown=compilerexplorer:compilerexplorer iwyu.tar.gz /home/pseyfert
RUN chown -R compilerexplorer:compilerexplorer /home/pseyfert

# invalidate cache whenever compiler-explorer config changes (78479 is compiler-explorer.git)
ADD https://gitlab.cern.ch/api/v4/projects/78479 config_repo

RUN git clone https://:@gitlab.cern.ch:8443/pseyfert/compiler-explorer.git --depth=1 -b production_since-2019-11-14 \
    && cd compiler-explorer \
    && git config --global user.email "novalid@e.mail" \
    && git config --global user.name "docker-build" \
    && git fetch origin --depth=2 dateprint \
    && git cherry-pick 66e8e8336 \
    && cd .. \
    && rm -rf compiler-explorer/.git \
    && mv /compiler-explorer /home/compilerexplorer/compiler-explorer \
    && make -C /home/compilerexplorer/compiler-explorer prereqs \
    && chown -R compilerexplorer:compilerexplorer /home/compilerexplorer \
    && chmod -R 777 /home/compilerexplorer

# get security updates and such after cache invalidation, expected to be smaller than full yum install
RUN yum update -y

# for picking up the c++.pseyfert-ce.properties file
ENV EXTRA_ARGS -env=pseyfert-ce

USER compilerexplorer

WORKDIR /home/compilerexplorer/compiler-explorer

CMD ["make", "-C", "/home/compilerexplorer/compiler-explorer"]
