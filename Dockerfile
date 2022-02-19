# base image
FROM amazon/aws-lambda-python:3.8

# Install ssh tool to install private dependencies
RUN yum install -y git openssh && \
    yum clean all && \
    rm -Rf /var/cache/yum

# Download public key for github.com
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Install poetry
RUN pip install poetry

# Copy in the poetry config files
COPY pyproject.toml poetry.lock ./

# Install dependencies
RUN poetry config virtualenvs.create false
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt
RUN --mount=type=ssh,id=github_ssh_key pip install -r requirements.txt --no-cache && \
    rm -rf pyproject.toml poetry.lock requirements.txt

# Copy app files
COPY ./espn_fantasy_my_matchup ./espn_fantasy_my_matchup

# add env vars for metaflow config
ENV USERNAME=produser
ENV METAFLOW_DATASTORE_SYSROOT_S3="s3://espn-fantasy-s3-test/metaflow/"
ENV METAFLOW_DATATOOLS_S3ROOT="s3://espn-fantasy-s3-test/data"
ENV METAFLOW_DEFAULT_DATASTORE="s3"
ENV METAFLOW_DEFAULT_METADATA="service"

# Entrypoint command
ENTRYPOINT [ "python", "-m", "espn_fantasy_my_matchup.handler", "run" ]