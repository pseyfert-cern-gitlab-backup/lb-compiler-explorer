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

RUN IWYUBUILD=$(mktemp -d) \
    && cd ${IWYUBUILD} \
    && git clone https://github.com/include-what-you-use/include-what-you-use.git --depth=1 -b clang_8.0 \
    && cd include-what-you-use/ \
    && mkdir build \
    && git remote add mine https://github.com/pseyfert/include-what-you-use.git \
    && git fetch mine \
    && git cherry-pick 923b8a64a7833739b7472bee414d8ee46e4b58bb \
    && cd build/ \
    && PATH=/cvmfs/lhcb.cern.ch/lib/bin/Linux-x86_64:${PATH} /cvmfs/lhcb.cern.ch/lib/bin/Linux-x86_64/cmake -GNinja .. -DCMAKE_PREFIX_PATH=/cvmfs/lhcb.cern.ch/lib/lcg/releases/clang/8.0.0-ed577/x86_64-centos7/ -DCMAKE_INSTALL_PREFIX=/home/pseyfert/.local -DCMAKE_BUILD_TYPE=Release -DCMAKE_RULE_MESSAGES=NO -DCMAKE_EXPORT_COMPILE_COMMANDS=YES -DCMAKE_CXX_COMPILER=/cvmfs/lhcb.cern.ch/lib/bin/x86_64-centos7/lcg-clang++-8.0.0 -DCMAKE_C_COMPILER=/cvmfs/lhcb.cern.ch/lib/bin/x86_64-centos7/lcg-clang-8.0.0 \
    && PATH=/cvmfs/lhcb.cern.ch/lib/bin/Linux-x86_64:${PATH} /cvmfs/lhcb.cern.ch/lib/bin/Linux-x86_64/cmake --build . --target install \
    && cat /cvmfs/lhcb.cern.ch/lib/bin/x86_64-centos7/lcg-clang++-8.0.0 \
    && mkdir -p /home/pseyfert/.local/lib/clang \
    && ln -s /cvmfs/lhcb.cern.ch/lib/lcg/releases/clang/8.0.0/x86_64-centos7/lib/clang/8.0.0 /tmp/include-what-you-use/lib/clang/8.0.0 \
    && rm -rf ${IWYUBUILD}

# invalidate cache whenever compiler-explorer config changes (78479 is compiler-explorer.git)
ADD https://gitlab.cern.ch/api/v4/projects/78479 config_repo

RUN git clone https://:@gitlab.cern.ch:8443/pseyfert/compiler-explorer.git --depth=1 -b production2 \
    && rm -rf compiler-explorer/.git \
    && mv /compiler-explorer /home/compilerexplorer/compiler-explorer \
    && chown -R compilerexplorer:compilerexplorer /home/compilerexplorer \
    && chmod -R 777 /home/compilerexplorer

# get security updates and such after cache invalidation, expected to be smaller than full yum install
RUN yum update -y

# for picking up the c++.pseyfert-ce.properties file
ENV EXTRA_ARGS -env=pseyfert-ce

USER compilerexplorer

WORKDIR /home/compilerexplorer/compiler-explorer

CMD ["make", "-C", "/home/compilerexplorer/compiler-explorer"]
