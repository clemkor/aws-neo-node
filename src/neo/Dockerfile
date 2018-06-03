FROM microsoft/dotnet:2.1-sdk-stretch

ENV NEO_CLI_VERSION="2.7.4"
ENV NEO_CLI_CHECKSUM="1B07A92E2867770B2DC5CEF830C151EAE3354353BB0D782D1642FBF7C5DEBC01"

# Install general prerequisites
RUN apt-get update \
    && apt-get -y install curl unzip \
    && rm -rf /var/lib/apt/lists

# Install AWS CLI
RUN apt-get update \
    && apt-get -y install python \
    && cd /tmp \
    && curl -L "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
    && unzip awscli-bundle.zip \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm awscli-bundle.zip \
    && rm -rf awscli-bundle \
    && rm -rf /var/lib/apt/lists

# Install NeoCLI prerequisites
RUN apt-get update \
    && apt-get -y install \
         expect \
         libleveldb-dev \
         sqlite3 \
         libsqlite3-dev \
         libunwind8-dev \
    && rm -rf /var/lib/apt/lists

# Install NeoCLI
RUN cd /tmp \
    && curl -L "https://github.com/neo-project/neo-cli/releases/download/v${NEO_CLI_VERSION}/neo-cli-linux-x64.zip" -o neo-cli-linux-x64.zip \
    && echo "${NEO_CLI_CHECKSUM} *neo-cli-linux-x64.zip" > neo-cli-linux-x64.zip.sha256 \
    && sha256sum -c neo-cli-linux-x64.zip.sha256 \
    && unzip neo-cli-linux-x64.zip \
    && mv neo-cli /opt/ \
    && rm neo-cli-linux-x64.zip neo-cli-linux-x64.zip.sha256

# Add scripts
ADD start-consensus /opt/neo-cli/bin/start-consensus
